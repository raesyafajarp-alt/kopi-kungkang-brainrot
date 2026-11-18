-- Effects: client-side juice that needs no server round-trip.
-- Floating "+$X" popups rise above a random owned brainrot every second
-- or so, and a red flash frame covers the screen while a tsunami
-- warning or wave is running.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Red flash shown during tsunami warning and wave.
local flash = Instance.new("Frame")
flash.Name = "TsunamiFlash"
flash.Size = UDim2.fromScale(1, 1)
flash.BackgroundColor3 = Color3.fromRGB(200, 30, 30)
flash.BackgroundTransparency = 0.92
flash.BorderSizePixel = 0
flash.Visible = false
flash.Parent = playerGui:WaitForChild("BrainrotGui")

local latestPayload = nil
local lastPopupAt = 0

-- One floating "+$N" above a brainrot model, rising and fading.
local function spawnIncomePopup(model: Model, amount: number)
	local body = model.PrimaryPart
	if not body then
		return
	end
	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.new(0, 100, 0, 30)
	billboard.ExtentsOffsetWorldSpace = Vector3.new(0, 4.5, 0)
	billboard.AlwaysOnTop = true
	billboard.Adornee = body
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = "+$" .. tostring(amount)
	label.TextColor3 = Color3.fromRGB(120, 255, 140)
	label.TextSize = 22
	label.Font = Enum.Font.GothamBold
	label.TextStrokeTransparency = 0.3
	label.Parent = billboard
	billboard.Parent = model
	task.spawn(function()
		for i = 1, 20 do
			task.wait(0.05)
			if not billboard.Parent then
				return
			end
			billboard.ExtentsOffsetWorldSpace = Vector3.new(0, 4.5 + i * 0.12, 0)
			label.TextTransparency = i / 20
		end
		billboard:Destroy()
	end)
end

ReplicatedStorage:WaitForChild("StateSync").OnClientEvent:Connect(function(payload)
	latestPayload = payload
	flash.Visible = payload.eventPhase == "warning" or payload.eventPhase == "wave"
end)

-- Popup loop: about once a second, float the income of a random owned
-- brainrot above its model in the world.
task.spawn(function()
	while true do
		task.wait(1)
		local payload = latestPayload
		if payload and payload.income > 0 and #payload.owned > 0 then
			local now = os.clock()
			if now - lastPopupAt >= 1 then
				lastPopupAt = now
				local folder = workspace:FindFirstChild("Brainrots")
				if folder then
					local item = payload.owned[math.random(1, #payload.owned)]
					local model = folder:FindFirstChild("Brainrot_" .. item.id)
					if model then
						spawnIncomePopup(model, item.rate)
					end
				end
			end
		end
	end
end)
