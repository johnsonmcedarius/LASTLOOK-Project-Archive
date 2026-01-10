--[[
	TutorialController.lua
	Client-side tutorial/onboarding system
	Guides new players through game mechanics
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- Remote events
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local TutorialController = {}
TutorialController.__index = TutorialController

local tutorialGui = nil
local currentStep = 0
local isActive = false
local hasCompletedTutorial = false

-- Tutorial steps
local TUTORIAL_STEPS = {
	-- Welcome
	{
		title = "WELCOME TO LAST LOOK",
		description = "The Haunted Atelier awaits. In this asymmetrical survival game, Designers must work together to escape while the Saboteur hunts them down.",
		image = nil,
		highlight = nil,
		action = "continue",
	},
	-- Roles explanation
	{
		title = "TWO SIDES",
		description = "Each match, players are assigned as either DESIGNERS (survivors) or SABOTEURS (hunters). Work together or hunt alone!",
		image = nil,
		highlight = nil,
		action = "continue",
	},
	-- Designer role
	{
		title = "PLAYING AS DESIGNER",
		description = "As a Designer, your goal is to repair stations and power the exit gates. Complete skill checks to make progress!",
		image = nil,
		highlight = "StationMarker",
		action = "continue",
	},
	-- Skill checks
	{
		title = "SKILL CHECKS",
		description = "When repairing, watch for skill checks! Press the button when the needle is in the highlighted zone. Perfect timing gives bonus progress!",
		image = nil,
		highlight = nil,
		action = "practice_skillcheck",
	},
	-- Health states
	{
		title = "HEALTH STATES",
		description = "Designers have multiple health states: HEALTHY → INJURED → DOWNED → HOOKED. Help your teammates before it's too late!",
		image = nil,
		highlight = nil,
		action = "continue",
	},
	-- Rescue
	{
		title = "RESCUING TEAMMATES",
		description = "Downed teammates are placed on mannequin stands. Approach and hold the rescue button to save them before they're scrapped!",
		image = nil,
		highlight = nil,
		action = "continue",
	},
	-- Escape
	{
		title = "ESCAPE TO WIN",
		description = "Once enough stations are powered, the exit gates can be opened. Reach the exit to escape and earn bonus rewards!",
		image = nil,
		highlight = nil,
		action = "continue",
	},
	-- Saboteur role
	{
		title = "PLAYING AS SABOTEUR",
		description = "As a Saboteur, your goal is to eliminate all Designers before they escape. Use your Shears to attack!",
		image = nil,
		highlight = nil,
		action = "continue",
	},
	-- Terror radius
	{
		title = "TERROR RADIUS",
		description = "Designers can sense your presence through the Terror Radius. The closer you are, the more the world distorts around them!",
		image = nil,
		highlight = nil,
		action = "continue",
	},
	-- Perks
	{
		title = "PERKS & ABILITIES",
		description = "Unlock and equip perks in the Wardrobe to gain unique advantages. Each role has different perks available!",
		image = nil,
		highlight = nil,
		action = "continue",
	},
	-- Shop
	{
		title = "BOUTIQUE & COSMETICS",
		description = "Earn Spools from matches to purchase cosmetics. Complete challenges and level up to earn Influence for perks!",
		image = nil,
		highlight = nil,
		action = "continue",
	},
	-- Completion
	{
		title = "YOU'RE READY!",
		description = "That's everything you need to know! Good luck in the Atelier. Remember: In fashion, only the BEST survive.",
		image = nil,
		highlight = nil,
		action = "complete",
	},
}

function TutorialController.CreateTutorialGui()
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "TutorialGui"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.IgnoreGuiInset = true
	screenGui.DisplayOrder = 100
	screenGui.Enabled = false

	-- Dimmed background
	local dimBackground = Instance.new("Frame")
	dimBackground.Name = "DimBackground"
	dimBackground.Size = UDim2.new(1, 0, 1, 0)
	dimBackground.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	dimBackground.BackgroundTransparency = 0.6
	dimBackground.BorderSizePixel = 0
	dimBackground.Parent = screenGui

	-- Tutorial panel
	local panel = Instance.new("Frame")
	panel.Name = "TutorialPanel"
	panel.Size = UDim2.new(0, 500, 0, 350)
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
	panelStroke.Color = Color3.fromRGB(255, 215, 0)
	panelStroke.Parent = panel

	-- Step indicator
	local stepIndicator = Instance.new("Frame")
	stepIndicator.Name = "StepIndicator"
	stepIndicator.Size = UDim2.new(0, 200, 0, 10)
	stepIndicator.Position = UDim2.new(0.5, 0, 0, 20)
	stepIndicator.AnchorPoint = Vector2.new(0.5, 0)
	stepIndicator.BackgroundTransparency = 1
	stepIndicator.Parent = panel

	local stepLayout = Instance.new("UIListLayout")
	stepLayout.FillDirection = Enum.FillDirection.Horizontal
	stepLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	stepLayout.Padding = UDim.new(0, 6)
	stepLayout.Parent = stepIndicator

	-- Create step dots
	for i = 1, #TUTORIAL_STEPS do
		local dot = Instance.new("Frame")
		dot.Name = "Step" .. i
		dot.Size = UDim2.new(0, 8, 0, 8)
		dot.BackgroundColor3 = Color3.fromRGB(80, 80, 85)
		dot.BorderSizePixel = 0
		dot.Parent = stepIndicator

		local dotCorner = Instance.new("UICorner")
		dotCorner.CornerRadius = UDim.new(1, 0)
		dotCorner.Parent = dot
	end

	-- Title
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, -40, 0, 40)
	title.Position = UDim2.new(0, 20, 0, 50)
	title.BackgroundTransparency = 1
	title.Text = "TUTORIAL"
	title.TextColor3 = Color3.fromRGB(255, 215, 0)
	title.TextSize = 28
	title.Font = Enum.Font.GothamBlack
	title.TextXAlignment = Enum.TextXAlignment.Center
	title.Parent = panel

	-- Description
	local description = Instance.new("TextLabel")
	description.Name = "Description"
	description.Size = UDim2.new(1, -60, 0, 120)
	description.Position = UDim2.new(0, 30, 0, 110)
	description.BackgroundTransparency = 1
	description.Text = ""
	description.TextColor3 = Color3.fromRGB(220, 220, 220)
	description.TextSize = 18
	description.Font = Enum.Font.Gotham
	description.TextWrapped = true
	description.TextYAlignment = Enum.TextYAlignment.Top
	description.Parent = panel

	-- Image container (for visual aids)
	local imageContainer = Instance.new("Frame")
	imageContainer.Name = "ImageContainer"
	imageContainer.Size = UDim2.new(0, 200, 0, 100)
	imageContainer.Position = UDim2.new(0.5, 0, 0, 240)
	imageContainer.AnchorPoint = Vector2.new(0.5, 0)
	imageContainer.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
	imageContainer.BackgroundTransparency = 1
	imageContainer.BorderSizePixel = 0
	imageContainer.Parent = panel

	-- Button container
	local buttonContainer = Instance.new("Frame")
	buttonContainer.Name = "ButtonContainer"
	buttonContainer.Size = UDim2.new(1, -40, 0, 50)
	buttonContainer.Position = UDim2.new(0, 20, 1, -20)
	buttonContainer.AnchorPoint = Vector2.new(0, 1)
	buttonContainer.BackgroundTransparency = 1
	buttonContainer.Parent = panel

	local buttonLayout = Instance.new("UIListLayout")
	buttonLayout.FillDirection = Enum.FillDirection.Horizontal
	buttonLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	buttonLayout.Padding = UDim.new(0, 15)
	buttonLayout.Parent = buttonContainer

	-- Skip button
	local skipButton = Instance.new("TextButton")
	skipButton.Name = "SkipButton"
	skipButton.Size = UDim2.new(0, 120, 0, 45)
	skipButton.BackgroundColor3 = Color3.fromRGB(80, 80, 85)
	skipButton.BorderSizePixel = 0
	skipButton.Text = "SKIP"
	skipButton.TextColor3 = Color3.fromRGB(200, 200, 200)
	skipButton.TextSize = 16
	skipButton.Font = Enum.Font.GothamBold
	skipButton.LayoutOrder = 1
	skipButton.Parent = buttonContainer

	local skipCorner = Instance.new("UICorner")
	skipCorner.CornerRadius = UDim.new(0, 8)
	skipCorner.Parent = skipButton

	-- Continue button
	local continueButton = Instance.new("TextButton")
	continueButton.Name = "ContinueButton"
	continueButton.Size = UDim2.new(0, 180, 0, 45)
	continueButton.BackgroundColor3 = Color3.fromRGB(76, 175, 80)
	continueButton.BorderSizePixel = 0
	continueButton.Text = "CONTINUE →"
	continueButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	continueButton.TextSize = 16
	continueButton.Font = Enum.Font.GothamBold
	continueButton.LayoutOrder = 2
	continueButton.Parent = buttonContainer

	local continueCorner = Instance.new("UICorner")
	continueCorner.CornerRadius = UDim.new(0, 8)
	continueCorner.Parent = continueButton

	-- Button events
	skipButton.MouseButton1Click:Connect(function()
		TutorialController.Skip()
	end)

	continueButton.MouseButton1Click:Connect(function()
		TutorialController.NextStep()
	end)

	-- Hover effects
	for _, btn in ipairs({skipButton, continueButton}) do
		btn.MouseEnter:Connect(function()
			TweenService:Create(btn, TweenInfo.new(0.15), {
				Size = UDim2.new(0, btn.Size.X.Offset + 10, 0, btn.Size.Y.Offset + 5)
			}):Play()
		end)
		btn.MouseLeave:Connect(function()
			local originalWidth = btn.Name == "SkipButton" and 120 or 180
			TweenService:Create(btn, TweenInfo.new(0.15), {
				Size = UDim2.new(0, originalWidth, 0, 45)
			}):Play()
		end)
	end

	return screenGui
end

function TutorialController.UpdateStep(stepIndex)
	if not tutorialGui then return end
	if stepIndex < 1 or stepIndex > #TUTORIAL_STEPS then return end

	currentStep = stepIndex
	local step = TUTORIAL_STEPS[stepIndex]

	local panel = tutorialGui:FindFirstChild("TutorialPanel")
	if not panel then return end

	-- Update title and description
	local title = panel:FindFirstChild("Title")
	local description = panel:FindFirstChild("Description")

	if title then
		title.Text = step.title
	end

	if description then
		-- Fade out, change text, fade in
		TweenService:Create(description, TweenInfo.new(0.15), {TextTransparency = 1}):Play()
		task.wait(0.15)
		description.Text = step.description
		TweenService:Create(description, TweenInfo.new(0.15), {TextTransparency = 0}):Play()
	end

	-- Update step indicators
	local stepIndicator = panel:FindFirstChild("StepIndicator")
	if stepIndicator then
		for i = 1, #TUTORIAL_STEPS do
			local dot = stepIndicator:FindFirstChild("Step" .. i)
			if dot then
				if i < stepIndex then
					dot.BackgroundColor3 = Color3.fromRGB(76, 175, 80) -- Completed
				elseif i == stepIndex then
					dot.BackgroundColor3 = Color3.fromRGB(255, 215, 0) -- Current
					-- Pulse animation
					TweenService:Create(dot, TweenInfo.new(0.3), {Size = UDim2.new(0, 12, 0, 12)}):Play()
				else
					dot.BackgroundColor3 = Color3.fromRGB(80, 80, 85) -- Upcoming
					dot.Size = UDim2.new(0, 8, 0, 8)
				end
			end
		end
	end

	-- Update continue button text
	local buttonContainer = panel:FindFirstChild("ButtonContainer")
	if buttonContainer then
		local continueButton = buttonContainer:FindFirstChild("ContinueButton")
		if continueButton then
			if step.action == "complete" then
				continueButton.Text = "START PLAYING!"
				continueButton.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
			elseif step.action == "practice_skillcheck" then
				continueButton.Text = "TRY IT →"
			else
				continueButton.Text = "CONTINUE →"
				continueButton.BackgroundColor3 = Color3.fromRGB(76, 175, 80)
			end
		end
	end
end

function TutorialController.NextStep()
	local step = TUTORIAL_STEPS[currentStep]

	if step.action == "complete" then
		TutorialController.Complete()
		return
	end

	if step.action == "practice_skillcheck" then
		-- Trigger practice skill check
		TutorialController.ShowPracticeSkillCheck()
		return
	end

	if currentStep < #TUTORIAL_STEPS then
		TutorialController.UpdateStep(currentStep + 1)
	end
end

function TutorialController.PreviousStep()
	if currentStep > 1 then
		TutorialController.UpdateStep(currentStep - 1)
	end
end

function TutorialController.ShowPracticeSkillCheck()
	-- For now, just continue to next step
	-- In full implementation, this would trigger a practice skill check UI
	if currentStep < #TUTORIAL_STEPS then
		TutorialController.UpdateStep(currentStep + 1)
	end
end

function TutorialController.Start()
	if isActive then return end
	if hasCompletedTutorial then return end

	isActive = true
	tutorialGui.Enabled = true

	-- Animate in
	local panel = tutorialGui:FindFirstChild("TutorialPanel")
	if panel then
		panel.Position = UDim2.new(0.5, 0, 0.6, 0)
		panel.BackgroundTransparency = 1

		TweenService:Create(panel, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Position = UDim2.new(0.5, 0, 0.5, 0),
			BackgroundTransparency = 0
		}):Play()
	end

	TutorialController.UpdateStep(1)
end

function TutorialController.Skip()
	TutorialController.Complete()
end

function TutorialController.Complete()
	isActive = false
	hasCompletedTutorial = true

	-- Save completion to server
	local tutorialEvent = Remotes:FindFirstChild("TutorialEvent")
	if tutorialEvent then
		tutorialEvent:FireServer("Complete")
	end

	-- Animate out
	if tutorialGui then
		local panel = tutorialGui:FindFirstChild("TutorialPanel")
		if panel then
			TweenService:Create(panel, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
				Position = UDim2.new(0.5, 0, 0.4, 0),
				BackgroundTransparency = 1
			}):Play()
		end

		local dimBackground = tutorialGui:FindFirstChild("DimBackground")
		if dimBackground then
			TweenService:Create(dimBackground, TweenInfo.new(0.3), {BackgroundTransparency = 1}):Play()
		end

		task.wait(0.35)
		tutorialGui.Enabled = false
	end

	print("[TutorialController] Tutorial completed")
end

function TutorialController.Init()
	tutorialGui = TutorialController.CreateTutorialGui()
	tutorialGui.Parent = PlayerGui

	-- Check if player has completed tutorial
	local tutorialEvent = Remotes:FindFirstChild("TutorialEvent")
	if tutorialEvent then
		tutorialEvent.OnClientEvent:Connect(function(action, data)
			if action == "Show" then
				TutorialController.Start()
			elseif action == "Status" then
				hasCompletedTutorial = data.completed or false
				if not hasCompletedTutorial then
					-- Auto-start tutorial for new players after loading
					task.wait(3)
					TutorialController.Start()
				end
			end
		end)

		-- Request tutorial status
		tutorialEvent:FireServer("GetStatus")
	end

	-- Keyboard shortcuts
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end
		if not isActive then return end

		if input.KeyCode == Enum.KeyCode.Return or input.KeyCode == Enum.KeyCode.Space then
			TutorialController.NextStep()
		elseif input.KeyCode == Enum.KeyCode.Escape then
			TutorialController.Skip()
		end
	end)

	print("[TutorialController] Initialized")
end

-- Auto-initialize
TutorialController.Init()

return TutorialController
