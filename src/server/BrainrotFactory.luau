-- BrainrotFactory: builds the 3D model of one brainrot from its cast row
-- and mutation. Every brainrot is built from plain parts (no meshes, no
-- asset ids), so the place needs no uploaded assets to look right:
-- a coloured body, two eyes, one accessory part, and a billboard that
-- shows its name, rarity and $/second to anyone nearby.

local BrainrotData = require(game:GetService("ReplicatedStorage").Shared.BrainrotData)

local BrainrotFactory = {}

local BODY_SIZE = Vector3.new(3, 3, 3)

-- One accessory part per cast member. Each entry: shape, size, offset
-- from the body centre, colour.
local ACCESSORIES = {
	Cup = { shape = "Cylinder", size = Vector3.new(1.2, 1, 1.2), offset = Vector3.new(0, 2, 0), color = Color3.fromRGB(255, 255, 255) },
	Fish = { shape = "Block", size = Vector3.new(1.6, 0.5, 0.7), offset = Vector3.new(0, 1.9, 0), color = Color3.fromRGB(120, 180, 255) },
	Bowl = { shape = "Cylinder", size = Vector3.new(2, 0.6, 2), offset = Vector3.new(0, -1.7, 0), color = Color3.fromRGB(255, 80, 80) },
	Headband = { shape = "Block", size = Vector3.new(3.2, 0.5, 3.2), offset = Vector3.new(0, 1.2, 0), color = Color3.fromRGB(40, 40, 40) },
	Wings = { shape = "Block", size = Vector3.new(1.2, 0.2, 2.4), offset = Vector3.new(0, 0.5, 0), color = Color3.fromRGB(255, 255, 255) },
	Cape = { shape = "Block", size = Vector3.new(0.3, 2.6, 2.6), offset = Vector3.new(-1.7, 0, 0), color = Color3.fromRGB(200, 30, 30) },
	Skewer = { shape = "Cylinder", size = Vector3.new(0.4, 4.5, 0.4), offset = Vector3.new(0, 0, 0), color = Color3.fromRGB(200, 170, 120) },
	Crown = { shape = "Cylinder", size = Vector3.new(1.8, 0.8, 1.8), offset = Vector3.new(0, 1.9, 0), color = Color3.fromRGB(255, 210, 60) },
	Fuse = { shape = "Cylinder", size = Vector3.new(0.4, 1.4, 0.4), offset = Vector3.new(0, 2.1, 0), color = Color3.fromRGB(60, 60, 60) },
	Halo = { shape = "Cylinder", size = Vector3.new(2.6, 0.3, 2.6), offset = Vector3.new(0, 2.2, 0), color = Color3.fromRGB(255, 220, 90) },
}

local function makePart(name: string, shape: Enum.PartType, size: Vector3, color: Color3): BasePart
	local part = Instance.new("Part")
	part.Name = name
	part.Shape = shape
	part.Size = size
	part.Color = color
	part.Material = Enum.Material.SmoothPlastic
	part.Anchored = true
	part.CanCollide = false
	return part
end

-- Refresh the billboard text of a brainrot after its rate changes
-- (for example when its owner rebirths).
function BrainrotFactory.refreshBillboard(record)
	local model = record.model
	if not model then
		return
	end
	local billboard = model:FindFirstChild("InfoBillboard")
	if not billboard then
		return
	end
	local rarity = BrainrotData.getRarity(record.character.rarity)
	local rebirths = 0
	if record.owner then
		local state = require(script.Parent.GameState).getPlayerState(record.owner)
		if state then
			rebirths = state.rebirths
		end
	end
	local rate = BrainrotData.getIncomeRate(record.character, record.mutation, rebirths)
	local nameLabel = billboard:FindFirstChild("NameLabel")
	local rateLabel = billboard:FindFirstChild("RateLabel")
	if nameLabel and nameLabel:IsA("TextLabel") then
		local mutation = BrainrotData.getMutation(record.mutation)
		local prefix = ""
		if record.mutation ~= "Normal" then
			prefix = record.mutation .. " "
		end
		nameLabel.Text = prefix .. record.character.name
		nameLabel.TextColor3 = rarity.color
	end
	if rateLabel and rateLabel:IsA("TextLabel") then
		rateLabel.Text = BrainrotData.formatMoney(rate) .. "/detik  •  " .. record.character.rarity
	end
end

-- Build the model for a brainrot record and parent it under Workspace.Brainrots.
-- Returns the model. The buy and steal ProximityPrompts are created here
-- but left disabled; Actions enables the right one at the right time.
function BrainrotFactory.buildBrainrotModel(record): Model
	local character = record.character
	local mutation = BrainrotData.getMutation(record.mutation)

	local folder = workspace:FindFirstChild("Brainrots")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "Brainrots"
		folder.Parent = workspace
	end

	local model = Instance.new("Model")
	model.Name = "Brainrot_" .. record.id

	local body = makePart("Body", Enum.PartType[character.shape], BODY_SIZE, character.bodyColor)
	body.Name = "Body"
	-- Mutations tint the body: Golden glows yellow, Diamond icy blue, Pelangi pink.
	if record.mutation == "Golden" then
		body.Color = Color3.fromRGB(255, 210, 60)
		body.Material = Enum.Material.Neon
	elseif record.mutation == "Diamond" then
		body.Color = Color3.fromRGB(140, 220, 255)
		body.Material = Enum.Material.Neon
	elseif record.mutation == "Pelangi" then
		body.Color = Color3.fromRGB(255, 120, 220)
		body.Material = Enum.Material.Neon
	end
	body.Parent = model
	model.PrimaryPart = body

	-- Eyes, so the blob reads as a character from across the map.
	local eyeLeft = makePart("EyeLeft", Enum.PartType.Ball, Vector3.new(0.6, 0.6, 0.6), Color3.fromRGB(255, 255, 255))
	eyeLeft.Position = Vector3.new(-0.7, 0.5, 1.55)
	eyeLeft.Parent = model
	local eyeRight = makePart("EyeRight", Enum.PartType.Ball, Vector3.new(0.6, 0.6, 0.6), Color3.fromRGB(255, 255, 255))
	eyeRight.Position = Vector3.new(0.7, 0.5, 1.55)
	eyeRight.Parent = model
	local pupilLeft = makePart("PupilLeft", Enum.PartType.Ball, Vector3.new(0.3, 0.3, 0.3), Color3.fromRGB(20, 20, 20))
	pupilLeft.Position = Vector3.new(-0.7, 0.5, 1.85)
	pupilLeft.Parent = model
	local pupilRight = makePart("PupilRight", Enum.PartType.Ball, Vector3.new(0.3, 0.3, 0.3), Color3.fromRGB(20, 20, 20))
	pupilRight.Position = Vector3.new(0.7, 0.5, 1.85)
	pupilRight.Parent = model

	-- The character's signature accessory.
	local spec = ACCESSORIES[character.accessory]
	if spec then
		local accessory = makePart("Accessory", Enum.PartType[spec.shape], spec.size, spec.color)
		accessory.CFrame = CFrame.new(spec.offset)
		-- A cylinder accessory stands upright by default in Roblox when its
		-- height runs along Y; rotate the skewer to lie across the body.
		if character.accessory == "Skewer" then
			accessory.CFrame = CFrame.new(spec.offset) * CFrame.Angles(0, 0, math.rad(90))
		elseif character.accessory == "Cup" or character.accessory == "Bowl" then
			accessory.CFrame = CFrame.new(spec.offset) * CFrame.Angles(math.rad(90), 0, 0)
		end
		accessory.Parent = model
	end

	-- Billboard: name, rarity and $/second, readable from the conveyor.
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "InfoBillboard"
	billboard.Size = UDim2.new(0, 140, 0, 56)
	billboard.ExtentsOffsetWorldSpace = Vector3.new(0, 3.2, 0)
	billboard.AlwaysOnTop = true
	billboard.Adornee = body

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "NameLabel"
	nameLabel.Size = UDim2.new(1, 0, 0.55, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.TextScaled = true
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextStrokeTransparency = 0.4
	nameLabel.Parent = billboard

	local rateLabel = Instance.new("TextLabel")
	rateLabel.Name = "RateLabel"
	rateLabel.Position = UDim2.new(0, 0, 0.55, 0)
	rateLabel.Size = UDim2.new(1, 0, 0.45, 0)
	rateLabel.BackgroundTransparency = 1
	rateLabel.TextScaled = true
	rateLabel.Font = Enum.Font.Gotham
	rateLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	rateLabel.TextStrokeTransparency = 0.4
	rateLabel.Parent = billboard

	billboard.Parent = model

	-- Buy prompt: shown while the brainrot walks the conveyor.
	local buyPrompt = Instance.new("ProximityPrompt")
	buyPrompt.Name = "BuyPrompt"
	buyPrompt.ActionText = "Beli"
	buyPrompt.ObjectText = character.name .. " — " .. BrainrotData.formatMoney(character.cost)
	buyPrompt.HoldDuration = 0
	buyPrompt.MaxActivationDistance = 14
	buyPrompt.RequiresLineOfSight = false
	buyPrompt.Parent = body

	-- Steal prompt: shown once the brainrot sits in somebody's base.
	local stealPrompt = Instance.new("ProximityPrompt")
	stealPrompt.Name = "StealPrompt"
	stealPrompt.ActionText = "Curi!"
	stealPrompt.ObjectText = character.name .. " milik " .. (record.owner and record.owner.Name or "?")
	stealPrompt.HoldDuration = 3
	stealPrompt.MaxActivationDistance = 12
	stealPrompt.RequiresLineOfSight = false
	stealPrompt.Enabled = false
	stealPrompt.Parent = body

	model.Parent = folder
	record.model = model
	BrainrotFactory.refreshBillboard(record)
	return model
end

-- Glide a brainrot model from where it is to a target CFrame in small
-- steps, so a bought brainrot visibly hops over to its new base slot.
function BrainrotFactory.animateModelTo(model: Model, targetCFrame: CFrame)
	local startCFrame = model:GetPivot()
	local steps = 18
	for i = 1, steps do
		local alpha = i / steps
		-- A little hop arc on the way over.
		local hop = math.sin(alpha * math.pi) * 2
		local lerped = startCFrame:Lerp(targetCFrame, alpha)
		model:PivotTo(lerped + Vector3.new(0, hop, 0))
		task.wait(0.03)
	end
	model:PivotTo(targetCFrame)
end

return BrainrotFactory
