--[[
	LoadingScreenController.lua
	Client-side loading screen with branding and progress
	Shows while game assets load
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContentProvider = game:GetService("ContentProvider")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local LoadingScreenController = {}
LoadingScreenController.__index = LoadingScreenController

local loadingGui = nil
local isLoading = true

-- Loading tips
local LOADING_TIPS = {
	"Designers must repair stations to power the exit gates",
	"Saboteurs use Shears to eliminate Designers",
	"Rescue your teammates from mannequin stands before they're scrapped",
	"Stay out of the Saboteur's terror radius to avoid detection",
	"Complete skill checks perfectly for bonus progress",
	"Equip perks to gain unique advantages in each match",
	"Daily logins grant bonus Spools and Influence",
	"The Best Dressed player earns extra rewards",
	"Wire matching tasks require connecting matching colors",
	"Anti-camp protection slows hook decay when Saboteurs linger",
	"Sprint to move faster, but be careful of your stamina",
	"Injured Designers leave blood trails for Saboteurs to follow",
	"Gates require full station power to open",
	"Spectate eliminated players while waiting for the next round",
	"Complete challenges for bonus rewards",
}

-- Assets to preload
local PRELOAD_ASSETS = {
	-- Add critical asset IDs here
	"rbxassetid://6031302931", -- Loading spinner
}

function LoadingScreenController.CreateLoadingScreen()
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "LoadingScreenGui"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.IgnoreGuiInset = true
	screenGui.DisplayOrder = 999 -- Always on top

	-- Background
	local background = Instance.new("Frame")
	background.Name = "Background"
	background.Size = UDim2.new(1, 0, 1, 0)
	background.BackgroundColor3 = Color3.fromRGB(10, 10, 15)
	background.BorderSizePixel = 0
	background.Parent = screenGui

	-- Animated gradient background
	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(20, 15, 30)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(10, 10, 15)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(15, 10, 25)),
	})
	gradient.Rotation = 0
	gradient.Parent = background

	-- Vignette effect
	local vignette = Instance.new("ImageLabel")
	vignette.Name = "Vignette"
	vignette.Size = UDim2.new(1, 0, 1, 0)
	vignette.BackgroundTransparency = 1
	vignette.Image = "rbxassetid://1526405635" -- Vignette
	vignette.ImageColor3 = Color3.fromRGB(0, 0, 0)
	vignette.ImageTransparency = 0.3
	vignette.Parent = background

	-- Logo
	local logoContainer = Instance.new("Frame")
	logoContainer.Name = "LogoContainer"
	logoContainer.Size = UDim2.new(0, 500, 0, 200)
	logoContainer.Position = UDim2.new(0.5, 0, 0.35, 0)
	logoContainer.AnchorPoint = Vector2.new(0.5, 0.5)
	logoContainer.BackgroundTransparency = 1
	logoContainer.Parent = screenGui

	local logoText = Instance.new("TextLabel")
	logoText.Name = "LogoText"
	logoText.Size = UDim2.new(1, 0, 0, 100)
	logoText.BackgroundTransparency = 1
	logoText.Text = "LAST LOOK"
	logoText.TextColor3 = Color3.fromRGB(255, 215, 0)
	logoText.TextSize = 80
	logoText.Font = Enum.Font.GothamBlack
	logoText.TextStrokeTransparency = 0.3
	logoText.TextStrokeColor3 = Color3.fromRGB(139, 69, 19)
	logoText.Parent = logoContainer

	local tagline = Instance.new("TextLabel")
	tagline.Name = "Tagline"
	tagline.Size = UDim2.new(1, 0, 0, 30)
	tagline.Position = UDim2.new(0, 0, 0, 110)
	tagline.BackgroundTransparency = 1
	tagline.Text = "THE HAUNTED ATELIER"
	tagline.TextColor3 = Color3.fromRGB(180, 180, 180)
	tagline.TextSize = 22
	tagline.Font = Enum.Font.Gotham
	tagline.Parent = logoContainer

	-- Loading bar container
	local loadingContainer = Instance.new("Frame")
	loadingContainer.Name = "LoadingContainer"
	loadingContainer.Size = UDim2.new(0, 400, 0, 8)
	loadingContainer.Position = UDim2.new(0.5, 0, 0.6, 0)
	loadingContainer.AnchorPoint = Vector2.new(0.5, 0.5)
	loadingContainer.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
	loadingContainer.BorderSizePixel = 0
	loadingContainer.Parent = screenGui

	local loadingCorner = Instance.new("UICorner")
	loadingCorner.CornerRadius = UDim.new(0, 4)
	loadingCorner.Parent = loadingContainer

	-- Loading bar fill
	local loadingFill = Instance.new("Frame")
	loadingFill.Name = "LoadingFill"
	loadingFill.Size = UDim2.new(0, 0, 1, 0)
	loadingFill.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
	loadingFill.BorderSizePixel = 0
	loadingFill.Parent = loadingContainer

	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(0, 4)
	fillCorner.Parent = loadingFill

	local fillGradient = Instance.new("UIGradient")
	fillGradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 215, 0)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 180, 0)),
	})
	fillGradient.Parent = loadingFill

	-- Loading percentage
	local loadingPercent = Instance.new("TextLabel")
	loadingPercent.Name = "LoadingPercent"
	loadingPercent.Size = UDim2.new(0, 100, 0, 25)
	loadingPercent.Position = UDim2.new(0.5, 0, 0.6, 25)
	loadingPercent.AnchorPoint = Vector2.new(0.5, 0)
	loadingPercent.BackgroundTransparency = 1
	loadingPercent.Text = "0%"
	loadingPercent.TextColor3 = Color3.fromRGB(200, 200, 200)
	loadingPercent.TextSize = 16
	loadingPercent.Font = Enum.Font.GothamBold
	loadingPercent.Parent = screenGui

	-- Loading status
	local loadingStatus = Instance.new("TextLabel")
	loadingStatus.Name = "LoadingStatus"
	loadingStatus.Size = UDim2.new(0, 400, 0, 25)
	loadingStatus.Position = UDim2.new(0.5, 0, 0.6, 50)
	loadingStatus.AnchorPoint = Vector2.new(0.5, 0)
	loadingStatus.BackgroundTransparency = 1
	loadingStatus.Text = "Loading assets..."
	loadingStatus.TextColor3 = Color3.fromRGB(150, 150, 150)
	loadingStatus.TextSize = 14
	loadingStatus.Font = Enum.Font.Gotham
	loadingStatus.Parent = screenGui

	-- Tips container
	local tipsContainer = Instance.new("Frame")
	tipsContainer.Name = "TipsContainer"
	tipsContainer.Size = UDim2.new(0, 600, 0, 60)
	tipsContainer.Position = UDim2.new(0.5, 0, 0.85, 0)
	tipsContainer.AnchorPoint = Vector2.new(0.5, 0.5)
	tipsContainer.BackgroundTransparency = 1
	tipsContainer.Parent = screenGui

	local tipIcon = Instance.new("TextLabel")
	tipIcon.Name = "TipIcon"
	tipIcon.Size = UDim2.new(0, 30, 0, 30)
	tipIcon.Position = UDim2.new(0, 0, 0, 0)
	tipIcon.BackgroundTransparency = 1
	tipIcon.Text = "💡"
	tipIcon.TextSize = 24
	tipIcon.Parent = tipsContainer

	local tipLabel = Instance.new("TextLabel")
	tipLabel.Name = "TipLabel"
	tipLabel.Size = UDim2.new(1, -40, 1, 0)
	tipLabel.Position = UDim2.new(0, 35, 0, 0)
	tipLabel.BackgroundTransparency = 1
	tipLabel.Text = LOADING_TIPS[1]
	tipLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
	tipLabel.TextSize = 16
	tipLabel.Font = Enum.Font.Gotham
	tipLabel.TextXAlignment = Enum.TextXAlignment.Left
	tipLabel.TextWrapped = true
	tipLabel.Parent = tipsContainer

	-- Copyright
	local copyright = Instance.new("TextLabel")
	copyright.Name = "Copyright"
	copyright.Size = UDim2.new(0, 300, 0, 20)
	copyright.Position = UDim2.new(0.5, 0, 1, -20)
	copyright.AnchorPoint = Vector2.new(0.5, 1)
	copyright.BackgroundTransparency = 1
	copyright.Text = "© 2024 LAST LOOK"
	copyright.TextColor3 = Color3.fromRGB(80, 80, 80)
	copyright.TextSize = 12
	copyright.Font = Enum.Font.Gotham
	copyright.Parent = screenGui

	return screenGui
end

function LoadingScreenController.UpdateProgress(percent, status)
	if not loadingGui then return end

	local loadingContainer = loadingGui:FindFirstChild("LoadingContainer")
	local loadingPercent = loadingGui:FindFirstChild("LoadingPercent")
	local loadingStatus = loadingGui:FindFirstChild("LoadingStatus")

	if loadingContainer then
		local fill = loadingContainer:FindFirstChild("LoadingFill")
		if fill then
			local tween = TweenService:Create(
				fill,
				TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
				{Size = UDim2.new(percent / 100, 0, 1, 0)}
			)
			tween:Play()
		end
	end

	if loadingPercent then
		loadingPercent.Text = string.format("%d%%", math.floor(percent))
	end

	if loadingStatus and status then
		loadingStatus.Text = status
	end
end

function LoadingScreenController.CycleTips()
	if not loadingGui then return end

	local tipsContainer = loadingGui:FindFirstChild("TipsContainer")
	if not tipsContainer then return end

	local tipLabel = tipsContainer:FindFirstChild("TipLabel")
	if not tipLabel then return end

	local currentIndex = 1

	while isLoading do
		-- Fade out
		local fadeOut = TweenService:Create(
			tipLabel,
			TweenInfo.new(0.3),
			{TextTransparency = 1}
		)
		fadeOut:Play()
		fadeOut.Completed:Wait()

		-- Change tip
		currentIndex = (currentIndex % #LOADING_TIPS) + 1
		tipLabel.Text = LOADING_TIPS[currentIndex]

		-- Fade in
		local fadeIn = TweenService:Create(
			tipLabel,
			TweenInfo.new(0.3),
			{TextTransparency = 0}
		)
		fadeIn:Play()
		fadeIn.Completed:Wait()

		-- Wait before next tip
		task.wait(4)
	end
end

function LoadingScreenController.AnimateGradient()
	if not loadingGui then return end

	local background = loadingGui:FindFirstChild("Background")
	if not background then return end

	local gradient = background:FindFirstChild("UIGradient")
	if not gradient then return end

	while isLoading do
		local tween = TweenService:Create(
			gradient,
			TweenInfo.new(3, Enum.EasingStyle.Linear),
			{Rotation = gradient.Rotation + 360}
		)
		tween:Play()
		tween.Completed:Wait()
	end
end

function LoadingScreenController.AnimateLogo()
	if not loadingGui then return end

	local logoContainer = loadingGui:FindFirstChild("LogoContainer")
	if not logoContainer then return end

	local logoText = logoContainer:FindFirstChild("LogoText")
	if not logoText then return end

	-- Subtle glow pulse
	while isLoading do
		local glowIn = TweenService:Create(
			logoText,
			TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
			{TextStrokeTransparency = 0.1}
		)
		glowIn:Play()
		glowIn.Completed:Wait()

		local glowOut = TweenService:Create(
			logoText,
			TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
			{TextStrokeTransparency = 0.5}
		)
		glowOut:Play()
		glowOut.Completed:Wait()
	end
end

function LoadingScreenController.PreloadAssets()
	local totalAssets = #PRELOAD_ASSETS + 50 -- Estimate for game assets
	local loadedAssets = 0

	-- Preload specified assets
	for i, assetId in ipairs(PRELOAD_ASSETS) do
		ContentProvider:PreloadAsync({assetId})
		loadedAssets = loadedAssets + 1
		LoadingScreenController.UpdateProgress(
			(loadedAssets / totalAssets) * 100,
			string.format("Loading assets (%d/%d)", loadedAssets, totalAssets)
		)
	end

	-- Preload game content
	LoadingScreenController.UpdateProgress(50, "Loading game world...")

	local gameContent = {}

	-- Collect game assets
	for _, descendant in ipairs(game:GetDescendants()) do
		if descendant:IsA("Sound") or descendant:IsA("Decal") or descendant:IsA("Texture") then
			table.insert(gameContent, descendant)
		end
	end

	-- Preload in batches
	local batchSize = 10
	for i = 1, #gameContent, batchSize do
		local batch = {}
		for j = i, math.min(i + batchSize - 1, #gameContent) do
			table.insert(batch, gameContent[j])
		end

		ContentProvider:PreloadAsync(batch)
		loadedAssets = loadedAssets + #batch

		local progress = math.min(50 + ((loadedAssets / (totalAssets + #gameContent)) * 50), 99)
		LoadingScreenController.UpdateProgress(
			progress,
			string.format("Loading game content... (%d%%)", math.floor(progress))
		)
	end

	-- Final loading stages
	LoadingScreenController.UpdateProgress(95, "Connecting to server...")
	task.wait(0.5)

	LoadingScreenController.UpdateProgress(98, "Preparing your session...")
	task.wait(0.3)

	LoadingScreenController.UpdateProgress(100, "Ready!")
	task.wait(0.5)
end

function LoadingScreenController.FadeOut()
	if not loadingGui then return end

	isLoading = false

	-- Fade out all elements
	for _, element in ipairs(loadingGui:GetDescendants()) do
		if element:IsA("TextLabel") or element:IsA("TextButton") then
			TweenService:Create(element, TweenInfo.new(0.5), {TextTransparency = 1}):Play()
		elseif element:IsA("ImageLabel") then
			TweenService:Create(element, TweenInfo.new(0.5), {ImageTransparency = 1}):Play()
		elseif element:IsA("Frame") then
			TweenService:Create(element, TweenInfo.new(0.5), {BackgroundTransparency = 1}):Play()
		end
	end

	task.wait(0.6)
	loadingGui:Destroy()
	loadingGui = nil
end

function LoadingScreenController.Init()
	loadingGui = LoadingScreenController.CreateLoadingScreen()
	loadingGui.Parent = PlayerGui

	-- Start animations
	task.spawn(LoadingScreenController.CycleTips)
	task.spawn(LoadingScreenController.AnimateGradient)
	task.spawn(LoadingScreenController.AnimateLogo)

	-- Start loading
	task.spawn(function()
		LoadingScreenController.PreloadAssets()
		LoadingScreenController.FadeOut()
	end)

	print("[LoadingScreenController] Initialized")
end

-- Auto-initialize
LoadingScreenController.Init()

return LoadingScreenController
