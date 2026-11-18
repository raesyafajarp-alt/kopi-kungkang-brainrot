-- GameState: the single place the server keeps live game state.
-- One table per player (money, rebirths, base, owned brainrots) plus the
-- list of brainrots currently walking the conveyor. Every other server
-- module reads and writes state through here, never through its own copy.

local Config = require(game:GetService("ReplicatedStorage").Shared.Config)
local BrainrotData = require(game:GetService("ReplicatedStorage").Shared.BrainrotData)

local GameState = {}

GameState.players = {} -- [Player] = player state table
GameState.walking = {} -- array of brainrot records walking the conveyor
GameState.nextBrainrotId = 1
GameState.tsunami = { phase = "idle", countdown = 0 }

-- A brainrot record:
--   id, character (cast row), mutation (name), owner (Player or nil),
--   model (Model or nil), slot (BasePart or nil), state ("walking"/"owned")

function GameState.newPlayerState(player: Player)
	local state = {
		player = player,
		money = Config.START_MONEY,
		rebirths = 0,
		totalEarned = 0,
		base = nil, -- Folder under Workspace.Bases, assigned on join
		owned = {}, -- array of brainrot records
	}
	GameState.players[player] = state
	return state
end

function GameState.getPlayerState(player: Player)
	return GameState.players[player]
end

-- First unclaimed base in Workspace.Bases, claimed for this player.
function GameState.assignBase(player: Player)
	local bases = workspace:FindFirstChild("Bases")
	if not bases then
		return nil
	end
	for _, base in ipairs(bases:GetChildren()) do
		if base:IsA("Folder") and base:GetAttribute("OwnerUserId") == nil then
			base:SetAttribute("OwnerUserId", player.UserId)
			base:SetAttribute("OwnerName", player.Name)
			local state = GameState.getPlayerState(player)
			if state then
				state.base = base
			end
			return base
		end
	end
	return nil
end

-- Release a player's base when they leave: clear the owner, unlock the door.
function GameState.releaseBase(player: Player)
	local state = GameState.getPlayerState(player)
	if not state or not state.base then
		return
	end
	local base = state.base
	base:SetAttribute("OwnerUserId", nil)
	base:SetAttribute("OwnerName", nil)
	base:SetAttribute("LockedUntil", 0)
	base:SetAttribute("LockCooldownUntil", 0)
	local door = base:FindFirstChild("Door")
	if door and door:IsA("BasePart") then
		door.Transparency = 1
		door.CanCollide = false
	end
end

-- Is this base's lock up right now? Locks are stored as unix timestamps
-- in attributes so any module can check without asking the lock module.
function GameState.isBaseLocked(base): boolean
	if not base then
		return false
	end
	local lockedUntil = base:GetAttribute("LockedUntil")
	if typeof(lockedUntil) ~= "number" then
		return false
	end
	return os.time() < lockedUntil
end

-- First free Slot part of a base, or nil when all six are taken.
function GameState.findFreeSlot(base)
	if not base then
		return nil
	end
	for i = 1, Config.BASE_SLOTS do
		local slot = base:FindFirstChild("Slot" .. i)
		if slot and slot:GetAttribute("BrainrotId") == nil then
			return slot
		end
	end
	return nil
end

-- Total $/second a player earns from every brainrot they own.
function GameState.getIncomePerSecond(state): number
	local total = 0
	for _, record in ipairs(state.owned) do
		total += BrainrotData.getIncomeRate(record.character, record.mutation, state.rebirths)
	end
	return total
end

-- Find a brainrot record by id, whether it is walking or owned.
function GameState.findBrainrot(brainrotId: string)
	for _, record in ipairs(GameState.walking) do
		if record.id == brainrotId then
			return record
		end
	end
	for _, state in pairs(GameState.players) do
		for _, record in ipairs(state.owned) do
			if record.id == brainrotId then
				return record
			end
		end
	end
	return nil
end

-- Remove a brainrot from the walking list (after a buy or a despawn).
function GameState.removeFromWalking(record)
	local index = table.find(GameState.walking, record)
	if index then
		table.remove(GameState.walking, index)
	end
end

-- Remove a brainrot from its owner's collection (after a sell, a steal
-- or a rebirth) and free the slot it sat on.
function GameState.removeFromOwned(record)
	local owner = record.owner
	if not owner then
		return
	end
	local state = GameState.getPlayerState(owner)
	if not state then
		return
	end
	local index = table.find(state.owned, record)
	if index then
		table.remove(state.owned, index)
	end
	if record.slot then
		record.slot:SetAttribute("BrainrotId", nil)
		record.slot = nil
	end
	record.owner = nil
end

return GameState
