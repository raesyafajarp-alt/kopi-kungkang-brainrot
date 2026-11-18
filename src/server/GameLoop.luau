-- GameLoop: the server's heartbeat. It spawns brainrots onto the conveyor,
-- walks them along it, pays every player their $/second once a second,
-- and broadcasts each player's state to their client for the HUD.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local BrainrotData = require(ReplicatedStorage.Shared.BrainrotData)
local GameState = require(script.Parent.GameState)
local BrainrotFactory = require(script.Parent.BrainrotFactory)
local Actions = require(script.Parent.Actions)

local GameLoop = {}

-- Make one brainrot appear at the start of the conveyor and walk it to
-- the end. If nobody buys it on the way, it despawns at the exit pad.
local function spawnBrainrot()
	local rarityName = BrainrotData.rollRarity()
	local character = BrainrotData.pickCharacter(rarityName)
	local mutationName = BrainrotData.rollMutation()
	local id = "B" .. GameState.nextBrainrotId
	GameState.nextBrainrotId += 1

	local record = {
		id = id,
		character = character,
		mutation = mutationName,
		owner = nil,
		model = nil,
		slot = nil,
		state = "walking",
	}
	table.insert(GameState.walking, record)
	BrainrotFactory.buildBrainrotModel(record)
	Actions.wireBrainrotPrompts(record)
	record.model:PivotTo(CFrame.new(Config.CONVEYOR_X, Config.BRAINROT_BODY_Y, Config.CONVEYOR_START_Z))

	task.spawn(function()
		local z = Config.CONVEYOR_START_Z
		while record.state == "walking" and record.model do
			task.wait(0.1)
			z += Config.WALK_SPEED * 0.1
			if z >= Config.CONVEYOR_END_Z then
				break
			end
			if record.model then
				-- A gentle bob while it walks, so it reads as alive.
				local bob = math.sin(z * 1.5) * 0.15
				record.model:PivotTo(CFrame.new(Config.CONVEYOR_X, Config.BRAINROT_BODY_Y + bob, z))
			end
		end
		if record.state == "walking" then
			GameState.removeFromWalking(record)
			if record.model then
				record.model:Destroy()
				record.model = nil
			end
		end
	end)
end

-- Build one player's state payload for the HUD: money, income, owned
-- brainrots, lock timers, tsunami phase and the leaderboard.
local function buildStatePayload(player: Player, state)
	local owned = {}
	for _, record in ipairs(state.owned) do
		table.insert(owned, {
			id = record.id,
			name = record.character.name,
			rarity = record.character.rarity,
			mutation = record.mutation,
			rate = BrainrotData.getIncomeRate(record.character, record.mutation, state.rebirths),
			cost = record.character.cost,
		})
	end

	local now = os.time()
	local lockRemaining = 0
	local lockCooldown = 0
	if state.base then
		local lockedUntil = state.base:GetAttribute("LockedUntil")
		if typeof(lockedUntil) == "number" then
			lockRemaining = math.max(0, lockedUntil - now)
		end
		local cooldownUntil = state.base:GetAttribute("LockCooldownUntil")
		if typeof(cooldownUntil) == "number" then
			lockCooldown = math.max(0, cooldownUntil - now)
		end
	end

	-- Leaderboard: top 5 players by cash right now.
	local ranking = {}
	for _, other in pairs(GameState.players) do
		table.insert(ranking, { name = other.player.Name, money = math.floor(other.money) })
	end
	table.sort(ranking, function(a, b)
		return a.money > b.money
	end)
	local leaderboard = {}
	for i = 1, math.min(5, #ranking) do
		table.insert(leaderboard, ranking[i])
	end

	local rebirthCost = Config.REBIRTH_BASE_COST * (state.rebirths + 1) * (state.rebirths + 1)
	return {
		money = math.floor(state.money),
		income = GameState.getIncomePerSecond(state),
		rebirths = state.rebirths,
		rebirthCost = rebirthCost,
		owned = owned,
		baseName = state.base and state.base.Name or "",
		lockRemaining = lockRemaining,
		lockCooldown = lockCooldown,
		eventPhase = GameState.tsunami.phase,
		eventCountdown = GameState.tsunami.countdown,
		leaderboard = leaderboard,
	}
end

-- Pay every player once a second and push fresh state to their HUD.
local function incomeTick()
	while true do
		task.wait(1)
		local sync = ReplicatedStorage:FindFirstChild("StateSync")
		for _, player in ipairs(Players:GetPlayers()) do
			local state = GameState.getPlayerState(player)
			if state then
				local income = GameState.getIncomePerSecond(state)
				if income > 0 then
					state.money += income
					state.totalEarned += income
				end
				local leaderstats = player:FindFirstChild("leaderstats")
				if leaderstats then
					local moneyValue = leaderstats:FindFirstChild("Uang")
					if moneyValue then
						moneyValue.Value = math.floor(state.money)
					end
					local rebirthValue = leaderstats:FindFirstChild("Rebirth")
					if rebirthValue then
						rebirthValue.Value = state.rebirths
					end
				end
				if sync then
					sync:FireClient(player, buildStatePayload(player, state))
				end
			end
		end
	end
end

-- Spawn loop: keep the conveyor supplied, up to MAX_WALKING at once.
local function spawnTick()
	while true do
		task.wait(Config.SPAWN_INTERVAL)
		if #GameState.walking < Config.MAX_WALKING then
			spawnBrainrot()
		end
	end
end

-- A player joins: give them starting money, a base and leaderstats.
local function onPlayerAdded(player: Player)
	local state = GameState.newPlayerState(player)
	GameState.assignBase(player)

	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	local moneyValue = Instance.new("NumberValue")
	moneyValue.Name = "Uang"
	moneyValue.Value = state.money
	moneyValue.Parent = leaderstats
	local rebirthValue = Instance.new("IntValue")
	rebirthValue.Name = "Rebirth"
	rebirthValue.Value = 0
	rebirthValue.Parent = leaderstats
	leaderstats.Parent = player
end

-- A player leaves: their brainrots vanish and their base frees up.
local function onPlayerRemoving(player: Player)
	local state = GameState.getPlayerState(player)
	if state then
		for _, record in ipairs(state.owned) do
			if record.model then
				record.model:Destroy()
				record.model = nil
			end
		end
		GameState.releaseBase(player)
		GameState.players[player] = nil
	end
end

function GameLoop.start()
	local folder = workspace:FindFirstChild("Brainrots")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "Brainrots"
		folder.Parent = workspace
	end
	Players.PlayerAdded:Connect(onPlayerAdded)
	Players.PlayerRemoving:Connect(onPlayerRemoving)
	for _, player in ipairs(Players:GetPlayers()) do
		onPlayerAdded(player)
	end
	task.spawn(spawnTick)
	task.spawn(incomeTick)
end

return GameLoop
