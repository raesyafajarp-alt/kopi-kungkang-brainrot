-- Kopi Kungkang Brainrot — server boot.
-- Wires the remotes, starts the game loop (spawning, income, HUD sync)
-- and the tsunami event loop. Nothing else runs here on purpose: each
-- system lives in its own module so one file does one job.

local Actions = require(script.Actions)
local GameLoop = require(script.GameLoop)
local Tsunami = require(script.Tsunami)

Actions.setupRemotes()
GameLoop.start()
task.spawn(Tsunami.start)

print("Kopi Kungkang Brainrot siap! Conveyor jalan, tsunami mengintai.")
