--[[
    SabotageTabletController (LocalScript)
    Path: StarterPlayer → StarterPlayerScripts
    Parent: StarterPlayerScripts
    Properties:
        Disabled: false
    Exported: 2026-01-02 03:27:27
]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local TabletEvent = ReplicatedStorage:WaitForChild("Events"):WaitForChild("SabotageTabletAction")

-- 🎨 NOVAE OS PALETTE
local COLORS = {
	Midnight = Color3.fromRGB(20, 20, 30),
	Cream = Color3.fromRGB(250, 248, 235),
	Gold = Color3.fromRGB(212, 175, 55),
	Red = Color3.fromRGB(255, 65, 65),
	Glass = 0.1 -- High transparency
}

-- STATE
local isOpen = false
local tabletFrame = nil
local canOpen = false
local buttons = {}

-- 🛠️ UI BUILDER
local function CreateTabletUI()
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "NovaeTablet"
	screenGui.ResetOnSpawn = false
	screenGui.DisplayOrder = 20
	screenGui.Parent = playerGui

	-- 1. MAIN FRAME (Right Side Slide-In)
	local frame = Instance.new("Frame")
	frame.Name = "TabletFrame"
	frame.Size = UDim2.new(0.35, 0, 0.8, 0) -- Vertical layout for mobile
	frame.Position = UDim2.new(1.2, 0, 0.5, 0) -- Start off-screen (Right)
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.BackgroundColor3 = COLORS.Midnight
	frame.BackgroundTransparency = COLORS.Glass
	frame.BorderSizePixel = 0
	frame.Parent = screenGui

	-- Stroke Border
	local stroke = Instance.new("UIStroke", frame)
	stroke.Color = COLORS.Gold
	stroke.Thickness = 2
	stroke.Transparency = 0.4

	local corner = Instance.new("UICorner", frame)
	corner.CornerRadius = UDim.new(0, 16)

	-- 2. HEADER
	local header = Instance.new("Frame", frame)
	header.Size = UDim2.new(1, 0, 0.1, 0)
	header.BackgroundTransparency = 1

	local title = Instance.new("TextLabel", header)
	title.Text = "NOVAE // OS"
	title.Font = Enum.Font.GothamBlack
	title.TextSize = 18
	title.TextColor3 = COLORS.Gold
	title.Size = UDim2.new(1, 0, 0.5, 0)
	title.BackgroundTransparency = 1

	local sub = Instance.new("TextLabel", header)
	sub.Text = "USER: " .. string.upper(player.Name)
	sub.Font = Enum.Font.Code
	sub.TextSize = 12
	sub.TextColor3 = COLORS.Cream
	sub.Size = UDim2.new(1, 0, 0.5, 0)
	sub.Position = UDim2.new(0, 0, 0.5, 0)
	sub.BackgroundTransparency = 1

	-- 3. GRID (Vertical for mobile thumb reach)
	local gridContainer = Instance.new("ScrollingFrame", frame)
	gridContainer.Size = UDim2.new(0.9, 0, 0.8, 0)
	gridContainer.Position = UDim2.new(0.05, 0, 0.12, 0)
	gridContainer.BackgroundTransparency = 1
	gridContainer.ScrollBarThickness = 2
	gridContainer.ScrollBarImageColor3 = COLORS.Gold

	local grid = Instance.new("UIGridLayout", gridContainer)
	grid.CellSize = UDim2.new(0.9, 0, 0.2, 0) -- Wide buttons
	grid.CellPadding = UDim2.new(0, 0, 0.02, 0)
	grid.HorizontalAlignment = Enum.HorizontalAlignment.Center

	-- 4. TILE FACTORY
	local function CreateTile(id, name, color, locked)
		local btn = Instance.new("TextButton", gridContainer)
		btn.Name = id
		btn.Text = ""
		btn.BackgroundColor3 = COLORS.Cream
		btn.BackgroundTransparency = 0.9
		btn.AutoButtonColor = false

		local c = Instance.new("UICorner", btn) c.CornerRadius = UDim.new(0, 8)
		local s = Instance.new("UIStroke", btn) s.Color = color s.Transparency = 0.6

		local lbl = Instance.new("TextLabel", btn)
		lbl.Text = name
		lbl.Font = Enum.Font.GothamBold
		lbl.TextSize = 16
		lbl.TextColor3 = color
		lbl.Size = UDim2.new(1, 0, 1, 0)
		lbl.BackgroundTransparency = 1

		if locked then
			btn.BackgroundColor3 = Color3.new(0,0,0)
			btn.BackgroundTransparency = 0.6
			lbl.Text = "🔒 " .. name .. " (Lvl 10)"
			lbl.TextColor3 = Color3.fromRGB(100, 100, 100)
			s.Color = Color3.fromRGB(60, 60, 60)
		end

		return btn
	end

	local b1 = CreateTile("ValveOverride", "VALVE OVERRIDE", COLORS.Red)
	local b2 = CreateTile("ChaosUnfreeze", "CHAOS UNFREEZE", COLORS.Red)
	local b3 = CreateTile("ShadowWalk", "SHADOW WALK", COLORS.Gold)
	local b4 = CreateTile("SecurityFeed", "SECURITY FEED", COLORS.Cream, true)

	return frame, {b1, b2, b3}
end

local frame, btns = CreateTabletUI()
tabletFrame = frame
buttons = btns

-- 🕵️ PERMISSIONS & ROLE LISTENER
local function UpdateState()
	local role = player:GetAttribute("Role")
	local lvl = player:GetAttribute("Level") or 1

	if role == "Saboteur" and lvl >= 5 then
		canOpen = true
		-- Could show a small icon here indicating tablet is available
	else
		canOpen = false
		if isOpen then ToggleTablet(false) end
	end
end

player:GetAttributeChangedSignal("Role"):Connect(UpdateState)
player:GetAttributeChangedSignal("Level"):Connect(UpdateState)

-- 🎞️ ANIMATION (Right Slide)
function ToggleTablet(show)
	if not canOpen and show then return end
	isOpen = show

	-- Slide from Right: 0.8 (Visible) vs 1.2 (Hidden)
	local targetX = show and 0.8 or 1.2 

	TweenService:Create(tabletFrame, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Position = UDim2.new(targetX, 0, 0.5, 0)
	}):Play()

	-- Blur Effect (Optional luxury feel)
	local blur = game.Lighting:FindFirstChild("TabletBlur")
	if not blur then 
		blur = Instance.new("BlurEffect", game.Lighting)
		blur.Name = "TabletBlur"
		blur.Size = 0
	end
	TweenService:Create(blur, TweenInfo.new(0.4), {Size = show and 15 or 0}):Play()
end

-- INPUT (Q Key or Touch Button needed later)
UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	if input.KeyCode == Enum.KeyCode.Q then
		ToggleTablet(not isOpen)
	end
end)

-- LOGIC
for _, btn in pairs(buttons) do
	btn.MouseButton1Click:Connect(function()
		if not isOpen then return end
		-- Visual Click
		btn.BackgroundColor3 = btn.UIStroke.Color
		btn.BackgroundTransparency = 0.7
		task.delay(0.1, function() btn.BackgroundTransparency = 0.9 end)

		-- Send
		TabletEvent:FireServer(btn.Name)
	end)
end

UpdateState()