--[[
    ResultsController (LocalScript)
    Path: StarterPlayer → StarterPlayerScripts
    Parent: StarterPlayerScripts
    Properties:
        Disabled: false
    Exported: 2026-01-02 14:59:28
]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local EndRoundEvent = ReplicatedStorage:WaitForChild("Events"):WaitForChild("EndRound")

-- 🎨 COLORS
local COLORS = {
	Midnight = Color3.fromRGB(20, 20, 30),
	Cream = Color3.fromRGB(250, 248, 235),
	Gold = Color3.fromRGB(255, 215, 0),
	Red = Color3.fromRGB(255, 60, 60),
	Green = Color3.fromRGB(0, 255, 150)
}

-- 🛠️ UI BUILDER
local function CreateResultsUI(data)
	local screen = Instance.new("ScreenGui")
	screen.Name = "RunwayResults"
	screen.IgnoreGuiInset = true
	screen.ResetOnSpawn = false
	screen.DisplayOrder = 100 -- Top priority
	screen.Parent = playerGui

	-- Background Blur
	local blur = Instance.new("BlurEffect", game.Lighting)
	blur.Size = 0
	TweenService:Create(blur, TweenInfo.new(0.5), {Size = 20}):Play()

	-- Main Card
	local card = Instance.new("Frame", screen)
	card.Size = UDim2.new(0.5, 0, 0.6, 0)
	card.Position = UDim2.new(0.5, 0, 1.5, 0) -- Off screen bottom
	card.AnchorPoint = Vector2.new(0.5, 0.5)
	card.BackgroundColor3 = COLORS.Midnight
	card.BorderSizePixel = 0
	local cc = Instance.new("UICorner", card) cc.CornerRadius = UDim.new(0, 16)
	local stroke = Instance.new("UIStroke", card) stroke.Thickness = 3

	-- Theme Colors
	if data.Winner == "Designers" then
		stroke.Color = COLORS.Green
	else
		stroke.Color = COLORS.Red
	end

	-- Title
	local title = Instance.new("TextLabel", card)
	title.Text = (data.Winner == "Designers") and "COLLECTION SAVED" or "CHAOS REIGNS"
	title.Font = Enum.Font.GothamBlack
	title.TextSize = 32
	title.TextColor3 = stroke.Color
	title.Size = UDim2.new(1, 0, 0.2, 0)
	title.BackgroundTransparency = 1

	-- Stats Container
	local list = Instance.new("UIListLayout", card)
	list.FillDirection = Enum.FillDirection.Vertical
	list.Padding = UDim.new(0.05, 0)
	list.HorizontalAlignment = Enum.HorizontalAlignment.Center
	list.VerticalAlignment = Enum.VerticalAlignment.Center

	-- Helper for Rows
	local function AddRow(text, val, color)
		local row = Instance.new("Frame", card)
		row.Size = UDim2.new(0.8, 0, 0.15, 0)
		row.BackgroundTransparency = 1

		local label = Instance.new("TextLabel", row)
		label.Text = text
		label.Font = Enum.Font.GothamBold
		label.TextSize = 18
		label.TextColor3 = COLORS.Cream
		label.Size = UDim2.new(0.5, 0, 1, 0)
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.BackgroundTransparency = 1

		local value = Instance.new("TextLabel", row)
		value.Text = "0" -- Start at 0 for animation
		value.Font = Enum.Font.Code
		value.TextSize = 22
		value.TextColor3 = color or COLORS.Gold
		value.Size = UDim2.new(0.5, 0, 1, 0)
		value.Position = UDim2.new(0.5, 0, 0, 0)
		value.TextXAlignment = Enum.TextXAlignment.Right
		value.BackgroundTransparency = 1

		return value -- Return label to animate
	end

	-- Padding Frame
	local pad = Instance.new("Frame", card)
	pad.Size = UDim2.new(1,0,0.1,0) pad.BackgroundTransparency = 1

	local spoolLabel = AddRow("SEWING SPOOLS", data.Spools, COLORS.Gold)
	local xpLabel = AddRow("EXPERIENCE", data.XP, COLORS.Cream)

	-- Multiplier Badge
	if data.IsClean and data.Winner == "Designers" then
		local badge = Instance.new("TextLabel", card)
		badge.Text = "✨ CLEAN RUN BONUS (1.5x) ✨"
		badge.Font = Enum.Font.GothamBlack
		badge.TextColor3 = COLORS.Gold
		badge.TextSize = 14
		badge.Size = UDim2.new(1, 0, 0.1, 0)
		badge.BackgroundTransparency = 1

		-- Pulse
		TweenService:Create(badge, TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {TextTransparency = 0.5}):Play()
	end

	-- ANIMATION SEQUENCE
	-- 1. Slide In
	TweenService:Create(card, TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Position = UDim2.new(0.5, 0, 0.5, 0)
	}):Play()

	task.wait(0.5)

	-- 2. Count Up Numbers
	local function CountUp(label, target)
		for i = 0, target, math.ceil(target/20) do
			label.Text = "+" .. i
			task.wait(0.02)
		end
		label.Text = "+" .. target
		-- Pop effect
		local s = label.TextSize
		label.TextSize = s * 1.5
		TweenService:Create(label, TweenInfo.new(0.2), {TextSize = s}):Play()
	end

	task.spawn(function() CountUp(spoolLabel, data.Spools) end)
	task.wait(0.5)
	task.spawn(function() CountUp(xpLabel, data.XP) end)

	-- 3. Cleanup
	task.delay(7, function()
		TweenService:Create(card, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
			Position = UDim2.new(0.5, 0, 1.5, 0)
		}):Play()
		TweenService:Create(blur, TweenInfo.new(0.5), {Size = 0}):Play()
		task.wait(0.5)
		screen:Destroy()
		blur:Destroy()
	end)
end

EndRoundEvent.OnClientEvent:Connect(CreateResultsUI)