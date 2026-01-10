-- -------------------------------------------------------------------------------
-- 📂 PROJECT: LAST LOOK
-- 📝 SCRIPT: WireTaskController (Client - TASK B: SORTING)
-- 🛠️ AUTH: Novae Studios
-- 💡 DESC: "Among Us" style wire matching. Drag & Drop.
-- -------------------------------------------------------------------------------

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")
local SkillCheckRemote = ReplicatedStorage:WaitForChild("SkillCheckEvent")

local HUD = PlayerGui:WaitForChild("SkillCheckHUD")
local GameFrame = HUD:WaitForChild("WireGame")
local DrawArea = GameFrame:WaitForChild("DrawingArea")

-- CONFIG
local COLORS = {
	Color3.fromRGB(255, 0, 0),   -- Red
	Color3.fromRGB(0, 0, 255),   -- Blue
	Color3.fromRGB(255, 255, 0), -- Yellow
	Color3.fromRGB(255, 0, 255)  -- Magenta
}

-- STATE
local isActive = false
local currentStation = nil
local connections = {} -- { {Start=UI, End=UI, Color=Color} }
local activeLine = nil -- The UI line currently being dragged
local startButton = nil

local function getGuiCenter(guiObject)
	local absPos = guiObject.AbsolutePosition
	local absSize = guiObject.AbsoluteSize
	return Vector2.new(absPos.X + absSize.X/2, absPos.Y + absSize.Y/2)
end

local function updateLine(lineFrame, startPos, endPos)
	local center = (startPos + endPos) / 2
	local diff = endPos - startPos
	local length = diff.Magnitude
	local angle = math.atan2(diff.Y, diff.X)
	
	lineFrame.Size = UDim2.new(0, length, 0, 5) -- 5px thickness
	lineFrame.Position = UDim2.fromOffset(center.X, center.Y)
	lineFrame.Rotation = math.deg(angle)
	lineFrame.AnchorPoint = Vector2.new(0.5, 0.5)
end

local function checkWin()
	local correct = 0
	for _, conn in pairs(connections) do
		if conn.Matched then correct += 1 end
	end
	
	if correct >= 4 then
		task.wait(0.2)
		isActive = false
		HUD.Enabled = false
		SkillCheckRemote:FireServer("Result", currentStation, "Great")
	end
end

local function startGame(station)
	if isActive then return end
	isActive = true
	currentStation = station
	connections = {}
	
	-- Reset UI
	DrawArea:ClearAllChildren()
	HUD.Enabled = true
	GameFrame.Visible = true
	HUD:WaitForChild("SpinGame").Visible = false
	
	-- Shuffle Colors Logic would go here (Assign colors to Left 1-4 and Right 1-4)
	-- For MVP, assuming Buttons are named "L1"..."L4" and "R1"..."R4" and manually colored in Studio or via script loop
	-- Ideally, you script the colors here.
end

-- MOUSE/TOUCH HANDLER
UserInputService.InputBegan:Connect(function(input)
	if not isActive then return end
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		local pos = input.Position
		-- Check if clicking a Left Port
		for _, btn in pairs(GameFrame.LeftPanel:GetChildren()) do
			if btn:IsA("GuiButton") then
				local tl = btn.AbsolutePosition
				local br = tl + btn.AbsoluteSize
				if pos.X >= tl.X and pos.X <= br.X and pos.Y >= tl.Y and pos.Y <= br.Y then
					startButton = btn
					
					-- Create temp line
					activeLine = Instance.new("Frame")
					activeLine.BackgroundColor3 = btn.BackgroundColor3
					activeLine.BorderSizePixel = 0
					activeLine.Parent = DrawArea
					return
				end
			end
		end
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if not isActive or not activeLine or not startButton then return end
	if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
		local startPos = getGuiCenter(startButton) - DrawArea.AbsolutePosition -- Local space
		local mousePos = Vector2.new(input.Position.X, input.Position.Y) - DrawArea.AbsolutePosition
		updateLine(activeLine, startPos, mousePos)
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if not isActive or not activeLine then return end
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		-- Check drop
		local pos = input.Position
		local matched = false
		
		for _, btn in pairs(GameFrame.RightPanel:GetChildren()) do
			if btn:IsA("GuiButton") then
				local tl = btn.AbsolutePosition
				local br = tl + btn.AbsoluteSize
				if pos.X >= tl.X and pos.X <= br.X and pos.Y >= tl.Y and pos.Y <= br.Y then
					-- Check color match
					if btn.BackgroundColor3 == startButton.BackgroundColor3 then
						-- Snap line
						local startPos = getGuiCenter(startButton) - DrawArea.AbsolutePosition
						local endPos = getGuiCenter(btn) - DrawArea.AbsolutePosition
						updateLine(activeLine, startPos, endPos)
						table.insert(connections, {Matched = true})
						matched = true
						startButton.Visible = false -- Hide used ports?
						btn.Visible = false
						checkWin()
					end
				end
			end
		end
		
		if not matched then
			activeLine:Destroy()
		end
		
		activeLine = nil
		startButton = nil
	end
end)

SkillCheckRemote.OnClientEvent:Connect(function(action, station)
	if action == "TriggerWire" then
		startGame(station)
	end
end)
