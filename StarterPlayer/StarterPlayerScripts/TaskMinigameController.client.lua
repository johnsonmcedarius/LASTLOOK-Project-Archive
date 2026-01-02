--[[
    TaskMinigameController (LocalScript)
    Path: StarterPlayer → StarterPlayerScripts
    Parent: StarterPlayerScripts
    Properties:
        Disabled: false
    Exported: 2026-01-02 03:27:27
]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local ProximityPromptService = game:GetService("ProximityPromptService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- 🚨 EVENTS
local EventsFolder = ReplicatedStorage:WaitForChild("Events")
local TaskCompletedEvent = EventsFolder:WaitForChild("TaskCompleted")
-- We lazy load TaskFailed inside FailGame to prevent crash if event isn't made yet

-- STATE
local currentTaskNode = nil
local isBusy = false
local activeGui = nil
local timerConnection = nil
local gameLoopConnection = nil 
local timeLeft = 0

-- 🎨 CONFIG
local GAME_TIME_LIMIT = 25 
local COLORS = {
	Red = Color3.fromRGB(255, 80, 80),
	Blue = Color3.fromRGB(80, 180, 255),
	Yellow = Color3.fromRGB(255, 230, 80),
	Green = Color3.fromRGB(100, 255, 120),
	Orange = Color3.fromRGB(255, 160, 50),
	White = Color3.fromRGB(255, 255, 255),
	DarkGrey = Color3.fromRGB(30, 30, 35),
	Black = Color3.new(0,0,0),
	Purple = Color3.fromRGB(180, 100, 255)
}
local WIRE_ORDER = {"Red", "Blue", "Yellow", "Green"}

print("✅ Minigame Controller [v10 - CHAOS INTEGRATED] Loaded.")

-- ============================================================================
-- 🛠️ HELPERS & CORE LOGIC
-- ============================================================================

local function SafeRun(func, ...)
	local success, err = pcall(func, ...)
	if not success then
		warn("🚨 [MINIGAME ERROR]: " .. tostring(err))
		if isBusy then 
			if activeGui then activeGui:Destroy() end
			local char = player.Character
			if char and char:FindFirstChild("Humanoid") then
				char.Humanoid.WalkSpeed = 16
				char.Humanoid.JumpPower = 50
				workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
			end
			isBusy = false
		end
	end
end

local function SetFrozen(frozen)
	local char = player.Character
	if char and char:FindFirstChild("Humanoid") then
		if frozen then
			char.Humanoid.WalkSpeed = 0
			char.Humanoid.JumpPower = 0
			workspace.CurrentCamera.CameraType = Enum.CameraType.Scriptable
		else
			char.Humanoid.WalkSpeed = 16
			char.Humanoid.JumpPower = 50
			workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
		end
	end
end

-- 📉 THE PUNISHER
local function FailGame()
	if not isBusy then return end
	print("💥 FAILED! Chaos Increasing...")

	-- 🚨 FIRE CHAOS EVENT
	local failEvent = EventsFolder:FindFirstChild("TaskFailed")
	if failEvent then
		failEvent:FireServer(currentTaskNode)
	end

	-- Shake Effect
	if activeGui and activeGui:FindFirstChild("GameArea", true) then
		local frame = activeGui:FindFirstChild("GameArea", true)
		local origin = frame.Position
		for i = 1, 10 do
			frame.Position = origin + UDim2.new(0, math.random(-8, 8), 0, math.random(-8, 8))
			task.wait(0.04)
		end
	end

	if activeGui then activeGui:Destroy() end
	if timerConnection then timerConnection:Disconnect() end
	if gameLoopConnection then gameLoopConnection:Disconnect() end

	SetFrozen(false)
	isBusy = false
end

local function WinGame()
	if timerConnection then timerConnection:Disconnect() end
	if gameLoopConnection then gameLoopConnection:Disconnect() end

	task.wait(0.2)
	print("🏆 Task Solved!")
	TaskCompletedEvent:FireServer(currentTaskNode)

	if activeGui then activeGui:Destroy() end
	SetFrozen(false)
	isBusy = false
end

-- 🛠️ UI GENERATOR
local function CreateBaseUI(templateName)
	if activeGui then activeGui:Destroy() end

	-- 1. Try Custom Asset
	local assets = ReplicatedStorage:FindFirstChild("Assets")
	local template = assets and assets:FindFirstChild("MinigameUI") and assets.MinigameUI:FindFirstChild(templateName)

	if template then
		local clone = template:Clone()
		clone.Parent = playerGui
		activeGui = clone
		local container = clone:WaitForChild("GameArea")
		local closeBtn = container:FindFirstChild("CloseButton") or container:FindFirstChild("Close")
		return clone, container, closeBtn
	end

	-- 2. Fallback Generator
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = templateName
	screenGui.IgnoreGuiInset = true
	screenGui.ResetOnSpawn = false
	screenGui.DisplayOrder = 10

	local bg = Instance.new("Frame", screenGui)
	bg.Name = "Background"
	bg.Size = UDim2.new(1, 0, 1, 0)
	bg.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
	bg.BackgroundTransparency = 0.15

	local container = Instance.new("Frame", bg)
	container.Name = "GameArea"
	container.Size = UDim2.new(0.85, 0, 0.6, 0)
	container.Position = UDim2.new(0.5, 0, 0.5, 0)
	container.AnchorPoint = Vector2.new(0.5, 0.5)
	container.BackgroundColor3 = COLORS.DarkGrey
	container.BorderSizePixel = 0
	local c = Instance.new("UICorner", container) c.CornerRadius = UDim.new(0, 16)
	local s = Instance.new("UIStroke", container) s.Color = Color3.fromRGB(60,60,65) s.Thickness = 2

	local closeBtn = Instance.new("TextButton", container)
	closeBtn.Name = "CloseButton"
	closeBtn.Text = "×"
	closeBtn.Font = Enum.Font.GothamBold
	closeBtn.TextSize = 32
	closeBtn.TextColor3 = COLORS.Red
	closeBtn.BackgroundTransparency = 1
	closeBtn.Size = UDim2.new(0.15, 0, 0.15, 0)
	closeBtn.Position = UDim2.new(0.85, 0, 0, 0)

	screenGui.Parent = playerGui
	activeGui = screenGui
	return screenGui, container, closeBtn
end

local function StartTimer(container)
	timeLeft = GAME_TIME_LIMIT
	local timerBar = container:FindFirstChild("TimerBar") or Instance.new("Frame", container)
	timerBar.Name = "TimerBar"
	timerBar.Size = UDim2.new(1, 0, 0.05, 0)
	timerBar.BackgroundColor3 = COLORS.Orange
	timerBar.BorderSizePixel = 0
	timerBar.ZIndex = 5

	timerConnection = RunService.Heartbeat:Connect(function(dt)
		timeLeft -= dt
		timerBar.Size = UDim2.new(timeLeft / GAME_TIME_LIMIT, 0, 0.05, 0)
		if timeLeft <= 0 then FailGame() end
	end)
end

-- ============================================================================
-- 1. 💳 BADGE SCAN (COMMON TASK)
-- ============================================================================
local function StartBadgeScan(taskNode)
	if isBusy then return end
	isBusy = true
	currentTaskNode = taskNode
	SetFrozen(true)

	local _, container, closeBtn = CreateBaseUI("BadgeScan")
	StartTimer(container)

	local status = Instance.new("TextLabel", container)
	status.Text = "SWIPE CARD -->"
	status.Size = UDim2.new(1,0,0.2,0)
	status.BackgroundTransparency = 1
	status.TextColor3 = COLORS.White
	status.Font = Enum.Font.GothamBold
	status.TextSize = 24

	local track = Instance.new("Frame", container)
	track.Size = UDim2.new(0.8, 0, 0.2, 0)
	track.Position = UDim2.new(0.1, 0, 0.4, 0)
	track.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	local tc = Instance.new("UICorner", track) tc.CornerRadius = UDim.new(1,0)

	local card = Instance.new("Frame", track)
	card.Size = UDim2.new(0.2, 0, 1.4, 0)
	card.Position = UDim2.new(0, 0, -0.2, 0)
	card.BackgroundColor3 = COLORS.White
	local cc = Instance.new("UICorner", card) cc.CornerRadius = UDim.new(0.2, 0)

	local dragging = false
	card.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = true end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local delta = input.Position.X - track.AbsolutePosition.X
			local percent = math.clamp(delta / track.AbsoluteSize.X, 0, 0.8)
			card.Position = UDim2.new(percent, 0, -0.2, 0)

			if percent >= 0.75 then
				dragging = false
				status.Text = "ACCEPTED"
				status.TextColor3 = COLORS.Green
				card.BackgroundColor3 = COLORS.Green
				WinGame()
			end
		end
	end)

	UserInputService.InputEnded:Connect(function(input) dragging = false; card.Position = UDim2.new(0, 0, -0.2, 0) end)
	if closeBtn then closeBtn.MouseButton1Click:Connect(FailGame) end
end

-- ============================================================================
-- 2. 🔌 WIRING MINIGAME
-- ============================================================================
local function StartWiringGame(taskNode)
	if isBusy then return end
	isBusy = true
	currentTaskNode = taskNode
	SetFrozen(true)

	local gui, container, closeBtn = CreateBaseUI("Wiring")
	StartTimer(container)

	local leftButtons, rightButtons = {}, {}
	local activeLine = nil
	local solvedCount = 0
	local totalWires = 4
	local rightColors = {unpack(WIRE_ORDER)}

	for i = #rightColors, 2, -1 do
		local j = math.random(i)
		rightColors[i], rightColors[j] = rightColors[j], rightColors[i]
	end

	local function EnsureBtn(side, index, colorName)
		local name = side .. "_" .. colorName
		local btn = container:FindFirstChild(name)
		if not btn then
			btn = Instance.new("ImageButton", container)
			btn.Name = name
			btn.BackgroundColor3 = COLORS[colorName]
			btn.Size = UDim2.new(0.15, 0, 0.15, 0)
			local yPos = 0.2 + (index - 1) * 0.2
			btn.Position = (side == "Left") and UDim2.new(0.05, 0, yPos, 0) or UDim2.new(0.8, 0, yPos, 0)
			local c = Instance.new("UICorner", btn) c.CornerRadius = UDim.new(1, 0)
		end
		if side == "Left" then leftButtons[colorName] = btn else rightButtons[colorName] = btn end
	end

	for i, c in ipairs(WIRE_ORDER) do EnsureBtn("Left", i, c) end
	for i, c in ipairs(rightColors) do EnsureBtn("Right", i, c) end

	local canvas = Instance.new("Frame", container)
	canvas.Name = "LineCanvas"
	canvas.Size = UDim2.new(1, 0, 1, 0)
	canvas.BackgroundTransparency = 1
	canvas.ZIndex = 2

	local function DrawLine(startPos, endPos, color)
		if not activeLine then
			activeLine = Instance.new("Frame", canvas)
			activeLine.BackgroundColor3 = color
			activeLine.BorderSizePixel = 0
			activeLine.AnchorPoint = Vector2.new(0.5, 0.5)
			local c = Instance.new("UICorner", activeLine) c.CornerRadius = UDim.new(1, 0)
		end
		local vec = endPos - startPos
		local angle = math.atan2(vec.Y, vec.X)
		activeLine.Size = UDim2.new(0, vec.Magnitude, 0, 8)
		activeLine.Position = UDim2.new(0, (startPos + endPos).X/2, 0, (startPos + endPos).Y/2)
		activeLine.Rotation = math.deg(angle)
	end

	local dragging, currentStartColor, currentStartPos = false, nil, nil
	local function GetInputPos(input) return Vector2.new(input.Position.X - container.AbsolutePosition.X, input.Position.Y - container.AbsolutePosition.Y) end

	for color, btn in pairs(leftButtons) do
		btn.InputBegan:Connect(function(input)
			if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) and not btn:GetAttribute("Solved") then
				dragging = true
				currentStartColor = color
				currentStartPos = (btn.AbsolutePosition - container.AbsolutePosition) + (btn.AbsoluteSize/2)
			end
		end)
	end

	UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			DrawLine(currentStartPos, GetInputPos(input), COLORS[currentStartColor])
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
			dragging = false
			local endAbs = input.Position
			local hit = false
			for color, btn in pairs(rightButtons) do
				local bPos, bSize = btn.AbsolutePosition, btn.AbsoluteSize
				if endAbs.X >= bPos.X and endAbs.X <= bPos.X + bSize.X and endAbs.Y >= bPos.Y and endAbs.Y <= bPos.Y + bSize.Y then
					if color == currentStartColor and not btn:GetAttribute("Solved") then
						hit = true
						btn:SetAttribute("Solved", true)
						leftButtons[currentStartColor]:SetAttribute("Solved", true)
						activeLine = nil
						solvedCount += 1
						if solvedCount >= totalWires then WinGame() end
					end
				end
			end
			if not hit and activeLine then activeLine:Destroy() activeLine = nil end
		end
	end)

	if closeBtn then closeBtn.MouseButton1Click:Connect(FailGame) end
end

-- ============================================================================
-- 3. 💨 STEAM VALVE
-- ============================================================================
local function StartSteamGame(taskNode)
	if isBusy then return end
	isBusy = true
	currentTaskNode = taskNode
	SetFrozen(true)

	local gui, container, closeBtn = CreateBaseUI("SteamValve")
	StartTimer(container)

	local gauge = container:FindFirstChild("Gauge") or Instance.new("Frame", container)
	gauge.Name = "Gauge" gauge.Size = UDim2.new(0.5, 0, 0.5, 0)
	gauge.SizeConstraint = Enum.SizeConstraint.RelativeYY gauge.Position = UDim2.new(0.5, 0, 0.35, 0)
	gauge.AnchorPoint = Vector2.new(0.5, 0.5) gauge.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	local gc = Instance.new("UICorner", gauge) gc.CornerRadius = UDim.new(1, 0)

	local needle = gauge:FindFirstChild("Needle") or Instance.new("Frame", gauge)
	needle.Name = "Needle" needle.Size = UDim2.new(0.04, 0, 0.45, 0)
	needle.Position = UDim2.new(0.5, 0, 0.5, 0) needle.AnchorPoint = Vector2.new(0.5, 1)
	needle.BackgroundColor3 = COLORS.Red

	local ventBtn = container:FindFirstChild("VentButton") or Instance.new("TextButton", container)
	ventBtn.Name = "VentButton" ventBtn.Text = "VENT"
	ventBtn.Size = UDim2.new(0.6, 0, 0.15, 0) ventBtn.Position = UDim2.new(0.5, 0, 0.85, 0)
	ventBtn.AnchorPoint = Vector2.new(0.5, 0.5) ventBtn.BackgroundColor3 = COLORS.Red
	local vc = Instance.new("UICorner", ventBtn) vc.CornerRadius = UDim.new(0, 8)

	local statusLabel = container:FindFirstChild("StatusLabel") or Instance.new("TextLabel", container)
	statusLabel.Name = "StatusLabel" statusLabel.Text = "HOLD TO VENT!"
	statusLabel.Size = UDim2.new(1, 0, 0.1, 0) statusLabel.Position = UDim2.new(0, 0, 0.65, 0)
	statusLabel.TextColor3 = COLORS.White statusLabel.BackgroundTransparency = 1
	statusLabel.Font = Enum.Font.GothamBold statusLabel.TextSize = 20

	local pressure, isVenting, stability = 0, false, 0
	local TARGET_MIN, TARGET_MAX = 45, 70

	ventBtn.MouseButton1Down:Connect(function() isVenting = true end)
	ventBtn.MouseButton1Up:Connect(function() isVenting = false end)
	ventBtn.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.Touch then isVenting = true end end)
	ventBtn.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.Touch then isVenting = false end end)

	gameLoopConnection = RunService.Heartbeat:Connect(function(dt)
		if isVenting then pressure -= 60 * dt else pressure += 35 * dt end
		pressure = math.clamp(pressure, 0, 100)
		needle.Rotation = -90 + (pressure / 100) * 180

		if pressure < TARGET_MIN then
			statusLabel.Text = "TOO LOW! RELEASE!"
			statusLabel.TextColor3 = COLORS.Blue
			ventBtn.BackgroundColor3 = COLORS.Red
		elseif pressure > TARGET_MAX then
			statusLabel.Text = "CRITICAL! VENT!"
			statusLabel.TextColor3 = COLORS.Red
			ventBtn.BackgroundColor3 = COLORS.Red
		else
			stability += dt
			statusLabel.Text = "STABILIZING... " .. string.format("%.1f", 3 - stability)
			statusLabel.TextColor3 = COLORS.Green
			ventBtn.BackgroundColor3 = COLORS.Green
			container.Position = UDim2.new(0.5, math.random(-1,1), 0.5, math.random(-1,1))
		end
		if stability >= 3 then WinGame() end
	end)
	if closeBtn then closeBtn.MouseButton1Click:Connect(FailGame) end
end

-- ============================================================================
-- 4. 🧪 CHEMICAL MIXER
-- ============================================================================
local function StartChemicalGame(taskNode)
	if isBusy then return end
	isBusy = true
	currentTaskNode = taskNode
	SetFrozen(true)

	local gui, container, closeBtn = CreateBaseUI("ChemicalMixer")
	StartTimer(container)

	local statusLabel = container:FindFirstChild("StatusLabel") or Instance.new("TextLabel", container)
	statusLabel.Name = "StatusLabel" statusLabel.Text = "WATCH..."
	statusLabel.Size = UDim2.new(1, 0, 0.2, 0) statusLabel.TextColor3 = COLORS.White
	statusLabel.BackgroundTransparency = 1 statusLabel.Font = Enum.Font.GothamBold
	statusLabel.TextSize = 20

	local btns = {}
	local colors = {COLORS.Red, COLORS.Blue, COLORS.Yellow, COLORS.Green}
	for i = 1, 4 do
		local btn = container:FindFirstChild("Btn"..i)
		if not btn then
			btn = Instance.new("ImageButton", container) btn.Name = "Btn"..i
			btn.BackgroundColor3 = colors[i]
			btn.Size = UDim2.new(0.2, 0, 0.4, 0)
			btn.Position = UDim2.new(0.05 + (i-1)*0.24, 0, 0.3, 0)
			local c = Instance.new("UICorner", btn) c.CornerRadius = UDim.new(0, 8)
		end
		btns[i] = btn
	end

	local pattern, playerSequence, round, maxRounds, acceptingInput = {}, {}, 1, 3, false

	local function Flash(btnIndex)
		local btn = btns[btnIndex]
		if not btn then return end
		local original = btn.BackgroundColor3
		btn.BackgroundColor3 = Color3.new(math.min(original.R+0.4,1), math.min(original.G+0.4,1), math.min(original.B+0.4,1))
		task.wait(0.3)
		btn.BackgroundColor3 = original
		task.wait(0.1)
	end

	local function PlayRound()
		acceptingInput = false
		statusLabel.Text = "WATCH..."
		table.insert(pattern, math.random(1, 4))
		playerSequence = {}
		task.wait(1)
		for _, idx in ipairs(pattern) do Flash(idx) end
		statusLabel.Text = "REPEAT!"
		acceptingInput = true
	end

	local function CheckInput(idx)
		if not acceptingInput then return end
		table.insert(playerSequence, idx)
		Flash(idx)
		local step = #playerSequence
		if playerSequence[step] ~= pattern[step] then
			statusLabel.Text = "WRONG!"
			statusLabel.TextColor3 = COLORS.Red
			task.wait(0.5)
			FailGame()
		elseif step == #pattern then
			if round >= maxRounds then
				statusLabel.Text = "MIXED!"
				statusLabel.TextColor3 = COLORS.Green
				WinGame()
			else
				round += 1
				statusLabel.Text = "GOOD!"
				task.wait(0.5)
				PlayRound()
			end
		end
	end

	for i, btn in ipairs(btns) do btn.MouseButton1Click:Connect(function() CheckInput(i) end) end
	if closeBtn then closeBtn.MouseButton1Click:Connect(FailGame) end
	PlayRound()
end

-- ============================================================================
-- 5. 📸 PHOTOSHOOT
-- ============================================================================
local function StartPhotoshootGame(taskNode)
	if isBusy then return end
	isBusy = true
	currentTaskNode = taskNode
	SetFrozen(true)

	local _, container, closeBtn = CreateBaseUI("Photoshoot")
	StartTimer(container)

	local viewfinder = container:FindFirstChild("Viewfinder") or Instance.new("Frame", container)
	viewfinder.Name = "Viewfinder" viewfinder.Size = UDim2.new(0.8, 0, 0.6, 0)
	viewfinder.Position = UDim2.new(0.5, 0, 0.4, 0) viewfinder.AnchorPoint = Vector2.new(0.5, 0.5)
	viewfinder.BackgroundColor3 = COLORS.Black viewfinder.ClipsDescendants = true

	local subject = viewfinder:FindFirstChild("Subject") or Instance.new("Frame", viewfinder)
	subject.Name = "Subject" subject.Size = UDim2.new(0.2, 0, 0.2, 0)
	subject.BackgroundColor3 = COLORS.Blue subject.Position = UDim2.new(0.1, 0, 0.5, 0)
	local c = Instance.new("UICorner", subject) c.CornerRadius = UDim.new(1, 0)

	local snapBtn = container:FindFirstChild("SnapButton") or Instance.new("TextButton", container)
	snapBtn.Name = "SnapButton" snapBtn.Text = "SNAP"
	snapBtn.Size = UDim2.new(0.4, 0, 0.15, 0) snapBtn.Position = UDim2.new(0.5, 0, 0.85, 0)
	snapBtn.AnchorPoint = Vector2.new(0.5, 0.5) snapBtn.BackgroundColor3 = COLORS.White
	snapBtn.TextColor3 = COLORS.Black
	local c = Instance.new("UICorner", snapBtn) c.CornerRadius = UDim.new(0, 8)

	local status = container:FindFirstChild("StatusLabel") or Instance.new("TextLabel", container)
	status.Name = "StatusLabel" status.Text = "0/3"
	status.Size = UDim2.new(1, 0, 0.1, 0) status.TextColor3 = COLORS.White
	status.BackgroundTransparency = 1 status.Font = Enum.Font.GothamBold status.TextSize = 24

	local score, t = 0, 0
	gameLoopConnection = RunService.Heartbeat:Connect(function(dt)
		t = t + dt * (1 + score * 0.5)
		local xPos = 0.5 + math.sin(t * 3) * 0.4
		subject.Position = UDim2.new(xPos, 0, 0.5, 0)
	end)

	snapBtn.MouseButton1Click:Connect(function()
		if math.abs(subject.Position.X.Scale - 0.5) < 0.08 then
			score += 1
			status.Text = score .. "/3"
			if score >= 3 then WinGame() end
		else
			status.Text = "MISSED!"
			status.TextColor3 = COLORS.Red
			task.wait(0.5)
			status.TextColor3 = COLORS.White
			status.Text = score .. "/3"
		end
	end)
	if closeBtn then closeBtn.MouseButton1Click:Connect(FailGame) end
end

-- ============================================================================
-- 6. 🧶 FABRIC PRESS
-- ============================================================================
local function StartFabricPressGame(taskNode)
	if isBusy then return end
	isBusy = true
	currentTaskNode = taskNode
	SetFrozen(true)

	local _, container, closeBtn = CreateBaseUI("FabricPress")
	StartTimer(container)

	local bed = container:FindFirstChild("PressBed") or Instance.new("Frame", container)
	bed.Name = "PressBed" bed.Size = UDim2.new(0.9, 0, 0.1, 0)
	bed.Position = UDim2.new(0.5, 0, 0.4, 0) bed.AnchorPoint = Vector2.new(0.5, 0.5)
	bed.BackgroundColor3 = COLORS.DarkGrey

	local target = bed:FindFirstChild("TargetZone") or Instance.new("Frame", bed)
	target.Name = "TargetZone" target.Size = UDim2.new(0.2, 0, 1, 0)
	target.Position = UDim2.new(0.7, 0, 0, 0) target.BackgroundColor3 = COLORS.Green
	target.BackgroundTransparency = 0.5

	local head = bed:FindFirstChild("MovingHead") or Instance.new("Frame", bed)
	head.Name = "MovingHead" head.Size = UDim2.new(0.1, 0, 1.5, 0)
	head.Position = UDim2.new(0, 0, -0.25, 0) head.BackgroundColor3 = COLORS.White

	local pressBtn = container:FindFirstChild("PressButton") or Instance.new("TextButton", container)
	pressBtn.Name = "PressButton" pressBtn.Text = "PRESS"
	pressBtn.Size = UDim2.new(0.4, 0, 0.2, 0) pressBtn.Position = UDim2.new(0.5, 0, 0.7, 0)
	pressBtn.AnchorPoint = Vector2.new(0.5, 0.5) pressBtn.BackgroundColor3 = COLORS.Red
	pressBtn.Font = Enum.Font.GothamBold pressBtn.TextSize = 24

	local hits, speed, phase = 0, 1.5, 0
	gameLoopConnection = RunService.Heartbeat:Connect(function(dt)
		phase = phase + dt * speed
		local pos = (math.sin(phase) + 1) / 2
		head.Position = UDim2.new(pos * 0.9, 0, -0.25, 0)
	end)

	pressBtn.MouseButton1Click:Connect(function()
		local hPos = head.Position.X.Scale
		local tPos = target.Position.X.Scale
		if hPos >= tPos - 0.05 and hPos <= tPos + target.Size.X.Scale then
			hits += 1
			pressBtn.Text = "GOOD! " .. hits .. "/3"
			target.Position = UDim2.new(math.random(2, 8)/10, 0, 0, 0)
			speed += 0.5
			if hits >= 3 then WinGame() end
		else
			FailGame()
		end
	end)
	if closeBtn then closeBtn.MouseButton1Click:Connect(FailGame) end
end

-- ============================================================================
-- 7. 🧹 LINT ROLL
-- ============================================================================
local function StartLintRollGame(taskNode)
	if isBusy then return end
	isBusy = true
	currentTaskNode = taskNode
	SetFrozen(true)

	local _, container, closeBtn = CreateBaseUI("LintRoll")
	StartTimer(container)

	local fabric = container:FindFirstChild("FabricBg")
	if not fabric then
		fabric = Instance.new("Frame", container) fabric.Name = "FabricBg"
		fabric.Size = UDim2.new(0.8, 0, 0.6, 0) fabric.Position = UDim2.new(0.5, 0, 0.5, 0)
		fabric.AnchorPoint = Vector2.new(0.5, 0.5) fabric.BackgroundColor3 = Color3.fromRGB(20, 20, 80)
	end

	local lints, totalLint, cleaned = {}, 15, 0

	for i = 1, totalLint do
		local lint = Instance.new("ImageLabel", fabric)
		lint.Size = UDim2.new(0.1, 0, 0.1, 0)
		lint.Position = UDim2.new(math.random(10, 90)/100, 0, math.random(10, 90)/100, 0)
		lint.BackgroundColor3 = COLORS.White lint.BackgroundTransparency = 0.3
		lint.Rotation = math.random(0, 360)
		table.insert(lints, lint)
	end

	local status = container:FindFirstChild("StatusLabel") or Instance.new("TextLabel", container)
	status.Text = "SCRUB OFF THE LINT!" status.Size = UDim2.new(1, 0, 0.1, 0)
	status.TextColor3 = COLORS.White status.BackgroundTransparency = 1
	status.Font = Enum.Font.GothamBold status.TextSize = 20

	gameLoopConnection = RunService.Heartbeat:Connect(function()
		local mouse = UserInputService:GetMouseLocation()
		for i = #lints, 1, -1 do
			local l = lints[i]
			if (mouse - (l.AbsolutePosition + l.AbsoluteSize/2)).Magnitude < 40 then
				l:Destroy()
				table.remove(lints, i)
				cleaned += 1
				if cleaned >= totalLint then WinGame() end
			end
		end
	end)
	if closeBtn then closeBtn.MouseButton1Click:Connect(FailGame) end
end

-- ============================================================================
-- 8. ⚡ POWER DISTRIBUTION
-- ============================================================================
local function StartPowerDistGame(taskNode)
	if isBusy then return end
	isBusy = true
	currentTaskNode = taskNode
	SetFrozen(true)

	local _, container, closeBtn = CreateBaseUI("PowerDist")
	StartTimer(container)

	local monitor = container:FindFirstChild("Monitor") or Instance.new("Frame", container)
	monitor.Name = "Monitor" monitor.Size = UDim2.new(0.6, 0, 0.4, 0)
	monitor.Position = UDim2.new(0.5, 0, 0.3, 0) monitor.AnchorPoint = Vector2.new(0.5, 0.5)
	monitor.BackgroundColor3 = COLORS.Black

	local display = monitor:FindFirstChild("VoltageDisplay") or Instance.new("TextLabel", monitor)
	display.Name = "VoltageDisplay" display.Size = UDim2.new(1,0,1,0)
	display.TextSize = 40 display.Font = Enum.Font.Code
	display.BackgroundTransparency = 1

	local lockBtn = container:FindFirstChild("LockButton") or Instance.new("TextButton", container)
	lockBtn.Name = "LockButton" lockBtn.Text = "LOCK VOLTAGE (90-100)"
	lockBtn.Size = UDim2.new(0.6, 0, 0.2, 0) lockBtn.Position = UDim2.new(0.5, 0, 0.7, 0)
	lockBtn.AnchorPoint = Vector2.new(0.5, 0.5) lockBtn.BackgroundColor3 = COLORS.Blue
	lockBtn.Font = Enum.Font.GothamBold

	local currentVolts, phase = 0, 0
	gameLoopConnection = RunService.Heartbeat:Connect(function(dt)
		phase = phase + dt * 5
		local noise = math.noise(phase, 0, 0)
		currentVolts = math.clamp(50 + (noise * 60), 0, 120)
		display.Text = math.floor(currentVolts) .. "%"
		if currentVolts > 100 then display.TextColor3 = COLORS.Red
		elseif currentVolts >= 90 then display.TextColor3 = COLORS.Green
		else display.TextColor3 = COLORS.Yellow end
	end)

	lockBtn.MouseButton1Click:Connect(function()
		if currentVolts >= 90 and currentVolts <= 100 then WinGame() else FailGame() end
	end)
	if closeBtn then closeBtn.MouseButton1Click:Connect(FailGame) end
end

-- ============================================================================
-- 9. 👕 FABRIC SORTER
-- ============================================================================
local function StartFabricSorterGame(taskNode)
	if isBusy then return end
	isBusy = true
	currentTaskNode = taskNode
	SetFrozen(true)

	local _, container, closeBtn = CreateBaseUI("FabricSorter")
	StartTimer(container)

	local binLeft = container:FindFirstChild("BinLeft") or Instance.new("TextButton", container)
	binLeft.Name = "BinLeft" binLeft.Text = "RED" binLeft.BackgroundColor3 = COLORS.Red
	binLeft.Size = UDim2.new(0.3, 0, 0.4, 0) binLeft.Position = UDim2.new(0.1, 0, 0.4, 0)

	local binRight = container:FindFirstChild("BinRight") or Instance.new("TextButton", container)
	binRight.Name = "BinRight" binRight.Text = "BLUE" binRight.BackgroundColor3 = COLORS.Blue
	binRight.Size = UDim2.new(0.3, 0, 0.4, 0) binRight.Position = UDim2.new(0.6, 0, 0.4, 0)

	local item = container:FindFirstChild("ItemSpawn") or Instance.new("Frame", container)
	item.Name = "ItemSpawn" item.Size = UDim2.new(0.2, 0, 0.2, 0)
	item.Position = UDim2.new(0.4, 0, 0.1, 0)
	local c = Instance.new("UICorner", item) c.CornerRadius = UDim.new(0, 8)

	local itemsSorted, currentItemColor = 0, "Red"
	local function SpawnItem()
		if math.random() > 0.5 then
			currentItemColor = "Red" item.BackgroundColor3 = COLORS.Red
		else
			currentItemColor = "Blue" item.BackgroundColor3 = COLORS.Blue
		end
	end
	SpawnItem()

	local function CheckSort(binColor)
		if currentItemColor == binColor then
			itemsSorted += 1
			if itemsSorted >= 5 then WinGame() else SpawnItem() end
		else
			FailGame()
		end
	end

	binLeft.MouseButton1Click:Connect(function() CheckSort("Red") end)
	binRight.MouseButton1Click:Connect(function() CheckSort("Blue") end)
	if closeBtn then closeBtn.MouseButton1Click:Connect(FailGame) end
end

-- ============================================================================
-- 10. 🧵 SEWING MACHINE (Tap Dots)
-- ============================================================================
local function StartSewingGame(taskNode)
	if isBusy then return end
	isBusy = true
	currentTaskNode = taskNode
	SetFrozen(true)

	local _, container, closeBtn = CreateBaseUI("SewingMachine")
	StartTimer(container)

	local status = Instance.new("TextLabel", container)
	status.Text = "STITCH IT UP! TAP DOTS IN ORDER!"
	status.Size = UDim2.new(1, 0, 0.15, 0)
	status.Position = UDim2.new(0, 0, 0.05, 0)
	status.BackgroundTransparency = 1
	status.TextColor3 = COLORS.White
	status.Font = Enum.Font.GothamBlack
	status.TextSize = 20

	local pathContainer = Instance.new("Frame", container)
	pathContainer.Size = UDim2.new(0.9, 0, 0.6, 0)
	pathContainer.Position = UDim2.new(0.5, 0, 0.5, 0)
	pathContainer.AnchorPoint = Vector2.new(0.5, 0.5)
	pathContainer.BackgroundTransparency = 1

	local points = {
		UDim2.new(0.1, 0, 0.2, 0), UDim2.new(0.3, 0, 0.8, 0),
		UDim2.new(0.5, 0, 0.2, 0), UDim2.new(0.7, 0, 0.8, 0),
		UDim2.new(0.9, 0, 0.5, 0)
	}

	local currentTarget = 1
	for i, pt in ipairs(points) do
		local dot = Instance.new("ImageButton", pathContainer)
		dot.Name = "Dot_"..i
		dot.Size = UDim2.new(0.15, 0, 0.15, 0)
		dot.SizeConstraint = Enum.SizeConstraint.RelativeXX
		dot.Position = pt
		dot.AnchorPoint = Vector2.new(0.5, 0.5)
		dot.BackgroundColor3 = (i == 1) and COLORS.Green or COLORS.Red
		local c = Instance.new("UICorner", dot) c.CornerRadius = UDim.new(1, 0)

		local num = Instance.new("TextLabel", dot)
		num.Size = UDim2.new(1,0,1,0) num.BackgroundTransparency = 1
		num.Text = tostring(i) num.Font = Enum.Font.GothamBold
		num.TextColor3 = COLORS.Black

		dot.MouseButton1Click:Connect(function()
			if i == currentTarget then
				currentTarget += 1
				dot.BackgroundColor3 = COLORS.Blue
				dot.Visible = false
				if currentTarget > #points then
					status.Text = "SEAMLESS!"
					WinGame()
				else
					local nextDot = pathContainer:FindFirstChild("Dot_"..currentTarget)
					if nextDot then nextDot.BackgroundColor3 = COLORS.Green end
				end
			else
				FailGame()
			end
		end)
	end
	if closeBtn then closeBtn.MouseButton1Click:Connect(FailGame) end
end

-- ============================================================================
-- 11. 👗 MANNEQUIN DRESS-UP
-- ============================================================================
local function StartMannequinGame(taskNode)
	if isBusy then return end
	isBusy = true
	currentTaskNode = taskNode
	SetFrozen(true)

	local _, container, closeBtn = CreateBaseUI("Mannequin")
	StartTimer(container)

	local status = Instance.new("TextLabel", container)
	status.Text = "COVER THEM UP!"
	status.Size = UDim2.new(1, 0, 0.1, 0)
	status.BackgroundTransparency = 1
	status.TextColor3 = COLORS.White
	status.Font = Enum.Font.GothamBold
	status.TextSize = 20

	local silhouette = Instance.new("Frame", container)
	silhouette.Name = "Body"
	silhouette.Size = UDim2.new(0.3, 0, 0.7, 0)
	silhouette.Position = UDim2.new(0.35, 0, 0.2, 0)
	silhouette.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	local c = Instance.new("UICorner", silhouette) c.CornerRadius = UDim.new(0.5, 0)

	local items = {
		{Name="Wig", Color=COLORS.Yellow, TargetPos=UDim2.new(0.5, 0, 0.1, 0)},
		{Name="Top", Color=COLORS.Red, TargetPos=UDim2.new(0.5, 0, 0.35, 0)},
		{Name="Pants", Color=COLORS.Blue, TargetPos=UDim2.new(0.5, 0, 0.7, 0)}
	}

	local itemsPlaced = 0
	for i, data in ipairs(items) do
		local item = Instance.new("TextButton", container)
		item.Text = data.Name
		item.BackgroundColor3 = data.Color
		item.Size = UDim2.new(0.2, 0, 0.15, 0)
		item.Position = UDim2.new(0.75, 0, 0.2 + (i*0.2), 0)
		local ic = Instance.new("UICorner", item) ic.CornerRadius = UDim.new(0, 8)

		local dragging, startPos = false, item.Position
		item.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = true end
		end)
		UserInputService.InputChanged:Connect(function(input)
			if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
				local mousePos = input.Position
				local contAbs = container.AbsolutePosition
				item.Position = UDim2.new(0, mousePos.X - contAbs.X - (item.AbsoluteSize.X/2), 0, mousePos.Y - contAbs.Y - (item.AbsoluteSize.Y/2))
			end
		end)
		UserInputService.InputEnded:Connect(function(input)
			if dragging then
				dragging = false
				local bodyAbs = silhouette.AbsolutePosition
				local center = item.AbsolutePosition + (item.AbsoluteSize/2)
				if center.X > bodyAbs.X and center.X < bodyAbs.X + silhouette.AbsoluteSize.X and center.Y > bodyAbs.Y and center.Y < bodyAbs.Y + silhouette.AbsoluteSize.Y then
					item.Position = UDim2.new(0, (bodyAbs.X - container.AbsolutePosition.X) + (silhouette.AbsoluteSize.X/2) - (item.AbsoluteSize.X/2), 0, (bodyAbs.Y - container.AbsolutePosition.Y) + (data.TargetPos.Y.Scale * silhouette.AbsoluteSize.Y))
					item.Active = false
					itemsPlaced += 1
					if itemsPlaced >= 3 then WinGame() end
				else
					item.Position = startPos
				end
			end
		end)
	end
	if closeBtn then closeBtn.MouseButton1Click:Connect(FailGame) end
end

-- ============================================================================
-- 12. 👞 SHOE SHINE
-- ============================================================================
local function StartShoeShineGame(taskNode)
	if isBusy then return end
	isBusy = true
	currentTaskNode = taskNode
	SetFrozen(true)

	local _, container, closeBtn = CreateBaseUI("ShoeShine")
	StartTimer(container)

	local status = Instance.new("TextLabel", container)
	status.Text = "RUB IT FAST!"
	status.Size = UDim2.new(1, 0, 0.15, 0)
	status.BackgroundTransparency = 1
	status.TextColor3 = COLORS.White
	status.Font = Enum.Font.GothamBold
	status.TextSize = 20

	local shoe = Instance.new("Frame", container)
	shoe.Size = UDim2.new(0.6, 0, 0.4, 0)
	shoe.Position = UDim2.new(0.5, 0, 0.5, 0)
	shoe.AnchorPoint = Vector2.new(0.5, 0.5)
	shoe.BackgroundColor3 = Color3.fromRGB(60, 40, 20)
	local c = Instance.new("UICorner", shoe) c.CornerRadius = UDim.new(0.3, 0)

	local shineOverlay = Instance.new("Frame", shoe)
	shineOverlay.Size = UDim2.new(1, 0, 1, 0)
	shineOverlay.BackgroundColor3 = COLORS.White
	shineOverlay.BackgroundTransparency = 1 
	local sc = Instance.new("UICorner", shineOverlay) sc.CornerRadius = UDim.new(0.3, 0)

	local shineLevel, lastMousePos = 0, nil

	local inputZone = Instance.new("TextButton", container)
	inputZone.Text = ""
	inputZone.BackgroundTransparency = 1
	inputZone.Size = UDim2.new(1,0,1,0)

	inputZone.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then lastMousePos = input.Position end
	end)

	gameLoopConnection = RunService.Heartbeat:Connect(function(dt)
		local mouse = UserInputService:GetMouseLocation()
		if lastMousePos then
			local delta = (mouse - Vector2.new(lastMousePos.X, lastMousePos.Y)).Magnitude
			if delta > 5 then
				shineLevel += delta * 0.005
				if shineLevel > 1 then shineLevel = 1 end
				shineOverlay.BackgroundTransparency = 1 - shineLevel
				if shineLevel >= 1 then WinGame() end
			end
		end
		shineLevel -= dt * 0.1
		if shineLevel < 0 then shineLevel = 0 end
		lastMousePos = Vector3.new(mouse.X, mouse.Y, 0)
	end)
	if closeBtn then closeBtn.MouseButton1Click:Connect(FailGame) end
end

-- ============================================================================
-- 13. 🎨 DYE VAT
-- ============================================================================
local function StartDyeVatGame(taskNode)
	if isBusy then return end
	isBusy = true
	currentTaskNode = taskNode
	SetFrozen(true)

	local _, container, closeBtn = CreateBaseUI("DyeVat")
	StartTimer(container)

	local targetColor = COLORS.Blue

	local status = Instance.new("TextLabel", container)
	status.Text = "MATCH THE DRIP! (WAIT FOR BLUE)"
	status.Size = UDim2.new(1, 0, 0.15, 0)
	status.BackgroundTransparency = 1
	status.TextColor3 = COLORS.White
	status.Font = Enum.Font.GothamBold
	status.TextSize = 18

	local vat = Instance.new("Frame", container)
	vat.Size = UDim2.new(0.5, 0, 0.4, 0)
	vat.Position = UDim2.new(0.5, 0, 0.65, 0)
	vat.AnchorPoint = Vector2.new(0.5, 0.5)
	vat.BackgroundColor3 = COLORS.White

	local dunkBtn = Instance.new("TextButton", container)
	dunkBtn.Text = "DUNK IT!"
	dunkBtn.Size = UDim2.new(0.6, 0, 0.15, 0)
	dunkBtn.Position = UDim2.new(0.5, 0, 0.9, 0)
	dunkBtn.AnchorPoint = Vector2.new(0.5, 0.5)
	dunkBtn.BackgroundColor3 = COLORS.White
	dunkBtn.TextColor3 = COLORS.Black
	dunkBtn.Font = Enum.Font.GothamBlack
	dunkBtn.TextSize = 24
	local c = Instance.new("UICorner", dunkBtn) c.CornerRadius = UDim.new(0, 8)

	local colors = {COLORS.Red, COLORS.Blue, COLORS.Yellow, COLORS.Green, COLORS.Purple, COLORS.Orange}
	local cycleTime, currentColor = 0, COLORS.White

	gameLoopConnection = RunService.Heartbeat:Connect(function(dt)
		cycleTime += dt
		if cycleTime > 0.6 then
			cycleTime = 0
			currentColor = colors[math.random(1, #colors)]
			vat.BackgroundColor3 = currentColor
		end
	end)

	dunkBtn.MouseButton1Click:Connect(function()
		if currentColor == targetColor then WinGame() else FailGame() end
	end)
	if closeBtn then closeBtn.MouseButton1Click:Connect(FailGame) end
end

-- ============================================================================
-- 14. 🔐 SECURITY SAFE (DIAL TURN)
-- ============================================================================
local function StartSecuritySafeGame(taskNode)
	if isBusy then return end
	isBusy = true
	currentTaskNode = taskNode
	SetFrozen(true)

	local _, container, closeBtn = CreateBaseUI("SecuritySafe")
	StartTimer(container)

	local status = Instance.new("TextLabel", container)
	status.Text = "CRACK THE CODE: 20 - 50 - 80"
	status.Size = UDim2.new(1, 0, 0.15, 0)
	status.BackgroundTransparency = 1
	status.TextColor3 = COLORS.Green
	status.Font = Enum.Font.Code
	status.TextSize = 20

	local dial = Instance.new("Frame", container)
	dial.Size = UDim2.new(0.5, 0, 0.5, 0)
	dial.SizeConstraint = Enum.SizeConstraint.RelativeYY
	dial.Position = UDim2.new(0.5, 0, 0.5, 0)
	dial.AnchorPoint = Vector2.new(0.5, 0.5)
	dial.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	local c = Instance.new("UICorner", dial) c.CornerRadius = UDim.new(1, 0)

	local knob = Instance.new("Frame", dial)
	knob.Size = UDim2.new(0.1, 0, 0.4, 0)
	knob.Position = UDim2.new(0.5, 0, 0.1, 0)
	knob.AnchorPoint = Vector2.new(0.5, 0)
	knob.BackgroundColor3 = COLORS.White

	local currentVal = 0
	local targetSequence = {20, 50, 80}
	local step = 1

	local dragging = false
	local lastMousePos = Vector2.new()

	local dragZone = Instance.new("TextButton", container)
	dragZone.Size = UDim2.new(1,0,1,0)
	dragZone.BackgroundTransparency = 1
	dragZone.Text = ""

	dragZone.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			lastMousePos = input.Position
		end
	end)

	dragZone.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local delta = input.Position.X - lastMousePos.X
			currentVal += delta * 0.5
			if currentVal > 100 then currentVal = 0 end
			if currentVal < 0 then currentVal = 100 end

			dial.Rotation = (currentVal / 100) * 360
			lastMousePos = input.Position
		end
	end)

	dragZone.InputEnded:Connect(function(input)
		if dragging then
			dragging = false
			local target = targetSequence[step]
			if math.abs(currentVal - target) < 5 then
				step += 1
				status.Text = "CLICK! NEXT..."
				if step > 3 then 
					status.Text = "UNLOCKED!"
					WinGame()
				end
			end
		end
	end)
	if closeBtn then closeBtn.MouseButton1Click:Connect(FailGame) end
end

-- ============================================================================
-- 15. 📏 MEASURE FABRIC (SLIDER)
-- ============================================================================
local function StartMeasureGame(taskNode)
	if isBusy then return end
	isBusy = true
	currentTaskNode = taskNode
	SetFrozen(true)

	local _, container, closeBtn = CreateBaseUI("MeasureFabric")
	StartTimer(container)

	local status = Instance.new("TextLabel", container)
	status.Text = "CUT AT THE GREEN LINE!"
	status.Size = UDim2.new(1, 0, 0.15, 0)
	status.BackgroundTransparency = 1
	status.TextColor3 = COLORS.White
	status.Font = Enum.Font.GothamBold
	status.TextSize = 20

	local ruler = Instance.new("Frame", container)
	ruler.Size = UDim2.new(0.8, 0, 0.2, 0)
	ruler.Position = UDim2.new(0.1, 0, 0.4, 0)
	ruler.BackgroundColor3 = COLORS.Yellow

	local targetPos = math.random(20, 80) / 100
	local targetLine = Instance.new("Frame", ruler)
	targetLine.Size = UDim2.new(0.05, 0, 1, 0)
	targetLine.Position = UDim2.new(targetPos, 0, 0, 0)
	targetLine.BackgroundColor3 = COLORS.Green

	local slider = Instance.new("Frame", ruler)
	slider.Size = UDim2.new(0.02, 0, 1.2, 0)
	slider.Position = UDim2.new(0, 0, -0.1, 0)
	slider.BackgroundColor3 = COLORS.Red

	local dragging = false
	container.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = true end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local delta = input.Position.X - ruler.AbsolutePosition.X
			local percent = math.clamp(delta / ruler.AbsoluteSize.X, 0, 1)
			slider.Position = UDim2.new(percent, 0, -0.1, 0)
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
			dragging = false
			local currentPos = slider.Position.X.Scale
			if math.abs(currentPos - targetPos) < 0.05 then
				status.Text = "PERFECT CUT!"
				WinGame()
			else
				status.Text = "OOF! CROOKED CUT!"
				status.TextColor3 = COLORS.Red
				FailGame()
			end
		end
	end)
	if closeBtn then closeBtn.MouseButton1Click:Connect(FailGame) end
end

-- ============================================================================
-- 📡 GLOBAL ROUTER (CONNECTS EVERYTHING)
-- ============================================================================
ProximityPromptService.PromptTriggered:Connect(function(prompt, playerWhoTriggered)
	if playerWhoTriggered ~= player then return end

	if prompt.Name == "InteractionPrompt" then
		local taskNode = prompt.Parent
		if taskNode then
			print("⚡ Interacted with: " .. taskNode.Name)
			local name = taskNode.Name

			SafeRun(function()
				if string.find(name, "Badge") or string.find(name, "Scan") or string.find(name, "Card") then StartBadgeScan(taskNode)
				elseif string.find(name, "Sew") or string.find(name, "Stitch") or string.find(name, "Machine") then StartSewingGame(taskNode)
				elseif string.find(name, "Mannequin") or string.find(name, "Dress") or string.find(name, "Style") then StartMannequinGame(taskNode)
				elseif string.find(name, "Shoe") or string.find(name, "Shine") or string.find(name, "Polish") then StartShoeShineGame(taskNode)
				elseif string.find(name, "Dye") or string.find(name, "Color") or string.find(name, "Vat") then StartDyeVatGame(taskNode)
				elseif string.find(name, "Steam") or string.find(name, "Valve") then StartSteamGame(taskNode)
				elseif string.find(name, "Chemical") or string.find(name, "Mixer") or string.find(name, "Lab") then StartChemicalGame(taskNode)
				elseif string.find(name, "Photo") or string.find(name, "Camera") then StartPhotoshootGame(taskNode)
				elseif string.find(name, "Press") or string.find(name, "Iron") then StartFabricPressGame(taskNode)
				elseif string.find(name, "Lint") or string.find(name, "Roll") then StartLintRollGame(taskNode)
				elseif string.find(name, "Power") or string.find(name, "Voltage") then StartPowerDistGame(taskNode)
				elseif string.find(name, "Sort") or string.find(name, "Bin") then StartFabricSorterGame(taskNode)
				elseif string.find(name, "Safe") or string.find(name, "Security") or string.find(name, "Lock") then StartSecuritySafeGame(taskNode)
				elseif string.find(name, "Measure") or string.find(name, "Ruler") or string.find(name, "Cut") then StartMeasureGame(taskNode)
				else StartWiringGame(taskNode) end
			end)
		end
	end
end)