-- BrainrotData: the original cast of Kopi Kungkang Brainrot.
-- Every character, rarity and mutation here is invented for this game:
-- Indonesian street-food and everyday memes, never a Steal a Brainrot name.
-- Both server and client read this module, so names, colours and rates
-- shown on screen always match what the server charges and pays.

local BrainrotData = {}

-- Rarity ladder, cheapest first. `weight` is the spawn chance out of 100.
BrainrotData.RARITIES = {
	{ name = "Common", color = Color3.fromRGB(190, 190, 190), weight = 55, order = 1 },
	{ name = "Rare", color = Color3.fromRGB(80, 180, 255), weight = 25, order = 2 },
	{ name = "Epic", color = Color3.fromRGB(180, 90, 255), weight = 12, order = 3 },
	{ name = "Legendary", color = Color3.fromRGB(255, 200, 40), weight = 6, order = 4 },
	{ name = "Mythic", color = Color3.fromRGB(255, 70, 120), weight = 2, order = 5 },
}

-- Mutations rolled when a brainrot spawns. `mult` multiplies its $/second.
BrainrotData.MUTATIONS = {
	{ name = "Normal", mult = 1, weight = 87.5, color = Color3.fromRGB(255, 255, 255) },
	{ name = "Golden", mult = 2, weight = 8, color = Color3.fromRGB(255, 210, 60) },
	{ name = "Diamond", mult = 3, weight = 3, color = Color3.fromRGB(120, 220, 255) },
	{ name = "Pelangi", mult = 5, weight = 1.5, color = Color3.fromRGB(255, 120, 220) },
}

-- The cast. `rate` is base $/second, `cost` is the buy price.
-- `shape` is the body part shape, `accessory` picks the extra part the
-- factory builds on top of the body.
BrainrotData.CAST = {
	{ id = "kopi", name = "Kopi Kungkang", rarity = "Common", cost = 100, rate = 5,
		bodyColor = Color3.fromRGB(122, 72, 32), shape = "Block", accessory = "Cup" },
	{ id = "meong", name = "Meong Micin", rarity = "Common", cost = 250, rate = 8,
		bodyColor = Color3.fromRGB(255, 165, 60), shape = "Block", accessory = "Fish" },
	{ id = "bakso", name = "Bakso Berlari", rarity = "Common", cost = 500, rate = 12,
		bodyColor = Color3.fromRGB(210, 180, 140), shape = "Ball", accessory = "Bowl" },
	{ id = "nasgor", name = "Nasi Goreng Ninja", rarity = "Rare", cost = 1200, rate = 25,
		bodyColor = Color3.fromRGB(240, 200, 60), shape = "Block", accessory = "Headband" },
	{ id = "esteh", name = "Es Teh Manis Terbang", rarity = "Rare", cost = 2500, rate = 40,
		bodyColor = Color3.fromRGB(200, 120, 40), shape = "Cylinder", accessory = "Wings" },
	{ id = "gorengan", name = "Gorengan Sakti", rarity = "Epic", cost = 6000, rate = 70,
		bodyColor = Color3.fromRGB(180, 120, 40), shape = "Ball", accessory = "Cape" },
	{ id = "sate", name = "Sate Klathak Raksasa", rarity = "Epic", cost = 12000, rate = 120,
		bodyColor = Color3.fromRGB(90, 50, 25), shape = "Block", accessory = "Skewer" },
	{ id = "rendang", name = "Rendang Raja", rarity = "Legendary", cost = 30000, rate = 250,
		bodyColor = Color3.fromRGB(140, 30, 20), shape = "Block", accessory = "Crown" },
	{ id = "durian", name = "Durian Meledak", rarity = "Legendary", cost = 60000, rate = 450,
		bodyColor = Color3.fromRGB(90, 160, 50), shape = "Ball", accessory = "Fuse" },
	{ id = "kerupuk", name = "Kerupuk Kosmik", rarity = "Mythic", cost = 150000, rate = 1000,
		bodyColor = Color3.fromRGB(255, 240, 245), shape = "Ball", accessory = "Halo" },
}

-- Look a rarity row up by name; falls back to Common.
function BrainrotData.getRarity(rarityName: string)
	for _, row in ipairs(BrainrotData.RARITIES) do
		if row.name == rarityName then
			return row
		end
	end
	return BrainrotData.RARITIES[1]
end

-- Look a mutation row up by name; falls back to Normal.
function BrainrotData.getMutation(mutationName: string)
	for _, row in ipairs(BrainrotData.MUTATIONS) do
		if row.name == mutationName then
			return row
		end
	end
	return BrainrotData.MUTATIONS[1]
end

-- Roll a rarity name from the weights in RARITIES.
function BrainrotData.rollRarity(): string
	local roll = math.random() * 100
	local running = 0
	for _, row in ipairs(BrainrotData.RARITIES) do
		running += row.weight
		if roll <= running then
			return row.name
		end
	end
	return "Common"
end

-- Roll a mutation name from the weights in MUTATIONS.
function BrainrotData.rollMutation(): string
	local roll = math.random() * 100
	local running = 0
	for _, row in ipairs(BrainrotData.MUTATIONS) do
		running += row.weight
		if roll <= running then
			return row.name
		end
	end
	return "Normal"
end

-- Pick a random cast member of the given rarity.
function BrainrotData.pickCharacter(rarityName: string)
	local pool = {}
	for _, character in ipairs(BrainrotData.CAST) do
		if character.rarity == rarityName then
			table.insert(pool, character)
		end
	end
	if #pool == 0 then
		return BrainrotData.CAST[1]
	end
	return pool[math.random(1, #pool)]
end

-- The $/second one brainrot earns, after its mutation and its owner's rebirths.
function BrainrotData.getIncomeRate(character, mutationName: string, rebirthCount: number): number
	local mutation = BrainrotData.getMutation(mutationName)
	local rebirthMult = 1 + 0.5 * rebirthCount
	return math.floor(character.rate * mutation.mult * rebirthMult)
end

-- "$1,234,567" style formatting for HUD and billboards.
function BrainrotData.formatMoney(amount: number): string
	local whole = math.floor(amount)
	local text = tostring(whole)
	local formatted = ""
	while #text > 3 do
		formatted = "," .. string.sub(text, -3) .. formatted
		text = string.sub(text, 1, -4)
	end
	return "$" .. text .. formatted
end

return BrainrotData
