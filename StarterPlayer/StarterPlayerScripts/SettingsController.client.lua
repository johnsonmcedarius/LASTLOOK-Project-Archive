--[[
    SettingsController (LocalScript)
    Path: StarterPlayer → StarterPlayerScripts
    Parent: StarterPlayerScripts
    Properties:
        Disabled: false
    Exported: 2026-01-02 14:59:28
]]
local Players = game:GetService("Players")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- 🎨 NOVAE PALETTE
local COLORS = {
	Midnight = Color3.fromRGB(25, 25, 35),
	Cream = Color3.fromRGB(250, 248, 235),
	Gold = Color3.fromRGB(255, 215, 0),
	Grey = Color3.fromRGB(60, 60, 65)
}

local isOpen = false
local mainFrame = nil

-- 🛠️ UI BUILDER
local function CreateSettingsUI()
	if playerGui:FindFirstChild("SettingsMenu") then playerGui.SettingsMenu:Destroy() end

	local screen = Instance.new("ScreenGui")
	screen.Name = "SettingsMenu"
	screen.ResetOnSpawn = false
	screen.DisplayOrder = 100
	screen.Parent = playerGui

	-- 1. GEAR BUTTON (Top Left)
	local gearBtn = Instance.new("ImageButton", screen)
	gearBtn.Name = "SettingsBtn"
	gearBtn.Image = "rbxassetid://11401835376" -- Generic Gear Icon
	gearBtn.BackgroundColor3 = COLORS.Midnight
	gearBtn.ImageColor3 = COLORS.Cream
	gearBtn.Size = UDim2.new(0.05, 0, 0.05, 0) -- Slightly bigger for mobile
	gearBtn.SizeConstraint = Enum.SizeConstraint.RelativeXX
	gearBtn.Position = UDim2.new(0.01, 0, 0.02, 0)
	local gc = Instance.new("UICorner", gearBtn) gc.CornerRadius = UDim.new(0.3, 0)
	local gs = Instance.new("UIStroke", gearBtn) gs.Color = COLORS.Gold gs.Thickness = 2

	-- 2. MAIN FRAME (Glassmorphic)
	local frame = Instance.new("Frame", screen)
	frame.Name = "MainFrame"
	frame.Size = UDim2.new(0.4, 0, 0.5, 0) -- Wider for mobile comfort
	frame.Position = UDim2.new(0.5, 0, -0.6, 0) -- Start off-screen top
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.BackgroundColor3 = COLORS.Midnight
	frame.BackgroundTransparency = 0.1
	frame.BorderSizePixel = 0

	local fc = Instance.new("UICorner", frame) fc.CornerRadius = UDim.new(0, 16)
	local fs = Instance.new("UIStroke", frame) fs.Color = COLORS.Gold fs.Thickness = 2

	-- Header
	local title = Instance.new("TextLabel", frame)
	title.Text = "SYSTEM // PREFERENCES"
	title.Font = Enum.Font.GothamBlack
	title.TextSize = 18
	title.TextColor3 = COLORS.Gold
	title.Size = UDim2.new(1, 0, 0.15, 0)
	title.BackgroundTransparency = 1

	-- List Layout
	local container = Instance.new("Frame", frame)
	container.Size = UDim2.new(0.9, 0, 0.8, 0)
	container.Position = UDim2.new(0.05, 0, 0.15, 0)
	container.BackgroundTransparency = 1

	local list = Instance.new("UIListLayout", container)
	list.Padding = UDim.new(0.05, 0)
	list.SortOrder = Enum.SortOrder.LayoutOrder

	-- 🎚️ SLIDER FACTORY (FIXED FOR MOBILE)
	local function CreateSlider(name, labelText, soundGroup)
		local sliderFrame = Instance.new("Frame", container)
		sliderFrame.Name = name
		sliderFrame.Size = UDim2.new(1, 0, 0.18, 0) -- Taller touch target
		sliderFrame.BackgroundTransparency = 1

		local label = Instance.new("TextLabel", sliderFrame)
		label.Text = labelText
		label.TextColor3 = COLORS.Cream
		label.Font = Enum.Font.GothamBold
		label.TextSize = 14
		label.Size = UDim2.new(1, 0, 0.4, 0)
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.BackgroundTransparency = 1

		-- The Track (Visual)
		local track = Instance.new("Frame", sliderFrame)
		track.Name = "Track"
		track.Size = UDim2.new(1, 0, 0.2, 0)
		track.Position = UDim2.new(0, 0, 0.6, 0)
		track.BackgroundColor3 = COLORS.Grey
		local tc = Instance.new("UICorner", track) tc.CornerRadius = UDim.new(1, 0)

		-- The Fill (Visual)
		local fill = Instance.new("Frame", track)
		fill.Name = "Fill"
		fill.Size = UDim2.new(0.5, 0, 1, 0) -- Start at 50%
		fill.BackgroundColor3 = COLORS.Gold
		local fkc = Instance.new("UICorner", fill) fkc.CornerRadius = UDim.new(1, 0)

		-- The Knob (Visual)
		local knob = Instance.new("Frame", track)
		knob.Name = "Knob"
		knob.Size = UDim2.new(0.05, 0, 2.5, 0) -- Bigger knob
		knob.SizeConstraint = Enum.SizeConstraint.RelativeYY
		knob.Position = UDim2.new(0.5, 0, 0.5, 0)
		knob.AnchorPoint = Vector2.new(0.5, 0.5)
		knob.BackgroundColor3 = COLORS.Cream
		local kc = Instance.new("UICorner", knob) kc.CornerRadius = UDim.new(1, 0)

		-- 🚨 HITBOX (Invisible, covers whole slider area for easy touching)
		local hitbox = Instance.new("TextButton", sliderFrame)
		hitbox.Text = ""
		hitbox.BackgroundTransparency = 1
		hitbox.Size = UDim2.new(1, 0, 0.6, 0) -- Covers track + padding
		hitbox.Position = UDim2.new(0, 0, 0.4, 0)
		hitbox.ZIndex = 5

		-- LOGIC
		local isDragging = false

		local function UpdateSlider(input)
			local trackAbsPos = track.AbsolutePosition.X
			local trackAbsSize = track.AbsoluteSize.X
			local inputX = input.Position.X

			-- Math to get 0-1 percentage
			local percent = math.clamp((inputX - trackAbsPos) / trackAbsSize, 0, 1)

			-- Update Visuals
			fill.Size = UDim2.new(percent, 0, 1, 0)
			knob.Position = UDim2.new(percent, 0, 0.5, 0)

			-- Update Audio (0 to 2 volume range)
			if soundGroup then
				soundGroup.Volume = percent * 2 
			end
		end

		-- Input Start (Touch or Click)
		hitbox.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				isDragging = true
				UpdateSlider(input) -- Jump to position instantly on tap
			end
		end)

		-- Global Input Monitor (So you can drag off the UI and it still works)
		UserInputService.InputChanged:Connect(function(input)
			if isDragging then
				if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
					UpdateSlider(input)
				end
			end
		end)

		-- Input End (Global)
		UserInputService.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				isDragging = false
			end
		end)
	end

	-- 🔆 TOGGLE FACTORY
	local function CreateToggle(name, labelText, onClick)
		local toggleFrame = Instance.new("Frame", container)
		toggleFrame.Name = name
		toggleFrame.Size = UDim2.new(1, 0, 0.15, 0)
		toggleFrame.BackgroundTransparency = 1

		local label = Instance.new("TextLabel", toggleFrame)
		label.Text = labelText
		label.TextColor3 = COLORS.Cream
		label.Font = Enum.Font.GothamBold
		label.TextSize = 14
		label.Size = UDim2.new(0.7, 0, 1, 0)
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.BackgroundTransparency = 1

		local btn = Instance.new("TextButton", toggleFrame)
		btn.Text = ""
		btn.Size = UDim2.new(0.2, 0, 0.6, 0)
		btn.Position = UDim2.new(1, 0, 0.2, 0)
		btn.AnchorPoint = Vector2.new(1, 0)
		btn.BackgroundColor3 = COLORS.Grey
		local bc = Instance.new("UICorner", btn) bc.CornerRadius = UDim.new(1, 0)

		local dot = Instance.new("Frame", btn)
		dot.Size = UDim2.new(0.4, 0, 0.8, 0)
		dot.Position = UDim2.new(0.1, 0, 0.1, 0)
		dot.BackgroundColor3 = COLORS.Cream
		local dc = Instance.new("UICorner", dot) dc.CornerRadius = UDim.new(1, 0)

		local active = false
		btn.MouseButton1Click:Connect(function()
			active = not active
			local targetPos = active and UDim2.new(0.5, 0, 0.1, 0) or UDim2.new(0.1, 0, 0.1, 0)
			local targetCol = active and COLORS.Gold or COLORS.Grey

			TweenService:Create(dot, TweenInfo.new(0.2), {Position = targetPos}):Play()
			TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = targetCol}):Play()

			onClick(active)
		end)
	end

	-- Wait for Groups from SoundManager
	local musicG = SoundService:WaitForChild("Music", 5)
	local sfxG = SoundService:WaitForChild("SFX", 5)

	-- BUILD ELEMENTS
	CreateSlider("MusicVol", "MUSIC VOLUME", musicG)
	CreateSlider("SFXVol", "SFX VOLUME", sfxG)

	CreateToggle("PerfMode", "LOW DETAIL MODE", function(enabled)
		-- Disable Shadows/Atmosphere for performance
		Lighting.GlobalShadows = not enabled
		if enabled then
			print("📉 Performance Mode: ON")
		else
			print("📈 Performance Mode: OFF")
		end
	end)

	mainFrame = frame
	return gearBtn
end

local gear = CreateSettingsUI()

-- ⚙️ OPEN/CLOSE LOGIC
gear.MouseButton1Click:Connect(function()
	isOpen = not isOpen

	local targetY = isOpen and 0.5 or -0.6
	TweenService:Create(mainFrame, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Position = UDim2.new(0.5, 0, targetY, 0)
	}):Play()
end)