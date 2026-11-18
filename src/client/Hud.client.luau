-- Hud: the whole ScreenGui for Kopi Kungkang Brainrot, built in code.
-- Top-right money, left collection panel, bottom-left leaderboard,
-- bottom-right action buttons, a tsunami banner across the top and
-- toasts in the middle. Everything updates from the StateSync payload
-- the server sends once a second. The top-left corner is left clear:
-- Roblox's own menu buttons sit there.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BrainrotData = require(ReplicatedStorage.Shared.BrainrotData)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local gui = Instance.new("ScreenGui")
gui.Name = "BrainrotGui"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = false
gui.Parent = playerGui

local function makeLabel(name, parent, text, size, position, textSize, color)
	local label = Instance.new("TextLabel")
	label.Name = name
	label.Text = text
	label.Size = size
	label.Position = position
	label.BackgroundTransparency = 1
	label.TextColor3 = color or Color3.fromRGB(255, 255, 255)
	label.TextSize = textSize
	label.Font = Enum.Font.GothamBold
	label.TextStrokeTransparency = 0.5
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = parent
	return label
end

local function makeButton(name, parent, text, size, position, color)
	local button = Instance.new("TextButton")
	button.Name = name
	button.Text = text
	button.Size = size
	button.Position = position
	button.BackgroundColor3 = color
	button.TextColor3 = Color3.fromRGB(255, 255, 255)
	button.TextSize = 18
	button.Font = Enum.Font.GothamBold
	button.BorderSizePixel = 2
	button.BorderColor3 = Color3.fromRGB(0, 0, 0)
	button.Parent = parent
	return button
end

-- Top-right: money, income per second, rebirth count.
local moneyFrame = Instance.new("Frame")
moneyFrame.Name = "MoneyFrame"
moneyFrame.AnchorPoint = Vector2.new(1, 0)
moneyFrame.Position = UDim2.new(1, -12, 0, 12)
moneyFrame.Size = UDim2.new(0, 280, 0, 96)
moneyFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
moneyFrame.BackgroundTransparency = 0.25
moneyFrame.BorderSizePixel = 0
moneyFrame.Parent = gui

local moneyLabel = makeLabel("MoneyLabel", moneyFrame, "$500", UDim2.new(1, -16, 0, 40), UDim2.new(0, 16, 0, 6), 30, Color3.fromRGB(255, 220, 80))
local incomeLabel = makeLabel("IncomeLabel", moneyFrame, "+$0/detik", UDim2.new(1, -16, 0, 24), UDim2.new(0, 16, 0, 46), 18, Color3.fromRGB(120, 255, 140))
local rebirthLabel = makeLabel("RebirthLabel", moneyFrame, "Rebirth: 0", UDim2.new(1, -16, 0, 22), UDim2.new(0, 16, 0, 70), 16, Color3.fromRGB(180, 200, 255))

-- Top-centre: how to play, and the tsunami banner under it.
local helpLabel = makeLabel("HelpLabel", gui, "Beli brainrot di conveyor, simpan di basemu, awas pencuri dan tsunami!",
	UDim2.new(0, 620, 0, 26), UDim2.new(0.5, -310, 0, 10), 16, Color3.fromRGB(255, 255, 255))
helpLabel.TextXAlignment = Enum.TextXAlignment.Center

local banner = Instance.new("TextLabel")
banner.Name = "TsunamiBanner"
banner.AnchorPoint = Vector2.new(0.5, 0)
banner.Position = UDim2.new(0.5, 0, 0, 42)
banner.Size = UDim2.new(0, 560, 0, 44)
banner.BackgroundColor3 = Color3.fromRGB(200, 30, 30)
banner.BackgroundTransparency = 0.15
banner.TextColor3 = Color3.fromRGB(255, 255, 255)
banner.TextSize = 24
banner.Font = Enum.Font.GothamBold
banner.TextStrokeTransparency = 0.3
banner.Visible = false
banner.Parent = gui

-- Left: the player's collection, with a sell button per brainrot.
local collectionFrame = Instance.new("Frame")
collectionFrame.Name = "CollectionFrame"
collectionFrame.Position = UDim2.new(0, 12, 0, 120)
collectionFrame.Size = UDim2.new(0, 300, 0, 300)
collectionFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
collectionFrame.BackgroundTransparency = 0.25
collectionFrame.BorderSizePixel = 0
collectionFrame.Parent = gui

makeLabel("CollectionTitle", collectionFrame, "Koleksiku (max 6)", UDim2.new(1, -16, 0, 28), UDim2.new(0, 8, 0, 4), 18, Color3.fromRGB(255, 220, 80))

local collectionList = Instance.new("ScrollingFrame")
collectionList.Name = "CollectionList"
collectionList.Position = UDim2.new(0, 4, 0, 36)
collectionList.Size = UDim2.new(1, -8, 1, -40)
collectionList.BackgroundTransparency = 1
collectionList.ScrollBarThickness = 4
collectionList.CanvasSize = UDim2.new(0, 0, 0, 0)
collectionList.AutomaticCanvasSize = Enum.AutomaticSize.Y
collectionList.Parent = collectionFrame

-- Bottom-left: leaderboard, top 5 by cash.
local boardFrame = Instance.new("Frame")
boardFrame.Name = "LeaderboardFrame"
boardFrame.AnchorPoint = Vector2.new(0, 1)
boardFrame.Position = UDim2.new(0, 12, 1, -12)
boardFrame.Size = UDim2.new(0, 260, 0, 170)
boardFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
boardFrame.BackgroundTransparency = 0.25
boardFrame.BorderSizePixel = 0
boardFrame.Parent = gui

makeLabel("BoardTitle", boardFrame, "Top Pemain", UDim2.new(1, -16, 0, 28), UDim2.new(0, 8, 0, 4), 18, Color3.fromRGB(255, 220, 80))
local boardList = Instance.new("Frame")
boardList.Name = "BoardList"
boardList.Position = UDim2.new(0, 8, 0, 36)
boardList.Size = UDim2.new(1, -16, 1, -42)
boardList.BackgroundTransparency = 1
boardList.Parent = boardFrame

-- Bottom-right: Rebirth and Lock Base buttons.
local buttonsFrame = Instance.new("Frame")
buttonsFrame.Name = "ButtonsFrame"
buttonsFrame.AnchorPoint = Vector2.new(1, 1)
buttonsFrame.Position = UDim2.new(1, -12, 1, -12)
buttonsFrame.Size = UDim2.new(0, 280, 0, 110)
buttonsFrame.BackgroundTransparency = 1
buttonsFrame.Parent = gui

local rebirthButton = makeButton("RebirthButton", buttonsFrame, "Rebirth ($50,000)", UDim2.new(1, 0, 0, 48), UDim2.new(0, 0, 0, 0), Color3.fromRGB(150, 60, 200))
local lockButton = makeButton("LockButton", buttonsFrame, "Kunci Base (60 dtk)", UDim2.new(1, 0, 0, 48), UDim2.new(0, 0, 1, -48), Color3.fromRGB(40, 90, 200))

-- Toasts stack in the middle of the screen and fade away.
local toastFrame = Instance.new("Frame")
toastFrame.Name = "ToastFrame"
toastFrame.AnchorPoint = Vector2.new(0.5, 0)
toastFrame.Position = UDim2.new(0.5, 0, 0, 100)
toastFrame.Size = UDim2.new(0, 520, 0, 120)
toastFrame.BackgroundTransparency = 1
toastFrame.Parent = gui

local function showToast(message: string)
	local toast = Instance.new("TextLabel")
	toast.Text = message
	toast.Size = UDim2.new(1, 0, 0, 30)
	toast.Position = UDim2.new(0, 0, 0, (#toastFrame:GetChildren()) * 32)
	toast.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
	toast.BackgroundTransparency = 0.2
	toast.TextColor3 = Color3.fromRGB(255, 255, 255)
	toast.TextSize = 16
	toast.Font = Enum.Font.GothamBold
	toast.TextStrokeTransparency = 0.4
	toast.Parent = toastFrame
	task.delay(4, function()
		toast:Destroy()
	end)
end

-- Rebuild the collection rows only when the owned list actually changed.
local lastOwnedSignature = ""
local function rebuildCollection(owned)
	local signature = ""
	for _, item in ipairs(owned) do
		signature ..= item.id .. ","
	end
	if signature == lastOwnedSignature then
		return
	end
	lastOwnedSignature = signature
	for _, child in ipairs(collectionList:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end
	for index, item in ipairs(owned) do
		local row = Instance.new("Frame")
		row.Name = "Row_" .. item.id
		row.Size = UDim2.new(1, -4, 0, 44)
		row.Position = UDim2.new(0, 2, 0, (index - 1) * 48)
		row.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
		row.BackgroundTransparency = 0.15
		row.BorderSizePixel = 0
		row.Parent = collectionList

		local rarity = BrainrotData.getRarity(item.rarity)
		local nameText = item.name
		if item.mutation ~= "Normal" then
			nameText = item.mutation .. " " .. item.name
		end
		makeLabel("RowName", row, nameText, UDim2.new(1, -90, 0, 22), UDim2.new(0, 8, 0, 2), 15, rarity.color)
		makeLabel("RowRate", row, BrainrotData.formatMoney(item.rate) .. "/detik  •  " .. item.rarity,
			UDim2.new(1, -90, 0, 18), UDim2.new(0, 8, 0, 22), 13, Color3.fromRGB(220, 220, 220))

		local refund = math.floor(item.cost * 0.5)
		local sellButton = makeButton("SellButton", row, "Jual " .. BrainrotData.formatMoney(refund),
			UDim2.new(0, 82, 0, 32), UDim2.new(1, -86, 0, 6), Color3.fromRGB(60, 160, 80))
		sellButton.TextSize = 14
		sellButton.MouseButton1Click:Connect(function()
			ReplicatedStorage:WaitForChild("SellRequest"):FireServer(item.id)
		end)
	end
end

local function rebuildLeaderboard(leaderboard)
	for _, child in ipairs(boardList:GetChildren()) do
		child:Destroy()
	end
	for index, entry in ipairs(leaderboard) do
		makeLabel("Rank" .. index, boardList, index .. ". " .. entry.name .. " — " .. BrainrotData.formatMoney(entry.money),
			UDim2.new(1, 0, 0, 22), UDim2.new(0, 0, 0, (index - 1) * 24), 15,
			index == 1 and Color3.fromRGB(255, 220, 80) or Color3.fromRGB(255, 255, 255))
	end
end

-- Rebirth asks twice: first click arms it, second click within 3s fires.
local rebirthArmed = false
rebirthButton.MouseButton1Click:Connect(function()
	if rebirthArmed then
		rebirthArmed = false
		rebirthButton.Text = "Rebirth"
		ReplicatedStorage:WaitForChild("RebirthRequest"):FireServer()
	else
		rebirthArmed = true
		rebirthButton.Text = "Yakin? Klik lagi!"
		task.delay(3, function()
			rebirthArmed = false
			rebirthButton.Text = "Rebirth"
		end)
	end
end)

lockButton.MouseButton1Click:Connect(function()
	ReplicatedStorage:WaitForChild("LockRequest"):FireServer()
end)

ReplicatedStorage:WaitForChild("Toast").OnClientEvent:Connect(showToast)

-- The one-second state push from the server drives the whole HUD.
ReplicatedStorage:WaitForChild("StateSync").OnClientEvent:Connect(function(payload)
	moneyLabel.Text = BrainrotData.formatMoney(payload.money)
	incomeLabel.Text = "+" .. BrainrotData.formatMoney(payload.income) .. "/detik"
	rebirthLabel.Text = "Rebirth: " .. payload.rebirths .. "  •  Base: " .. payload.baseName
	if not rebirthArmed then
		rebirthButton.Text = "Rebirth (" .. BrainrotData.formatMoney(payload.rebirthCost) .. ")"
	end
	if payload.lockRemaining > 0 then
		lockButton.Text = "Terkunci (" .. payload.lockRemaining .. " dtk)"
		lockButton.BackgroundColor3 = Color3.fromRGB(60, 160, 80)
	elseif payload.lockCooldown > 0 then
		lockButton.Text = "Kunci (cooldown " .. payload.lockCooldown .. " dtk)"
		lockButton.BackgroundColor3 = Color3.fromRGB(90, 90, 110)
	else
		lockButton.Text = "Kunci Base (60 dtk)"
		lockButton.BackgroundColor3 = Color3.fromRGB(40, 90, 200)
	end
	if payload.eventPhase == "warning" then
		banner.Visible = true
		banner.Text = "TSUNAMI! Lari ke basemu! " .. payload.eventCountdown .. " detik!"
	elseif payload.eventPhase == "wave" then
		banner.Visible = true
		banner.Text = "TSUNAMI DATANG! Bertahan di dalam base!"
	else
		banner.Visible = false
	end
	rebuildCollection(payload.owned)
	rebuildLeaderboard(payload.leaderboard)
end)
