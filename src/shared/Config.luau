-- Config: every tuning number for Kopi Kungkang Brainrot lives in one place,
-- so the server modules never hard-code a magic number of their own.

local Config = {}

-- Economy
Config.START_MONEY = 500
Config.REBIRTH_BASE_COST = 50000
Config.REBIRTH_MULTIPLIER_PER_LEVEL = 0.5 -- +50% income per rebirth
Config.SELL_REFUND = 0.5 -- selling a brainrot refunds half its cost

-- Conveyor (matches the belt built in default.project.json)
Config.CONVEYOR_X = 0
Config.CONVEYOR_START_Z = -88
Config.CONVEYOR_END_Z = 88
Config.BELT_TOP_Y = 1
Config.BRAINROT_BODY_Y = 2.5 -- centre of a walking brainrot body above the belt
Config.WALK_SPEED = 6 -- studs per second along the conveyor
Config.SPAWN_INTERVAL = 4 -- seconds between spawn attempts
Config.MAX_WALKING = 12 -- at most this many brainrots walking at once

-- Bases
Config.BASE_SLOTS = 6 -- collection slots per base
Config.BASE_HALF_SIZE = 13 -- base pad is 26x26, used for the tsunami safe check

-- Base lock (anti-steal defence)
Config.LOCK_DURATION = 60 -- seconds a lock stays up
Config.LOCK_COOLDOWN = 150 -- seconds before the same base can lock again

-- Tsunami event
Config.TSUNAMI_FIRST_DELAY = 180 -- seconds after the server starts
Config.TSUNAMI_INTERVAL = 240 -- seconds between waves after one ends
Config.TSUNAMI_WARNING_SECONDS = 15 -- run home during this window
Config.TSUNAMI_SWEEP_SECONDS = 12 -- the wave crosses the map in this time
Config.TSUNAMI_CASH_LOSS = 0.10 -- caught outside your base: lose 10% of cash
Config.TSUNAMI_START_Z = -130
Config.TSUNAMI_END_Z = 130

return Config
