-- Tsunami: the map-wide hazard. Every few minutes a warning goes out,
-- then a giant wave sweeps the map from north to south. Any player
-- caught outside their own base loses 10% of their cash and gets thrown
-- back to spawn. The HUD reads GameState.tsunami for the banner.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local GameState = require(script.Parent.GameState)

local Tsunami = {}

-- Is this player standing inside their own base right now?
function Tsunami.isPlayerSafe(player: Player): boolean
	local state = GameState.getPlayerState(player)
	if not state or not state.base then
		return false
	end
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then
		return false
	end
	local pad = state.base:FindFirstChild("Pad")
	if not pad then
		return false
	end
	local pos = root.Position
	return math.abs(pos.X - pad.Position.X) <= Config.BASE_HALF_SIZE
		and math.abs(pos.Z - pad.Position.Z) <= Config.BASE_HALF_SIZE
end

-- Count the warning down one second at a time so the HUD banner ticks.
function Tsunami.triggerWarning()
	GameState.tsunami.phase = "warning"
	for i = Config.TSUNAMI_WARNING_SECONDS, 1, -1 do
		GameState.tsunami.countdown = i
		task.wait(1)
	end
	GameState.tsunami.countdown = 0
end

-- Sweep the wave part across the map, punishing anyone caught outside
-- their base once, then park the wave back where it started.
function Tsunami.triggerWave()
	GameState.tsunami.phase = "wave"
	local wave = workspace:FindFirstChild("TsunamiWave")
	local punished = {}
	local stepCount = math.floor(Config.TSUNAMI_SWEEP_SECONDS / 0.1)
	for step = 0, stepCount do
		local alpha = step / stepCount
		local z = Config.TSUNAMI_START_Z + (Config.TSUNAMI_END_Z - Config.TSUNAMI_START_Z) * alpha
		if wave then
			wave.CFrame = CFrame.new(0, 12, z)
		end
		-- Check for stragglers every half second of the sweep.
		if step % 5 == 0 then
			for _, player in ipairs(Players:GetPlayers()) do
				if not punished[player] and not Tsunami.isPlayerSafe(player) then
					punished[player] = true
					local state = GameState.getPlayerState(player)
					if state then
						local lost = math.floor(state.money * Config.TSUNAMI_CASH_LOSS)
						state.money -= lost
						local toast = ReplicatedStorage:FindFirstChild("Toast")
						if toast then
							toast:FireClient(player, "Tsunami menghantammu! Kehilangan " .. "$" .. tostring(lost) .. ". Lari ke base lain kali!")
						end
					end
					local character = player.Character
					local root = character and character:FindFirstChild("HumanoidRootPart")
					local spawn = workspace:FindFirstChild("SpawnLocation")
					if root and spawn then
						root.CFrame = CFrame.new(spawn.Position + Vector3.new(0, 3, 0))
					end
				end
			end
		end
		task.wait(0.1)
	end
	if wave then
		wave.CFrame = CFrame.new(0, 12, Config.TSUNAMI_START_Z)
	end
	GameState.tsunami.phase = "idle"
	GameState.tsunami.countdown = 0
end

-- Main event loop: first wave a few minutes in, then one every interval.
function Tsunami.start()
	task.wait(Config.TSUNAMI_FIRST_DELAY)
	while true do
		Tsunami.triggerWarning()
		Tsunami.triggerWave()
		task.wait(Config.TSUNAMI_INTERVAL)
	end
end

-- Debug hook for TOUR.json: fire a warning right now, then the wave,
-- so a reviewer can bring the game to the tsunami screen on demand.
function Tsunami.triggerNow(_arg)
	task.spawn(function()
		Tsunami.triggerWarning()
		Tsunami.triggerWave()
	end)
end

return Tsunami
