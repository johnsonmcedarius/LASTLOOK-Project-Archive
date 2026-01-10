--[[
	MainMenuController.lua
	Client-side controller for the main menu/lobby UI
	Handles navigation, queue, and menu transitions
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- Remote events
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local QueueEvent = Remotes:WaitForChild("QueueEvent")
local DataEvent = Remotes:WaitForChild("DataEvent")

-- Configuration
local Config = {
	TRANSITION_TIME = 0.3,
	BUTTON_HOVER_SCALE = 1.05,
	MENU_SLIDE_OFFSET = 100,
	LOGO_BOB_AMPLITUDE = 5,
	LOGO_BOB_SPEED = 2,
}

-- Menu states
local MenuState = {
	MAIN = "Main",
	PLAY = "Play",
	SHOP = "Shop",
	WARDROBE = "Wardrobe",
	PROFILE = "Profile",
	SETTINGS = "Settings",
	BATTLEPASS = "BattlePass",
	CHALLENGES = "Challenges",
}

local MainMenuController = {}
MainMenuController.__index = MainMenuController

local currentState = MenuState.MAIN
local isInQueue = false
local menuGui = nil
local connections = {}

-- Utility functions
local function createTween(object, properties, duration, easingStyle, easingDirection)
	local tweenInfo = TweenInfo.new(
		duration or Config.TRANSITION_TIME,
		easingStyle or Enum.EasingStyle.Quart,
		easingDirection or Enum.EasingDirection.Out
	)
	return TweenService:Create(object, tweenInfo, properties)
end

local function playSound(soundName)
	local sounds = SoundService:FindFirstChild("MenuSounds")
	if sounds then
		local sound = sounds:FindFirstChild(soundName)
		if sound then
			sound:Play()
		end
	end
end

-- Create the main menu GUI
function MainMenuController.CreateMenuGui()
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "MainMenuGui"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.IgnoreGuiInset = true

	-- Background gradient
	local background = Instance.new("Frame")
	background.Name = "Background"
	background.Size = UDim2.new(1, 0, 1, 0)
	background.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
	background.BorderSizePixel = 0
	background.Parent = screenGui

	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(25, 20, 35)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(15, 15, 20)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(10, 10, 15)),
	})
	gradient.Rotation = 45
	gradient.Parent = background

	-- Animated particles overlay
	local particleOverlay = Instance.new("Frame")
	particleOverlay.Name = "ParticleOverlay"
	particleOverlay.Size = UDim2.new(1, 0, 1, 0)
	particleOverlay.BackgroundTransparency = 1
	particleOverlay.Parent = background

	-- Logo container
	local logoContainer = Instance.new("Frame")
	logoContainer.Name = "LogoContainer"
	logoContainer.Size = UDim2.new(0, 400, 0, 150)
	logoContainer.Position = UDim2.new(0.5, 0, 0.15, 0)
	logoContainer.AnchorPoint = Vector2.new(0.5, 0.5)
	logoContainer.BackgroundTransparency = 1
	logoContainer.Parent = screenGui

	local logoText = Instance.new("TextLabel")
	logoText.Name = "LogoText"
	logoText.Size = UDim2.new(1, 0, 1, 0)
	logoText.BackgroundTransparency = 1
	logoText.Text = "LAST LOOK"
	logoText.TextColor3 = Color3.fromRGB(255, 215, 0)
	logoText.TextSize = 72
	logoText.Font = Enum.Font.GothamBlack
	logoText.TextStrokeTransparency = 0.5
	logoText.TextStrokeColor3 = Color3.fromRGB(139, 69, 19)
	logoText.Parent = logoContainer

	local tagline = Instance.new("TextLabel")
	tagline.Name = "Tagline"
	tagline.Size = UDim2.new(1, 0, 0, 30)
	tagline.Position = UDim2.new(0, 0, 1, 10)
	tagline.BackgroundTransparency = 1
	tagline.Text = "THE HAUNTED ATELIER"
	tagline.TextColor3 = Color3.fromRGB(180, 180, 180)
	tagline.TextSize = 18
	tagline.Font = Enum.Font.Gotham
	tagline.TextTransparency = 0.3
	tagline.Parent = logoContainer

	-- Main menu container
	local mainMenuContainer = Instance.new("Frame")
	mainMenuContainer.Name = "MainMenuContainer"
	mainMenuContainer.Size = UDim2.new(0, 300, 0, 450)
	mainMenuContainer.Position = UDim2.new(0.5, 0, 0.55, 0)
	mainMenuContainer.AnchorPoint = Vector2.new(0.5, 0.5)
	mainMenuContainer.BackgroundTransparency = 1
	mainMenuContainer.Parent = screenGui

	local menuLayout = Instance.new("UIListLayout")
	menuLayout.Padding = UDim.new(0, 15)
	menuLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	menuLayout.SortOrder = Enum.SortOrder.LayoutOrder
	menuLayout.Parent = mainMenuContainer

	-- Menu buttons
	local buttons = {
		{name = "Play", text = "▶  PLAY", color = Color3.fromRGB(76, 175, 80), order = 1},
		{name = "Shop", text = "🛒  BOUTIQUE", color = Color3.fromRGB(156, 39, 176), order = 2},
		{name = "Wardrobe", text = "👔  WARDROBE", color = Color3.fromRGB(33, 150, 243), order = 3},
		{name = "Challenges", text = "📋  CHALLENGES", color = Color3.fromRGB(255, 152, 0), order = 4},
		{name = "BattlePass", text = "⭐  RUNWAY PASS", color = Color3.fromRGB(233, 30, 99), order = 5},
		{name = "Profile", text = "👤  PROFILE", color = Color3.fromRGB(96, 125, 139), order = 6},
		{name = "Settings", text = "⚙  SETTINGS", color = Color3.fromRGB(117, 117, 117), order = 7},
	}

	for _, buttonData in ipairs(buttons) do
		local button = MainMenuController.CreateMenuButton(buttonData)
		button.Parent = mainMenuContainer
	end

	-- Player info panel (bottom left)
	local playerPanel = MainMenuController.CreatePlayerPanel()
	playerPanel.Parent = screenGui

	-- Currency display (top right)
	local currencyPanel = MainMenuController.CreateCurrencyPanel()
	currencyPanel.Parent = screenGui

	-- Version info (bottom right)
	local versionLabel = Instance.new("TextLabel")
	versionLabel.Name = "VersionLabel"
	versionLabel.Size = UDim2.new(0, 200, 0, 20)
	versionLabel.Position = UDim2.new(1, -10, 1, -10)
	versionLabel.AnchorPoint = Vector2.new(1, 1)
	versionLabel.BackgroundTransparency = 1
	versionLabel.Text = "v1.0.0 | LAST LOOK"
	versionLabel.TextColor3 = Color3.fromRGB(100, 100, 100)
	versionLabel.TextSize = 12
	versionLabel.Font = Enum.Font.Gotham
	versionLabel.TextXAlignment = Enum.TextXAlignment.Right
	versionLabel.Parent = screenGui

	-- Queue panel (hidden by default)
	local queuePanel = MainMenuController.CreateQueuePanel()
	queuePanel.Parent = screenGui
	queuePanel.Visible = false

	return screenGui
end

function MainMenuController.CreateMenuButton(data)
	local button = Instance.new("TextButton")
	button.Name = data.name .. "Button"
	button.Size = UDim2.new(1, 0, 0, 50)
	button.BackgroundColor3 = data.color
	button.BorderSizePixel = 0
	button.Text = data.text
	button.TextColor3 = Color3.fromRGB(255, 255, 255)
	button.TextSize = 20
	button.Font = Enum.Font.GothamBold
	button.LayoutOrder = data.order
	button.AutoButtonColor = false

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = button

	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 2
	stroke.Color = Color3.fromRGB(255, 255, 255)
	stroke.Transparency = 0.8
	stroke.Parent = button

	local shadow = Instance.new("ImageLabel")
	shadow.Name = "Shadow"
	shadow.Size = UDim2.new(1, 10, 1, 10)
	shadow.Position = UDim2.new(0, -5, 0, 2)
	shadow.BackgroundTransparency = 1
	shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
	shadow.ImageTransparency = 0.7
	shadow.ZIndex = 0
	shadow.Parent = button

	-- Hover effects
	button.MouseEnter:Connect(function()
		playSound("Hover")
		createTween(button, {Size = UDim2.new(1, 10, 0, 55)}, 0.15):Play()
		createTween(stroke, {Transparency = 0.4}, 0.15):Play()
	end)

	button.MouseLeave:Connect(function()
		createTween(button, {Size = UDim2.new(1, 0, 0, 50)}, 0.15):Play()
		createTween(stroke, {Transparency = 0.8}, 0.15):Play()
	end)

	-- Click handler
	button.MouseButton1Click:Connect(function()
		playSound("Click")
		MainMenuController.OnMenuButtonClicked(data.name)
	end)

	return button
end

function MainMenuController.CreatePlayerPanel()
	local panel = Instance.new("Frame")
	panel.Name = "PlayerPanel"
	panel.Size = UDim2.new(0, 300, 0, 80)
	panel.Position = UDim2.new(0, 20, 1, -20)
	panel.AnchorPoint = Vector2.new(0, 1)
	panel.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
	panel.BackgroundTransparency = 0.3
	panel.BorderSizePixel = 0

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = panel

	-- Player avatar
	local avatarFrame = Instance.new("Frame")
	avatarFrame.Name = "AvatarFrame"
	avatarFrame.Size = UDim2.new(0, 60, 0, 60)
	avatarFrame.Position = UDim2.new(0, 10, 0.5, 0)
	avatarFrame.AnchorPoint = Vector2.new(0, 0.5)
	avatarFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
	avatarFrame.Parent = panel

	local avatarCorner = Instance.new("UICorner")
	avatarCorner.CornerRadius = UDim.new(0, 8)
	avatarCorner.Parent = avatarFrame

	local avatar = Instance.new("ImageLabel")
	avatar.Name = "Avatar"
	avatar.Size = UDim2.new(1, -4, 1, -4)
	avatar.Position = UDim2.new(0, 2, 0, 2)
	avatar.BackgroundTransparency = 1
	avatar.Image = Players:GetUserThumbnailAsync(
		LocalPlayer.UserId,
		Enum.ThumbnailType.HeadShot,
		Enum.ThumbnailSize.Size150x150
	)
	avatar.Parent = avatarFrame

	local avatarImgCorner = Instance.new("UICorner")
	avatarImgCorner.CornerRadius = UDim.new(0, 6)
	avatarImgCorner.Parent = avatar

	-- Player name
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "PlayerName"
	nameLabel.Size = UDim2.new(0, 200, 0, 25)
	nameLabel.Position = UDim2.new(0, 80, 0, 15)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = LocalPlayer.DisplayName
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLabel.TextSize = 18
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.Parent = panel

	-- Level display
	local levelLabel = Instance.new("TextLabel")
	levelLabel.Name = "LevelLabel"
	levelLabel.Size = UDim2.new(0, 200, 0, 20)
	levelLabel.Position = UDim2.new(0, 80, 0, 42)
	levelLabel.BackgroundTransparency = 1
	levelLabel.Text = "Level 1 • 0 XP"
	levelLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
	levelLabel.TextSize = 14
	levelLabel.Font = Enum.Font.Gotham
	levelLabel.TextXAlignment = Enum.TextXAlignment.Left
	levelLabel.Parent = panel

	return panel
end

function MainMenuController.CreateCurrencyPanel()
	local panel = Instance.new("Frame")
	panel.Name = "CurrencyPanel"
	panel.Size = UDim2.new(0, 250, 0, 70)
	panel.Position = UDim2.new(1, -20, 0, 20)
	panel.AnchorPoint = Vector2.new(1, 0)
	panel.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
	panel.BackgroundTransparency = 0.3
	panel.BorderSizePixel = 0

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = panel

	-- Spools display
	local spoolsFrame = Instance.new("Frame")
	spoolsFrame.Name = "SpoolsFrame"
	spoolsFrame.Size = UDim2.new(1, -20, 0, 25)
	spoolsFrame.Position = UDim2.new(0, 10, 0, 10)
	spoolsFrame.BackgroundTransparency = 1
	spoolsFrame.Parent = panel

	local spoolsIcon = Instance.new("TextLabel")
	spoolsIcon.Name = "Icon"
	spoolsIcon.Size = UDim2.new(0, 25, 1, 0)
	spoolsIcon.BackgroundTransparency = 1
	spoolsIcon.Text = "🧵"
	spoolsIcon.TextSize = 18
	spoolsIcon.Parent = spoolsFrame

	local spoolsLabel = Instance.new("TextLabel")
	spoolsLabel.Name = "Amount"
	spoolsLabel.Size = UDim2.new(1, -35, 1, 0)
	spoolsLabel.Position = UDim2.new(0, 30, 0, 0)
	spoolsLabel.BackgroundTransparency = 1
	spoolsLabel.Text = "0 Spools"
	spoolsLabel.TextColor3 = Color3.fromRGB(156, 39, 176)
	spoolsLabel.TextSize = 16
	spoolsLabel.Font = Enum.Font.GothamBold
	spoolsLabel.TextXAlignment = Enum.TextXAlignment.Left
	spoolsLabel.Parent = spoolsFrame

	-- Influence display
	local influenceFrame = Instance.new("Frame")
	influenceFrame.Name = "InfluenceFrame"
	influenceFrame.Size = UDim2.new(1, -20, 0, 25)
	influenceFrame.Position = UDim2.new(0, 10, 0, 38)
	influenceFrame.BackgroundTransparency = 1
	influenceFrame.Parent = panel

	local influenceIcon = Instance.new("TextLabel")
	influenceIcon.Name = "Icon"
	influenceIcon.Size = UDim2.new(0, 25, 1, 0)
	influenceIcon.BackgroundTransparency = 1
	influenceIcon.Text = "📍"
	influenceIcon.TextSize = 18
	influenceIcon.Parent = influenceFrame

	local influenceLabel = Instance.new("TextLabel")
	influenceLabel.Name = "Amount"
	influenceLabel.Size = UDim2.new(1, -35, 1, 0)
	influenceLabel.Position = UDim2.new(0, 30, 0, 0)
	influenceLabel.BackgroundTransparency = 1
	influenceLabel.Text = "0 Influence"
	influenceLabel.TextColor3 = Color3.fromRGB(255, 193, 7)
	influenceLabel.TextSize = 16
	influenceLabel.Font = Enum.Font.GothamBold
	influenceLabel.TextXAlignment = Enum.TextXAlignment.Left
	influenceLabel.Parent = influenceFrame

	return panel
end

function MainMenuController.CreateQueuePanel()
	local panel = Instance.new("Frame")
	panel.Name = "QueuePanel"
	panel.Size = UDim2.new(0, 400, 0, 200)
	panel.Position = UDim2.new(0.5, 0, 0.5, 0)
	panel.AnchorPoint = Vector2.new(0.5, 0.5)
	panel.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
	panel.BorderSizePixel = 0

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 16)
	corner.Parent = panel

	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 2
	stroke.Color = Color3.fromRGB(76, 175, 80)
	stroke.Parent = panel

	-- Title
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, 0, 0, 40)
	title.Position = UDim2.new(0, 0, 0, 15)
	title.BackgroundTransparency = 1
	title.Text = "FINDING MATCH..."
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.TextSize = 24
	title.Font = Enum.Font.GothamBold
	title.Parent = panel

	-- Spinner
	local spinner = Instance.new("ImageLabel")
	spinner.Name = "Spinner"
	spinner.Size = UDim2.new(0, 60, 0, 60)
	spinner.Position = UDim2.new(0.5, 0, 0.5, -10)
	spinner.AnchorPoint = Vector2.new(0.5, 0.5)
	spinner.BackgroundTransparency = 1
	spinner.Image = "rbxassetid://6031302931" -- Loading spinner
	spinner.Parent = panel

	-- Player count
	local playerCount = Instance.new("TextLabel")
	playerCount.Name = "PlayerCount"
	playerCount.Size = UDim2.new(1, 0, 0, 25)
	playerCount.Position = UDim2.new(0, 0, 1, -70)
	playerCount.BackgroundTransparency = 1
	playerCount.Text = "Players in queue: 1"
	playerCount.TextColor3 = Color3.fromRGB(180, 180, 180)
	playerCount.TextSize = 16
	playerCount.Font = Enum.Font.Gotham
	playerCount.Parent = panel

	-- Cancel button
	local cancelButton = Instance.new("TextButton")
	cancelButton.Name = "CancelButton"
	cancelButton.Size = UDim2.new(0, 150, 0, 40)
	cancelButton.Position = UDim2.new(0.5, 0, 1, -20)
	cancelButton.AnchorPoint = Vector2.new(0.5, 1)
	cancelButton.BackgroundColor3 = Color3.fromRGB(244, 67, 54)
	cancelButton.BorderSizePixel = 0
	cancelButton.Text = "CANCEL"
	cancelButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	cancelButton.TextSize = 16
	cancelButton.Font = Enum.Font.GothamBold
	cancelButton.Parent = panel

	local cancelCorner = Instance.new("UICorner")
	cancelCorner.CornerRadius = UDim.new(0, 8)
	cancelCorner.Parent = cancelButton

	cancelButton.MouseButton1Click:Connect(function()
		MainMenuController.LeaveQueue()
	end)

	return panel
end

function MainMenuController.OnMenuButtonClicked(buttonName)
	if buttonName == "Play" then
		MainMenuController.JoinQueue()
	elseif buttonName == "Shop" then
		-- Open shop UI (handled by BoutiqueUIController)
		local boutiqueEvent = Remotes:FindFirstChild("BoutiqueEvent")
		if boutiqueEvent then
			boutiqueEvent:FireServer("Open")
		end
		MainMenuController.HideMenu()
	elseif buttonName == "Wardrobe" then
		-- Open wardrobe (handled by WardrobeController)
		local wardrobeEvent = Remotes:FindFirstChild("WardrobeEvent")
		if wardrobeEvent then
			wardrobeEvent:FireServer("Open")
		end
		MainMenuController.HideMenu()
	elseif buttonName == "Profile" then
		MainMenuController.OpenProfile()
	elseif buttonName == "Settings" then
		MainMenuController.OpenSettings()
	elseif buttonName == "BattlePass" then
		MainMenuController.OpenBattlePass()
	elseif buttonName == "Challenges" then
		MainMenuController.OpenChallenges()
	end
end

function MainMenuController.JoinQueue()
	if isInQueue then return end

	isInQueue = true
	local queuePanel = menuGui:FindFirstChild("QueuePanel")
	if queuePanel then
		queuePanel.Visible = true

		-- Animate spinner
		local spinner = queuePanel:FindFirstChild("Spinner")
		if spinner then
			local spinConnection
			spinConnection = RunService.Heartbeat:Connect(function(dt)
				spinner.Rotation = spinner.Rotation + (dt * 180)
			end)
			table.insert(connections, spinConnection)
		end
	end

	QueueEvent:FireServer("Join")
end

function MainMenuController.LeaveQueue()
	isInQueue = false
	local queuePanel = menuGui:FindFirstChild("QueuePanel")
	if queuePanel then
		queuePanel.Visible = false
	end

	QueueEvent:FireServer("Leave")
end

function MainMenuController.ShowMenu()
	if menuGui then
		menuGui.Enabled = true

		-- Fade in animation
		local mainContainer = menuGui:FindFirstChild("MainMenuContainer")
		if mainContainer then
			mainContainer.Position = UDim2.new(0.5, 0, 0.6, 0)
			createTween(mainContainer, {Position = UDim2.new(0.5, 0, 0.55, 0)}, 0.4, Enum.EasingStyle.Back):Play()
		end
	end
end

function MainMenuController.HideMenu()
	if menuGui then
		menuGui.Enabled = false
	end
end

function MainMenuController.OpenProfile()
	-- Trigger profile UI (will be handled by ProfileController)
	local profileEvent = Remotes:FindFirstChild("ProfileEvent")
	if profileEvent then
		profileEvent:FireServer("Open")
	end
end

function MainMenuController.OpenSettings()
	-- Trigger settings UI (will be handled by SettingsController)
	local settingsEvent = Remotes:FindFirstChild("SettingsEvent")
	if settingsEvent then
		settingsEvent:FireServer("Open")
	end
end

function MainMenuController.OpenBattlePass()
	-- Trigger battle pass UI
	local battlePassEvent = Remotes:FindFirstChild("BattlePassEvent")
	if battlePassEvent then
		battlePassEvent:FireServer("Open")
	end
end

function MainMenuController.OpenChallenges()
	-- Trigger challenges UI
	local challengesEvent = Remotes:FindFirstChild("ChallengesEvent")
	if challengesEvent then
		challengesEvent:FireServer("Open")
	end
end

function MainMenuController.UpdateCurrency(spools, influence)
	if not menuGui then return end

	local currencyPanel = menuGui:FindFirstChild("CurrencyPanel")
	if currencyPanel then
		local spoolsLabel = currencyPanel.SpoolsFrame.Amount
		local influenceLabel = currencyPanel.InfluenceFrame.Amount

		spoolsLabel.Text = tostring(spools) .. " Spools"
		influenceLabel.Text = tostring(influence) .. " Influence"
	end
end

function MainMenuController.UpdatePlayerInfo(level, xp)
	if not menuGui then return end

	local playerPanel = menuGui:FindFirstChild("PlayerPanel")
	if playerPanel then
		local levelLabel = playerPanel:FindFirstChild("LevelLabel")
		if levelLabel then
			levelLabel.Text = string.format("Level %d • %d XP", level, xp)
		end
	end
end

-- Logo animation
function MainMenuController.StartLogoAnimation()
	local logoContainer = menuGui:FindFirstChild("LogoContainer")
	if not logoContainer then return end

	local startY = logoContainer.Position.Y.Offset
	local connection = RunService.Heartbeat:Connect(function()
		local time = tick()
		local offset = math.sin(time * Config.LOGO_BOB_SPEED) * Config.LOGO_BOB_AMPLITUDE
		logoContainer.Position = UDim2.new(0.5, 0, 0.15, startY + offset)
	end)
	table.insert(connections, connection)
end

-- Initialize
function MainMenuController.Init()
	menuGui = MainMenuController.CreateMenuGui()
	menuGui.Parent = PlayerGui

	MainMenuController.StartLogoAnimation()

	-- Listen for data updates
	DataEvent.OnClientEvent:Connect(function(action, data)
		if action == "Update" then
			MainMenuController.UpdateCurrency(data.Spools or 0, data.Influence or 0)
			MainMenuController.UpdatePlayerInfo(data.Level or 1, data.XP or 0)
		end
	end)

	-- Listen for round start to hide menu
	local gameValues = ReplicatedStorage:WaitForChild("GameValues")
	gameValues:GetAttributeChangedSignal("RoundActive"):Connect(function()
		if gameValues:GetAttribute("RoundActive") then
			MainMenuController.HideMenu()
		else
			MainMenuController.ShowMenu()
		end
	end)

	print("[MainMenuController] Initialized")
end

-- Cleanup
function MainMenuController.Cleanup()
	for _, connection in ipairs(connections) do
		connection:Disconnect()
	end
	connections = {}

	if menuGui then
		menuGui:Destroy()
		menuGui = nil
	end
end

-- Auto-initialize
MainMenuController.Init()

return MainMenuController
