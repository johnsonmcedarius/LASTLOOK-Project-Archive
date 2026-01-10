--[[
	ProfileController.lua
	Client-side profile/stats UI controller
	Displays player statistics, achievements, and match history
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- Remote events
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local ProfileController = {}
ProfileController.__index = ProfileController

local profileGui = nil
local isOpen = false

-- Stats categories
local STAT_CATEGORIES = {
	{
		name = "General",
		stats = {
			{key = "TotalMatches", label = "Matches Played", icon = "🎮"},
			{key = "TotalWins", label = "Victories", icon = "🏆"},
			{key = "WinRate", label = "Win Rate", icon = "📊", format = "percent"},
			{key = "TotalPlayTime", label = "Play Time", icon = "⏱️", format = "time"},
			{key = "BestDressed", label = "Best Dressed Awards", icon = "👑"},
		}
	},
	{
		name = "Designer",
		stats = {
			{key = "DesignerMatches", label = "Designer Matches", icon = "👔"},
			{key = "Escapes", label = "Successful Escapes", icon = "🚪"},
			{key = "StationsRepaired", label = "Stations Repaired", icon = "🔧"},
			{key = "SkillChecksHit", label = "Skill Checks Hit", icon = "✓"},
			{key = "PerfectSkillChecks", label = "Perfect Skill Checks", icon = "⭐"},
			{key = "TeammatesRescued", label = "Teammates Rescued", icon = "🤝"},
		}
	},
	{
		name = "Saboteur",
		stats = {
			{key = "SaboteurMatches", label = "Saboteur Matches", icon = "✂️"},
			{key = "Eliminations", label = "Designers Eliminated", icon = "💀"},
			{key = "DesignersDowned", label = "Designers Downed", icon = "⬇️"},
			{key = "StationsKicked", label = "Stations Sabotaged", icon = "🦵"},
			{key = "Wipeouts", label = "Total Wipeouts", icon = "🔥"},
		}
	},
}

function ProfileController.CreateProfileGui()
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "ProfileGui"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.IgnoreGuiInset = true
	screenGui.DisplayOrder = 50
	screenGui.Enabled = false

	-- Dimmed background
	local dimBackground = Instance.new("TextButton")
	dimBackground.Name = "DimBackground"
	dimBackground.Size = UDim2.new(1, 0, 1, 0)
	dimBackground.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	dimBackground.BackgroundTransparency = 0.5
	dimBackground.BorderSizePixel = 0
	dimBackground.Text = ""
	dimBackground.AutoButtonColor = false
	dimBackground.Parent = screenGui

	dimBackground.MouseButton1Click:Connect(function()
		ProfileController.Close()
	end)

	-- Main panel
	local panel = Instance.new("Frame")
	panel.Name = "ProfilePanel"
	panel.Size = UDim2.new(0, 700, 0, 550)
	panel.Position = UDim2.new(0.5, 0, 0.5, 0)
	panel.AnchorPoint = Vector2.new(0.5, 0.5)
	panel.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
	panel.BorderSizePixel = 0
	panel.Parent = screenGui

	local panelCorner = Instance.new("UICorner")
	panelCorner.CornerRadius = UDim.new(0, 16)
	panelCorner.Parent = panel

	local panelStroke = Instance.new("UIStroke")
	panelStroke.Thickness = 2
	panelStroke.Color = Color3.fromRGB(60, 60, 65)
	panelStroke.Parent = panel

	-- Header
	local header = Instance.new("Frame")
	header.Name = "Header"
	header.Size = UDim2.new(1, 0, 0, 120)
	header.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
	header.BorderSizePixel = 0
	header.Parent = panel

	local headerCorner = Instance.new("UICorner")
	headerCorner.CornerRadius = UDim.new(0, 16)
	headerCorner.Parent = header

	-- Fix bottom corners of header
	local headerFix = Instance.new("Frame")
	headerFix.Name = "HeaderFix"
	headerFix.Size = UDim2.new(1, 0, 0, 20)
	headerFix.Position = UDim2.new(0, 0, 1, -20)
	headerFix.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
	headerFix.BorderSizePixel = 0
	headerFix.Parent = header

	-- Avatar
	local avatarFrame = Instance.new("Frame")
	avatarFrame.Name = "AvatarFrame"
	avatarFrame.Size = UDim2.new(0, 80, 0, 80)
	avatarFrame.Position = UDim2.new(0, 20, 0.5, 0)
	avatarFrame.AnchorPoint = Vector2.new(0, 0.5)
	avatarFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
	avatarFrame.Parent = header

	local avatarCorner = Instance.new("UICorner")
	avatarCorner.CornerRadius = UDim.new(0, 12)
	avatarCorner.Parent = avatarFrame

	local avatar = Instance.new("ImageLabel")
	avatar.Name = "Avatar"
	avatar.Size = UDim2.new(1, -6, 1, -6)
	avatar.Position = UDim2.new(0, 3, 0, 3)
	avatar.BackgroundTransparency = 1
	avatar.Image = Players:GetUserThumbnailAsync(
		LocalPlayer.UserId,
		Enum.ThumbnailType.HeadShot,
		Enum.ThumbnailSize.Size150x150
	)
	avatar.Parent = avatarFrame

	local avatarImgCorner = Instance.new("UICorner")
	avatarImgCorner.CornerRadius = UDim.new(0, 10)
	avatarImgCorner.Parent = avatar

	-- Player info
	local playerName = Instance.new("TextLabel")
	playerName.Name = "PlayerName"
	playerName.Size = UDim2.new(0, 300, 0, 30)
	playerName.Position = UDim2.new(0, 115, 0, 25)
	playerName.BackgroundTransparency = 1
	playerName.Text = LocalPlayer.DisplayName
	playerName.TextColor3 = Color3.fromRGB(255, 255, 255)
	playerName.TextSize = 24
	playerName.Font = Enum.Font.GothamBold
	playerName.TextXAlignment = Enum.TextXAlignment.Left
	playerName.Parent = header

	local playerLevel = Instance.new("TextLabel")
	playerLevel.Name = "PlayerLevel"
	playerLevel.Size = UDim2.new(0, 300, 0, 25)
	playerLevel.Position = UDim2.new(0, 115, 0, 55)
	playerLevel.BackgroundTransparency = 1
	playerLevel.Text = "Level 1"
	playerLevel.TextColor3 = Color3.fromRGB(255, 215, 0)
	playerLevel.TextSize = 18
	playerLevel.Font = Enum.Font.GothamBold
	playerLevel.TextXAlignment = Enum.TextXAlignment.Left
	playerLevel.Parent = header

	-- XP Progress bar
	local xpBarBg = Instance.new("Frame")
	xpBarBg.Name = "XPBarBg"
	xpBarBg.Size = UDim2.new(0, 250, 0, 8)
	xpBarBg.Position = UDim2.new(0, 115, 0, 85)
	xpBarBg.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
	xpBarBg.BorderSizePixel = 0
	xpBarBg.Parent = header

	local xpBarCorner = Instance.new("UICorner")
	xpBarCorner.CornerRadius = UDim.new(1, 0)
	xpBarCorner.Parent = xpBarBg

	local xpBarFill = Instance.new("Frame")
	xpBarFill.Name = "XPBarFill"
	xpBarFill.Size = UDim2.new(0, 0, 1, 0)
	xpBarFill.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
	xpBarFill.BorderSizePixel = 0
	xpBarFill.Parent = xpBarBg

	local xpFillCorner = Instance.new("UICorner")
	xpFillCorner.CornerRadius = UDim.new(1, 0)
	xpFillCorner.Parent = xpBarFill

	local xpText = Instance.new("TextLabel")
	xpText.Name = "XPText"
	xpText.Size = UDim2.new(0, 100, 0, 20)
	xpText.Position = UDim2.new(0, 370, 0, 79)
	xpText.BackgroundTransparency = 1
	xpText.Text = "0 / 1000 XP"
	xpText.TextColor3 = Color3.fromRGB(150, 150, 150)
	xpText.TextSize = 12
	xpText.Font = Enum.Font.Gotham
	xpText.TextXAlignment = Enum.TextXAlignment.Left
	xpText.Parent = header

	-- Close button
	local closeButton = Instance.new("TextButton")
	closeButton.Name = "CloseButton"
	closeButton.Size = UDim2.new(0, 40, 0, 40)
	closeButton.Position = UDim2.new(1, -15, 0, 15)
	closeButton.AnchorPoint = Vector2.new(1, 0)
	closeButton.BackgroundColor3 = Color3.fromRGB(60, 60, 65)
	closeButton.BorderSizePixel = 0
	closeButton.Text = "✕"
	closeButton.TextColor3 = Color3.fromRGB(200, 200, 200)
	closeButton.TextSize = 20
	closeButton.Font = Enum.Font.GothamBold
	closeButton.Parent = header

	local closeCorner = Instance.new("UICorner")
	closeCorner.CornerRadius = UDim.new(0, 8)
	closeCorner.Parent = closeButton

	closeButton.MouseButton1Click:Connect(function()
		ProfileController.Close()
	end)

	-- Tab container
	local tabContainer = Instance.new("Frame")
	tabContainer.Name = "TabContainer"
	tabContainer.Size = UDim2.new(1, -40, 0, 40)
	tabContainer.Position = UDim2.new(0, 20, 0, 130)
	tabContainer.BackgroundTransparency = 1
	tabContainer.Parent = panel

	local tabLayout = Instance.new("UIListLayout")
	tabLayout.FillDirection = Enum.FillDirection.Horizontal
	tabLayout.Padding = UDim.new(0, 10)
	tabLayout.Parent = tabContainer

	-- Create tabs
	for i, category in ipairs(STAT_CATEGORIES) do
		local tab = Instance.new("TextButton")
		tab.Name = category.name .. "Tab"
		tab.Size = UDim2.new(0, 100, 1, 0)
		tab.BackgroundColor3 = i == 1 and Color3.fromRGB(255, 215, 0) or Color3.fromRGB(50, 50, 55)
		tab.BorderSizePixel = 0
		tab.Text = category.name
		tab.TextColor3 = i == 1 and Color3.fromRGB(30, 30, 35) or Color3.fromRGB(180, 180, 180)
		tab.TextSize = 14
		tab.Font = Enum.Font.GothamBold
		tab.LayoutOrder = i
		tab.Parent = tabContainer

		local tabCorner = Instance.new("UICorner")
		tabCorner.CornerRadius = UDim.new(0, 8)
		tabCorner.Parent = tab

		tab.MouseButton1Click:Connect(function()
			ProfileController.SwitchTab(category.name)
		end)
	end

	-- Stats container
	local statsContainer = Instance.new("ScrollingFrame")
	statsContainer.Name = "StatsContainer"
	statsContainer.Size = UDim2.new(1, -40, 1, -200)
	statsContainer.Position = UDim2.new(0, 20, 0, 180)
	statsContainer.BackgroundTransparency = 1
	statsContainer.BorderSizePixel = 0
	statsContainer.ScrollBarThickness = 4
	statsContainer.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 105)
	statsContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
	statsContainer.Parent = panel

	local statsLayout = Instance.new("UIGridLayout")
	statsLayout.CellSize = UDim2.new(0.5, -10, 0, 70)
	statsLayout.CellPadding = UDim2.new(0, 15, 0, 15)
	statsLayout.SortOrder = Enum.SortOrder.LayoutOrder
	statsLayout.Parent = statsContainer

	return screenGui
end

function ProfileController.CreateStatCard(statData, value)
	local card = Instance.new("Frame")
	card.Name = statData.key .. "Card"
	card.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
	card.BorderSizePixel = 0

	local cardCorner = Instance.new("UICorner")
	cardCorner.CornerRadius = UDim.new(0, 10)
	cardCorner.Parent = card

	-- Icon
	local icon = Instance.new("TextLabel")
	icon.Name = "Icon"
	icon.Size = UDim2.new(0, 40, 0, 40)
	icon.Position = UDim2.new(0, 10, 0.5, 0)
	icon.AnchorPoint = Vector2.new(0, 0.5)
	icon.BackgroundTransparency = 1
	icon.Text = statData.icon
	icon.TextSize = 24
	icon.Parent = card

	-- Label
	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.Size = UDim2.new(1, -60, 0, 20)
	label.Position = UDim2.new(0, 55, 0, 12)
	label.BackgroundTransparency = 1
	label.Text = statData.label
	label.TextColor3 = Color3.fromRGB(150, 150, 150)
	label.TextSize = 12
	label.Font = Enum.Font.Gotham
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextTruncate = Enum.TextTruncate.AtEnd
	label.Parent = card

	-- Value
	local valueLabel = Instance.new("TextLabel")
	valueLabel.Name = "Value"
	valueLabel.Size = UDim2.new(1, -60, 0, 30)
	valueLabel.Position = UDim2.new(0, 55, 0, 32)
	valueLabel.BackgroundTransparency = 1
	valueLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	valueLabel.TextSize = 22
	valueLabel.Font = Enum.Font.GothamBold
	valueLabel.TextXAlignment = Enum.TextXAlignment.Left
	valueLabel.Parent = card

	-- Format value based on type
	local displayValue = value or 0
	if statData.format == "percent" then
		displayValue = string.format("%.1f%%", displayValue * 100)
	elseif statData.format == "time" then
		local hours = math.floor(displayValue / 3600)
		local minutes = math.floor((displayValue % 3600) / 60)
		displayValue = string.format("%dh %dm", hours, minutes)
	else
		displayValue = tostring(displayValue)
	end
	valueLabel.Text = displayValue

	return card
end

function ProfileController.SwitchTab(tabName)
	if not profileGui then return end

	local panel = profileGui:FindFirstChild("ProfilePanel")
	if not panel then return end

	-- Update tab appearances
	local tabContainer = panel:FindFirstChild("TabContainer")
	if tabContainer then
		for _, tab in ipairs(tabContainer:GetChildren()) do
			if tab:IsA("TextButton") then
				local isActive = tab.Name == tabName .. "Tab"
				TweenService:Create(tab, TweenInfo.new(0.2), {
					BackgroundColor3 = isActive and Color3.fromRGB(255, 215, 0) or Color3.fromRGB(50, 50, 55),
					TextColor3 = isActive and Color3.fromRGB(30, 30, 35) or Color3.fromRGB(180, 180, 180)
				}):Play()
			end
		end
	end

	-- Update stats display
	ProfileController.UpdateStats(tabName)
end

function ProfileController.UpdateStats(categoryName)
	if not profileGui then return end

	local panel = profileGui:FindFirstChild("ProfilePanel")
	if not panel then return end

	local statsContainer = panel:FindFirstChild("StatsContainer")
	if not statsContainer then return end

	-- Clear existing stats
	for _, child in ipairs(statsContainer:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end

	-- Find category
	local category = nil
	for _, cat in ipairs(STAT_CATEGORIES) do
		if cat.name == categoryName then
			category = cat
			break
		end
	end

	if not category then return end

	-- Create stat cards
	for i, statData in ipairs(category.stats) do
		local value = LocalPlayer:GetAttribute(statData.key) or 0
		local card = ProfileController.CreateStatCard(statData, value)
		card.LayoutOrder = i
		card.Parent = statsContainer
	end

	-- Update canvas size
	local layout = statsContainer:FindFirstChildOfClass("UIGridLayout")
	if layout then
		local rows = math.ceil(#category.stats / 2)
		statsContainer.CanvasSize = UDim2.new(0, 0, 0, rows * 85)
	end
end

function ProfileController.UpdateHeader(level, xp, xpRequired)
	if not profileGui then return end

	local panel = profileGui:FindFirstChild("ProfilePanel")
	if not panel then return end

	local header = panel:FindFirstChild("Header")
	if not header then return end

	-- Update level
	local levelLabel = header:FindFirstChild("PlayerLevel")
	if levelLabel then
		levelLabel.Text = "Level " .. level
	end

	-- Update XP bar
	local xpBarBg = header:FindFirstChild("XPBarBg")
	if xpBarBg then
		local xpBarFill = xpBarBg:FindFirstChild("XPBarFill")
		if xpBarFill then
			local progress = math.clamp(xp / xpRequired, 0, 1)
			TweenService:Create(xpBarFill, TweenInfo.new(0.3), {
				Size = UDim2.new(progress, 0, 1, 0)
			}):Play()
		end
	end

	-- Update XP text
	local xpText = header:FindFirstChild("XPText")
	if xpText then
		xpText.Text = string.format("%d / %d XP", xp, xpRequired)
	end
end

function ProfileController.Open()
	if isOpen then return end

	isOpen = true
	profileGui.Enabled = true

	-- Animate in
	local panel = profileGui:FindFirstChild("ProfilePanel")
	if panel then
		panel.Position = UDim2.new(0.5, 0, 0.55, 0)
		panel.BackgroundTransparency = 0.3

		TweenService:Create(panel, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Position = UDim2.new(0.5, 0, 0.5, 0),
			BackgroundTransparency = 0
		}):Play()
	end

	-- Request stats from server
	local profileEvent = Remotes:FindFirstChild("ProfileEvent")
	if profileEvent then
		profileEvent:FireServer("GetStats")
	end

	-- Show first tab
	ProfileController.SwitchTab("General")
end

function ProfileController.Close()
	if not isOpen then return end

	isOpen = false

	-- Animate out
	local panel = profileGui:FindFirstChild("ProfilePanel")
	if panel then
		TweenService:Create(panel, TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
			Position = UDim2.new(0.5, 0, 0.55, 0),
			BackgroundTransparency = 0.3
		}):Play()
	end

	task.wait(0.2)
	profileGui.Enabled = false
end

function ProfileController.Toggle()
	if isOpen then
		ProfileController.Close()
	else
		ProfileController.Open()
	end
end

function ProfileController.Init()
	profileGui = ProfileController.CreateProfileGui()
	profileGui.Parent = PlayerGui

	-- Listen for server events
	local profileEvent = Remotes:FindFirstChild("ProfileEvent")
	if profileEvent then
		profileEvent.OnClientEvent:Connect(function(action, data)
			if action == "Open" then
				ProfileController.Open()
			elseif action == "Stats" then
				-- Update player stats from server
				for key, value in pairs(data.stats or {}) do
					LocalPlayer:SetAttribute(key, value)
				end
				ProfileController.UpdateHeader(
					data.level or 1,
					data.xp or 0,
					data.xpRequired or 1000
				)
				-- Refresh current tab
				ProfileController.SwitchTab("General")
			end
		end)
	end

	-- Keyboard shortcut
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end

		if input.KeyCode == Enum.KeyCode.P then
			ProfileController.Toggle()
		elseif input.KeyCode == Enum.KeyCode.Escape and isOpen then
			ProfileController.Close()
		end
	end)

	print("[ProfileController] Initialized")
end

-- Auto-initialize
ProfileController.Init()

return ProfileController
