--[[
    CutsceneManager (LocalScript)
    Path: StarterPlayer → StarterPlayerScripts
    Parent: StarterPlayerScripts
    Properties:
        Disabled: false
    Exported: 2026-01-02 03:27:27
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
local STING_SOUND = "rbxassetid://9125900898" -- Dramatic Vine Boom or similar

-- 🎬 THE CUTSCENE
EjectionReveal.OnClientEvent:Connect(function(victim)
	if not victim or not victim.Character then return end

	local char = victim.Character
	local head = char:FindFirstChild("Head")
	if not head then return end

	-- 1. DRAMATIC UI
	local screen = Instance.new("ScreenGui", playerGui)
	screen.Name = "TheCutUI"
	screen.IgnoreGuiInset = true

	-- Letterbox Bars (Cinema feel)
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

	-- Animate Bars
	TweenService:Create(topBar, TweenInfo.new(0.5), {Size = UDim2.new(1, 0, 0.15, 0)}):Play()
	TweenService:Create(botBar, TweenInfo.new(0.5), {Size = UDim2.new(1, 0, 0.15, 0)}):Play()

	-- 2. CAMERA ZOOM
	camera.CameraType = Enum.CameraType.Scriptable

	-- Start: Wide shot looking at victim
	local startCF = CFrame.new(head.Position + (head.CFrame.LookVector * 8) + Vector3.new(0, 2, 0), head.Position)
	-- End: Tight zoom on face
	local endCF = CFrame.new(head.Position + (head.CFrame.LookVector * 3) + Vector3.new(0, 0.5, 0), head.Position)

	camera.CFrame = startCF

	-- Play Sound
	local sfx = Instance.new("Sound", SoundService)
	sfx.SoundId = STING_SOUND
	sfx.Volume = 2
	sfx:Play()
	game.Debris:AddItem(sfx, 3)

	-- Tween Camera (Slow dramatic push)
	TweenService:Create(camera, TweenInfo.new(3, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {
		CFrame = endCF
	}):Play()

	-- 3. TEXT REVEAL
	local label = Instance.new("TextLabel", screen)
	label.Size = UDim2.new(1, 0, 0.2, 0)
	label.Position = UDim2.new(0, 0, 0.8, 0) -- On bottom bar
	label.BackgroundTransparency = 1
	label.Text = string.upper(victim.Name) .. "..."
	label.Font = Enum.Font.GothamBlack
	label.TextSize = 40
	label.TextColor3 = Color3.fromRGB(255, 50, 50)
	label.TextTransparency = 1

	task.wait(1)
	TweenService:Create(label, TweenInfo.new(0.5), {TextTransparency = 0}):Play()

	task.wait(1.5)
	label.Text = "YOU HAVE BEEN CUT."

	-- 4. CLEANUP (Handled by GameLoop resetting state, but we clean UI)
	task.wait(1.5)
	screen:Destroy()

	-- Camera reset is handled by GameLoop/VotingController returning to "Playing" state
	-- But as a failsafe:
	-- camera.CameraType = Enum.CameraType.Custom 
end)