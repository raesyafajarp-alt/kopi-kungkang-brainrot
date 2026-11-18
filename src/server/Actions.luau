-- Actions: every player action the server accepts — buying a brainrot off
-- the conveyor, stealing one from another base, selling, rebirthing and
-- locking a base. Each action re-checks everything on the server
-- (money, slots, locks, ownership), so a client can never fake one.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local BrainrotData = require(ReplicatedStorage.Shared.BrainrotData)
local GameState = require(script.Parent.GameState)
local BrainrotFactory = require(script.Parent.BrainrotFactory)

local Actions = {}

local function toast(player: Player, message: string)
	local remote = ReplicatedStorage:FindFirstChild("Toast")
	if remote then
		remote:FireClient(player, message)
	end
end

-- Put a brainrot record into a player's base: claim a slot, move the
-- model there, flip the prompts from "buy" to "steal".
local function placeInBase(record, player: Player, state)
	local slot = GameState.findFreeSlot(state.base)
	if not slot then
		return false
	end
	slot:SetAttribute("BrainrotId", record.id)
	record.slot = slot
	record.owner = player
	record.state = "owned"
	table.insert(state.owned, record)
	if record.model then
		local body = record.model.PrimaryPart
		local buyPrompt = body and body:FindFirstChild("BuyPrompt")
		if buyPrompt then
			buyPrompt.Enabled = false
		end
		local stealPrompt = body and body:FindFirstChild("StealPrompt")
		if stealPrompt then
			stealPrompt.ObjectText = record.character.name .. " milik " .. player.Name
			stealPrompt.Enabled = not GameState.isBaseLocked(state.base)
		end
		local target = CFrame.new(slot.Position + Vector3.new(0, 1.6, 0))
		task.spawn(BrainrotFactory.animateModelTo, record.model, target)
	end
	BrainrotFactory.refreshBillboard(record)
	return true
end

-- Buy a walking brainrot: pay its cost, walk it over to the buyer's base.
function Actions.tryBuyBrainrot(player: Player, record)
	if not record or record.state ~= "walking" then
		return
	end
	local state = GameState.getPlayerState(player)
	if not state then
		return
	end
	if not state.base then
		toast(player, "Kamu belum punya base! Tunggu sebentar lalu coba lagi.")
		return
	end
	if state.money < record.character.cost then
		toast(player, "Uangmu kurang! " .. record.character.name .. " harganya " .. BrainrotData.formatMoney(record.character.cost) .. ".")
		return
	end
	if not GameState.findFreeSlot(state.base) then
		toast(player, "Basemu penuh! Jual satu brainrot dulu.")
		return
	end
	state.money -= record.character.cost
	GameState.removeFromWalking(record)
	if placeInBase(record, player, state) then
		toast(player, "Kamu membeli " .. record.character.name .. " (" .. record.character.rarity .. ")! +" .. BrainrotData.formatMoney(BrainrotData.getIncomeRate(record.character, record.mutation, state.rebirths)) .. "/detik.")
	else
		-- Extremely rare: the slot vanished between the check and the
		-- placement. Refund rather than eat the player's money.
		state.money += record.character.cost
		toast(player, "Gagal menaruh brainrot di base. Uang dikembalikan.")
	end
end

-- Steal a brainrot out of another player's base. Only works while the
-- victim's base lock is down, and only if the thief has a free slot.
function Actions.tryStealBrainrot(player: Player, record)
	if not record or record.state ~= "owned" then
		return
	end
	local victim = record.owner
	if not victim or victim == player then
		return
	end
	local thiefState = GameState.getPlayerState(player)
	local victimState = GameState.getPlayerState(victim)
	if not thiefState or not victimState then
		return
	end
	if not thiefState.base then
		toast(player, "Kamu belum punya base untuk menaruh hasil curian!")
		return
	end
	if GameState.isBaseLocked(victimState.base) then
		toast(player, "Base " .. victim.Name .. " sedang terkunci! Coba lagi nanti.")
		return
	end
	if not GameState.findFreeSlot(thiefState.base) then
		toast(player, "Basemu penuh! Jual satu brainrot dulu.")
		return
	end
	GameState.removeFromOwned(record)
	if placeInBase(record, player, thiefState) then
		toast(player, "Berhasil mencuri " .. record.character.name .. " dari " .. victim.Name .. "!")
		toast(victim, player.Name .. " mencuri " .. record.character.name .. " dari basemu! Kunci basemu lain kali!")
	else
		-- Placement failed: hand it back to the victim instead of losing it.
		placeInBase(record, victim, victimState)
		toast(player, "Gagal mencuri. Brainrot kembali ke pemiliknya.")
	end
end

-- Sell one owned brainrot for half its cost.
function Actions.sellBrainrot(player: Player, brainrotId: string)
	local state = GameState.getPlayerState(player)
	if not state then
		return
	end
	for _, record in ipairs(state.owned) do
		if record.id == brainrotId then
			local refund = math.floor(record.character.cost * Config.SELL_REFUND)
			state.money += refund
			GameState.removeFromOwned(record)
			if record.model then
				record.model:Destroy()
				record.model = nil
			end
			toast(player, "Menjual " .. record.character.name .. " seharga " .. BrainrotData.formatMoney(refund) .. ".")
			return
		end
	end
	toast(player, "Brainrot itu tidak ada di koleksimu.")
end

-- Rebirth: pay a growing price, lose your money and your brainrots,
-- keep a permanent +50% income multiplier per rebirth.
function Actions.rebirthPlayer(player: Player)
	local state = GameState.getPlayerState(player)
	if not state then
		return
	end
	local cost = Config.REBIRTH_BASE_COST * (state.rebirths + 1) * (state.rebirths + 1)
	if state.money < cost then
		toast(player, "Rebirth butuh " .. BrainrotData.formatMoney(cost) .. ". Uangmu " .. BrainrotData.formatMoney(state.money) .. ".")
		return
	end
	state.money = Config.START_MONEY
	state.rebirths += 1
	-- Clear the whole collection, models included.
	for i = #state.owned, 1, -1 do
		local record = state.owned[i]
		if record.model then
			record.model:Destroy()
			record.model = nil
		end
		if record.slot then
			record.slot:SetAttribute("BrainrotId", nil)
		end
		table.remove(state.owned, i)
	end
	toast(player, "REBIRTH! Sekarang penghasilanmu x" .. string.format("%.1f", 1 + Config.REBIRTH_MULTIPLIER_PER_LEVEL * state.rebirths) .. ".")
end

-- Lock your base for 60 seconds: steal prompts on your brainrots turn
-- off and the red door appears. Cooldown 150 seconds before next lock.
function Actions.lockBase(player: Player)
	local state = GameState.getPlayerState(player)
	if not state or not state.base then
		return
	end
	local base = state.base
	local now = os.time()
	local cooldownUntil = base:GetAttribute("LockCooldownUntil")
	if typeof(cooldownUntil) == "number" and now < cooldownUntil then
		toast(player, "Kunci base masih cooldown " .. (cooldownUntil - now) .. " detik lagi.")
		return
	end
	if GameState.isBaseLocked(base) then
		toast(player, "Basemu sudah terkunci.")
		return
	end
	base:SetAttribute("LockedUntil", now + Config.LOCK_DURATION)
	base:SetAttribute("LockCooldownUntil", now + Config.LOCK_COOLDOWN)
	local door = base:FindFirstChild("Door")
	if door and door:IsA("BasePart") then
		door.Transparency = 0.2
		door.CanCollide = true
	end
	for _, record in ipairs(state.owned) do
		local body = record.model and record.model.PrimaryPart
		local stealPrompt = body and body:FindFirstChild("StealPrompt")
		if stealPrompt then
			stealPrompt.Enabled = false
		end
	end
	toast(player, "Base terkunci selama " .. Config.LOCK_DURATION .. " detik! Pencuri tidak bisa masuk.")
	task.delay(Config.LOCK_DURATION, function()
		if not state.base then
			return
		end
		local doorAgain = state.base:FindFirstChild("Door")
		if doorAgain and doorAgain:IsA("BasePart") then
			doorAgain.Transparency = 1
			doorAgain.CanCollide = false
		end
		for _, record in ipairs(state.owned) do
			local body = record.model and record.model.PrimaryPart
			local stealPrompt = body and body:FindFirstChild("StealPrompt")
			if stealPrompt then
				stealPrompt.Enabled = true
			end
		end
		if Players:GetPlayerByUserId(player.UserId) then
			toast(player, "Kunci basemu sudah habis. Kunci lagi kalau mau!")
		end
	end)
end

-- Wire the RemoteEvents and the buy/steal prompts of every new brainrot.
function Actions.setupRemotes()
	local rebirthRemote = ReplicatedStorage:WaitForChild("RebirthRequest")
	rebirthRemote.OnServerEvent:Connect(function(player)
		Actions.rebirthPlayer(player)
	end)
	local lockRemote = ReplicatedStorage:WaitForChild("LockRequest")
	lockRemote.OnServerEvent:Connect(function(player)
		Actions.lockBase(player)
	end)
	local sellRemote = ReplicatedStorage:WaitForChild("SellRequest")
	sellRemote.OnServerEvent:Connect(function(player, brainrotId)
		if typeof(brainrotId) == "string" then
			Actions.sellBrainrot(player, brainrotId)
		end
	end)
end

-- Connect a freshly built brainrot model's prompts to the actions above.
function Actions.wireBrainrotPrompts(record)
	local model = record.model
	if not model or not model.PrimaryPart then
		return
	end
	local buyPrompt = model.PrimaryPart:FindFirstChild("BuyPrompt")
	if buyPrompt then
		buyPrompt.Triggered:Connect(function(player)
			Actions.tryBuyBrainrot(player, record)
		end)
	end
	local stealPrompt = model.PrimaryPart:FindFirstChild("StealPrompt")
	if stealPrompt then
		stealPrompt.Triggered:Connect(function(player)
			Actions.tryStealBrainrot(player, record)
		end)
	end
end

return Actions
