--[[
    CutsceneManager (LocalScript)
    Path: StarterPlayer → StarterPlayerScripts
    Parent: StarterPlayerScripts
    Properties:
        Disabled: false
    Exported: 2026-01-02 14:59:28
]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local SoundService = game:GetService("SoundService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local playerGui = player:WaitForChild("PlayerGui")

-- EVENTS
local Events = ReplicatedStorage:WaitForChild("Events")
local EjectionReveal = Events:WaitForChild("EjectionReveal")

-- ASSETS
-- ✂️ THE SNIP: A sharp scissor cutting sound
local CUT_SOUND = "rbxassetid://9119765666" 

-- CONFIG
local FADE_HOLD_TIME = 2.5 -- How long the screen stays black (Cover the respawn)

-- 🎬 THE CUTSCENE
EjectionReveal.OnClientEvent:Connect(function(victim)
	if not victim or not victim.Character then return end

	local char = victim.Character
	local head = char:FindFirstChild("Head")
	if not head then return end

	-- 1. DRAMATIC UI (Letterbox)
	local screen = Instance.new("ScreenGui", playerGui)
	screen.Name = "TheCutUI"
	screen.IgnoreGuiInset = true
	screen.DisplayOrder = 1000 -- Topmost

	-- Blackout Curtain (Start Invisible)
	local curtain = Instance.new("Frame", screen)
	curtain.Name = "Curtain"
	curtain.Size = UDim2.new(1, 0, 1, 0)
	curtain.BackgroundColor3 = Color3.new(0, 0, 0)
	curtain.BackgroundTransparency = 1
	curtain.ZIndex = 10

	-- Letterbox Bars
	local topBar = Instance.new("Frame", screen)
	topBar.Size = UDim2.new(1, 0, 0, 0)
	topBar.BackgroundColor3 = Color3.new(0,0,0)
	topBar.BorderSizePixel = 0

	local botBar = Instance.new("Frame", screen)
	botBar.Size = UDim2.new(1, 0, 0, 0)
	botBar.Position = UDim2.new(0, 0, 1, 0)
	botBar.AnchorPoint = Vector2.new(0, 1)
	botBar.BackgroundColor3 = Color3.new(0,0,0)
	botBar.BorderSizePixel = 0

	-- Animate Bars In
	TweenService:Create(topBar, TweenInfo.new(0.5, Enum.EasingStyle.Quad), {Size = UDim2.new(1, 0, 0.15, 0)}):Play()
	TweenService:Create(botBar, TweenInfo.new(0.5, Enum.EasingStyle.Quad), {Size = UDim2.new(1, 0, 0.15, 0)}):Play()

	-- 2. CAMERA ZOOM
	camera.CameraType = Enum.CameraType.Scriptable

	-- Start: Wide shot looking at victim
	local startCF = CFrame.new(head.Position + (head.CFrame.LookVector * 8) + Vector3.new(0, 2, 0), head.Position)
	-- End: Tight zoom on face (The "Oh no" moment)
	local endCF = CFrame.new(head.Position + (head.CFrame.LookVector * 3) + Vector3.new(0, 0.5, 0), head.Position)

	camera.CFrame = startCF

	-- Dramatic Push In
	TweenService:Create(camera, TweenInfo.new(3, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {
		CFrame = endCF
	}):Play()

	-- 3. SUSPENSE... THEN THE CUT
	task.wait(1.5) -- Build tension

	-- 🔊 PLAY SCISSOR SOUND
	local sfx = Instance.new("Sound", SoundService)
	sfx.SoundId = CUT_SOUND
	sfx.Volume = 2
	sfx:Play()
	game.Debris:AddItem(sfx, 3)

	-- 📝 TEXT REVEAL
	local label = Instance.new("TextLabel", screen)
	label.Size = UDim2.new(1, 0, 0.2, 0)
	label.Position = UDim2.new(0, 0, 0.8, 0) -- On bottom bar
	label.BackgroundTransparency = 1
	label.Text = "YOU HAVE BEEN CUT."
	label.Font = Enum.Font.GothamBlack
	label.TextSize = 40
	label.TextColor3 = Color3.fromRGB(255, 50, 50) -- Red
	label.TextTransparency = 1

	-- Flash the text
	TweenService:Create(label, TweenInfo.new(0.1), {TextTransparency = 0}):Play()

	-- 4. FADE TO BLACK (Hide the Glitch)
	task.wait(2) -- Read text for 2 seconds

	-- Fade Out World
	TweenService:Create(curtain, TweenInfo.new(0.5), {BackgroundTransparency = 0}):Play()

	-- 5. WAIT FOR RESPAWN/RESET
	task.wait(0.5 + FADE_HOLD_TIME) 

	-- 6. FADE BACK IN
	-- Camera reset usually happens by GameLoop logic here, so we just fade in the UI
	TweenService:Create(curtain, TweenInfo.new(1), {BackgroundTransparency = 1}):Play()

	task.wait(1)
	screen:Destroy()

	-- Failsafe Camera Reset (in case GameLoop didn't catch it)
	-- camera.CameraType = Enum.CameraType.Custom 
end)