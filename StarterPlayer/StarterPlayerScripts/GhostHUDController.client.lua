--[[
    GhostHUDController (LocalScript)
    Path: StarterPlayer → StarterPlayerScripts
    Parent: StarterPlayerScripts
    Properties:
        Disabled: false
    Exported: 2026-01-02 14:59:28
]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local camera = workspace.CurrentCamera

-- EVENTS
local Events = ReplicatedStorage:WaitForChild("Events")
local GhostActionEvent = Events:WaitForChild("GhostAction")

-- STATE
local isDead = false
local hud = nil

-- COLORS
local COLORS = {
	GhostBlue = Color3.fromRGB(150, 255, 255),
	Dark = Color3.fromRGB(20, 25, 30),
	Gold = Color3.fromRGB(255, 215, 0)
}

print("👻 Ghost Controller Loaded (Free-Roam Mode).")

-- 🛠️ UI BUILDER
local function CreateGhostHUD()
	if hud then hud:Destroy() end

	local screen = Instance.new("ScreenGui")
	screen.Name = "GhostHUD"
	screen.IgnoreGuiInset = true
	screen.ResetOnSpawn = false
	screen.DisplayOrder = 50
	screen.Parent = playerGui
	hud = screen

	-- 1. HEADER
	local header = Instance.new("Frame", screen)
	header.Size = UDim2.new(1, 0, 0.15, 0)
	header.BackgroundTransparency = 1

	local title = Instance.new("TextLabel", header)
	title.Text = "YOU ARE A GHOST"
	title.Font = Enum.Font.GothamBlack
	title.TextSize = 24
	title.TextColor3 = COLORS.GhostBlue
	title.Size = UDim2.new(1, 0, 0.5, 0)
	title.Position = UDim2.new(0, 0, 0.2, 0)
	title.BackgroundTransparency = 1

	local sub = Instance.new("TextLabel", header)
	sub.Text = "FLY FREE. HAUNT THE HOUSE."
	sub.Font = Enum.Font.Gotham
	sub.TextSize = 14
	sub.TextColor3 = Color3.new(1,1,1)
	sub.Size = UDim2.new(1, 0, 0.3, 0)
	sub.Position = UDim2.new(0, 0, 0.6, 0)
	sub.BackgroundTransparency = 1

	-- 2. ABILITY BAR (Right Side)
	local abilityFrame = Instance.new("Frame", screen)
	abilityFrame.Size = UDim2.new(0.15, 0, 0.4, 0)
	abilityFrame.Position = UDim2.new(0.98, 0, 0.5, 0)
	abilityFrame.AnchorPoint = Vector2.new(1, 0.5)
	abilityFrame.BackgroundTransparency = 1

	local list = Instance.new("UIListLayout", abilityFrame)
	list.Padding = UDim.new(0.05, 0)
	list.HorizontalAlignment = Enum.HorizontalAlignment.Right
	list.VerticalAlignment = Enum.VerticalAlignment.Center

	-- Helper for Buttons
	local function CreateAbility(name, text, color, cooldown)
		local btn = Instance.new("TextButton", abilityFrame)
		btn.Name = name
		btn.Text = ""
		btn.Size = UDim2.new(1, 0, 0.2, 0)
		btn.BackgroundColor3 = COLORS.Dark
		btn.BackgroundTransparency = 0.3
		btn.AutoButtonColor = false
		local c = Instance.new("UICorner", btn) c.CornerRadius = UDim.new(0, 8)
		local s = Instance.new("UIStroke", btn) s.Color = color s.Thickness = 2

		local lbl = Instance.new("TextLabel", btn)
		lbl.Text = text
		lbl.Size = UDim2.new(1,0,1,0)
		lbl.BackgroundTransparency = 1
		lbl.TextColor3 = color
		lbl.Font = Enum.Font.GothamBold
		lbl.TextSize = 12
		lbl.TextWrapped = true

		-- Logic
		btn.MouseButton1Click:Connect(function()
			if btn:GetAttribute("Cooldown") then return end

			-- Visual Feedback
			btn.BackgroundColor3 = color
			lbl.TextColor3 = COLORS.Dark
			task.wait(0.1)
			btn.BackgroundColor3 = COLORS.Dark
			lbl.TextColor3 = color

			-- Fire Server
			GhostActionEvent:FireServer(name)

			-- Cooldown UI
			btn:SetAttribute("Cooldown", true)
			local oldText = text
			for i = cooldown, 1, -1 do
				lbl.Text = tostring(i)
				btn.BackgroundTransparency = 0.7
				s.Transparency = 0.7
				task.wait(1)
			end
			lbl.Text = oldText
			btn.BackgroundTransparency = 0.3
			s.Transparency = 0
			btn:SetAttribute("Cooldown", nil)
		end)

		return btn
	end

	CreateAbility("CleanUp", "HAUNT\n(-2% Chaos)", COLORS.GhostBlue, 15)
	CreateAbility("MuseFreeze", "MUSE FREEZE\n(STOP CHAOS)", COLORS.Gold, 60)
	-- CreateAbility("Whisper", "WHISPER\n(HINT)", COLORS.GhostBlue, 45) -- Add later
end

-- ☠️ DEATH LISTENER
player:GetAttributeChangedSignal("IsDead"):Connect(function()
	if player:GetAttribute("IsDead") then
		isDead = true
		task.wait(2) -- Wait for ragdoll/death cam to finish

		CreateGhostHUD()

		-- 🚨 CRITICAL: Ensure Camera is on OUR character so flight works
		if player.Character then
			local hum = player.Character:FindFirstChild("Humanoid")
			if hum then
				camera.CameraSubject = hum
				camera.CameraType = Enum.CameraType.Custom
			end
		end
	else
		isDead = false
		if hud then hud:Destroy() end

		-- Reset camera on respawn
		if player.Character then
			camera.CameraSubject = player.Character:FindFirstChild("Humanoid")
			camera.CameraType = Enum.CameraType.Custom
		end
	end
end)