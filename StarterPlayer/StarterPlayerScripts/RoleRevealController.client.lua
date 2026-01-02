--[[
    RoleRevealController (LocalScript)
    Path: StarterPlayer → StarterPlayerScripts
    Parent: StarterPlayerScripts
    Properties:
        Disabled: false
    Exported: 2026-01-02 14:59:28
]]
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ASSETS
local SOUND_REVEAL = "rbxassetid://6042053626" 

local function PlayReveal(role)
	if not role then return end

	local screen = Instance.new("ScreenGui", playerGui)
	screen.Name = "RoleReveal"
	screen.IgnoreGuiInset = true
	screen.DisplayOrder = 200 -- Topmost

	-- Blackout BG
	local bg = Instance.new("Frame", screen)
	bg.Size = UDim2.new(1, 0, 1, 0)
	bg.BackgroundColor3 = Color3.new(0,0,0)
	bg.BackgroundTransparency = 0

	-- Text
	local label = Instance.new("TextLabel", screen)
	label.Size = UDim2.new(1, 0, 0.2, 0)
	label.Position = UDim2.new(0, 0, 0.4, 0)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBlack
	label.TextSize = 60
	label.TextTransparency = 1

	local sub = Instance.new("TextLabel", screen)
	sub.Size = UDim2.new(1, 0, 0.1, 0)
	sub.Position = UDim2.new(0, 0, 0.55, 0)
	sub.BackgroundTransparency = 1
	sub.Font = Enum.Font.Gotham
	sub.TextSize = 24
	sub.TextTransparency = 1
	sub.TextColor3 = Color3.new(1,1,1)

	-- 🚨 ROLE LOGIC (FIXED)
	if role == "Saboteur" then
		label.Text = "SABOTEUR"
		label.TextColor3 = Color3.fromRGB(255, 50, 50)
		sub.Text = "DESTROY THE COLLECTION. DON'T GET CAUGHT."

	elseif role == "Ghost" then
		label.Text = "GHOST"
		label.TextColor3 = Color3.fromRGB(150, 255, 255) -- Ghost Blue
		sub.Text = "HAUNT THE HOUSE. ASSIST FROM BEYOND."

	else -- Designer (Default)
		label.Text = "DESIGNER"
		label.TextColor3 = Color3.fromRGB(0, 255, 150)
		sub.Text = "FINISH TASKS. SURVIVE THE CHAOS."
	end

	-- ANIMATION
	local sfx = Instance.new("Sound", SoundService)
	sfx.SoundId = SOUND_REVEAL
	sfx:Play()
	game.Debris:AddItem(sfx, 3)

	-- Fade In BG
	TweenService:Create(bg, TweenInfo.new(0.5), {BackgroundTransparency = 0.2}):Play()

	-- Slam Text In
	label.Position = UDim2.new(0, 0, 0.3, 0)
	TweenService:Create(label, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		TextTransparency = 0,
		Position = UDim2.new(0, 0, 0.4, 0)
	}):Play()

	task.wait(0.3)
	TweenService:Create(sub, TweenInfo.new(0.5), {TextTransparency = 0}):Play()

	-- Hold
	task.wait(3)

	-- Fade Out
	TweenService:Create(bg, TweenInfo.new(1), {BackgroundTransparency = 1}):Play()
	TweenService:Create(label, TweenInfo.new(0.5), {TextTransparency = 1, Position = UDim2.new(0,0,0.3,0)}):Play()
	TweenService:Create(sub, TweenInfo.new(0.5), {TextTransparency = 1}):Play()

	task.wait(1)
	screen:Destroy()
end

-- LISTEN
player:GetAttributeChangedSignal("Role"):Connect(function()
	local role = player:GetAttribute("Role")
	if role then
		PlayReveal(role)
	end
end)