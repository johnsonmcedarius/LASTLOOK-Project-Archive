-- -------------------------------------------------------------------------------
-- 📂 PROJECT: LAST LOOK
-- 📝 SCRIPT: ThreadJamController (Client)
-- 🛠️ AUTH: Novae Studios
-- 💡 DESC: Minigame B. Handles Clearing Jams via Swipes/WASD.
-- -------------------------------------------------------------------------------

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")
local SkillCheckRemote = ReplicatedStorage:WaitForChild("SkillCheckEvent") -- Reusing this channel

-- CONFIG
local SWIPE_THRESHOLD = 50 -- Pixels movement to count as a swipe
local THREADS_TO_CLEAR = 3

-- STATE
local isJammed = false
local threadsRemaining = 0
local currentStation = nil
local touchStartPos = nil

-- UI
local JamHUD = nil
local ThreadContainer = nil

-- // SETUP UI
local function setupJamHUD()
	local screen = Instance.new("ScreenGui")
	screen.Name = "JamHUD"
	screen.ResetOnSpawn = false
	screen.Parent = PlayerGui
	
	local frame = Instance.new("Frame")
	frame.Size = UDim2.fromOffset(300, 200)
	frame.Position = UDim2.fromScale(0.5, 0.5)
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.BackgroundColor3 = Color3.fromRGB(0,0,0)
	frame.BackgroundTransparency = 0.5
	frame.Visible = false
	frame.Parent = screen
	JamHUD = frame
	
	local label = Instance.new("TextLabel")
	label.Text = "JAMMED! SWIPE TO CLEAR!"
	label.Size = UDim2.fromScale(1, 0.2)
	label.TextColor3 = Color3.fromRGB(255, 0, 0) -- Neon Red
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
	label.TextSize = 24
	label.Parent = frame
	
	ThreadContainer = Instance.new("Frame")
	ThreadContainer.Size = UDim2.fromScale(1, 0.8)
	ThreadContainer.Position = UDim2.fromScale(0, 0.2)
	ThreadContainer.BackgroundTransparency = 1
	ThreadContainer.Parent = frame
end

-- // FUNCTION: Start Jam
local function startJam(station)
	isJammed = true
	currentStation = station
	threadsRemaining = THREADS_TO_CLEAR
	
	if not JamHUD then setupJamHUD() end
	JamHUD.Visible = true
	
	-- Render Threads (Visuals for Nerd)
	ThreadContainer:ClearAllChildren()
	for i = 1, threadsRemaining do
		local thread = Instance.new("Frame")
		thread.Name = "Thread" .. i
		thread.Size = UDim2.new(0, 10, 0.8, 0)
		thread.Position = UDim2.fromScale(0.25 * i, 0.1)
		thread.BackgroundColor3 = Color3.fromRGB(255, 50, 50) -- Red Thread
		thread.Rotation = math.random(-15, 15)
		thread.Parent = ThreadContainer
	end
end

-- // FUNCTION: Clear One Thread
local function clearThread()
	if not isJammed then return end
	
	threadsRemaining -= 1
	
	-- Update Visuals
	local thread = ThreadContainer:FindFirstChild("Thread" .. (threadsRemaining + 1))
	if thread then thread:Destroy() end
	
	-- Play Snap Sound (SoundManager placeholder)
	local s = Instance.new("Sound")
	s.SoundId = "rbxassetid://12221967" -- Snap sound
	s.Parent = PlayerGui
	s:Play()
	game.Debris:AddItem(s, 1)
	
	if threadsRemaining <= 0 then
		-- CLEARED!
		isJammed = false
		JamHUD.Visible = false
		SkillCheckRemote:FireServer("ClearJam", currentStation)
	end
end

-- // INPUT: Touch Swipe
UserInputService.TouchStarted:Connect(function(input)
	if isJammed then touchStartPos = input.Position end
end)

UserInputService.TouchEnded:Connect(function(input)
	if isJammed and touchStartPos then
		local delta = (input.Position - touchStartPos).Magnitude
		if delta > SWIPE_THRESHOLD then
			clearThread()
		end
		touchStartPos = nil
	end
end)

-- // INPUT: PC (WASD / Arrows) to simulate "Shake/Pull"
UserInputService.InputBegan:Connect(function(input)
	if isJammed then
		if input.KeyCode == Enum.KeyCode.W or input.KeyCode == Enum.KeyCode.A or input.KeyCode == Enum.KeyCode.S or input.KeyCode == Enum.KeyCode.D then
			clearThread()
		end
	end
end)

-- // REMOTE LISTENER
SkillCheckRemote.OnClientEvent:Connect(function(action, station)
	if action == "Jam" then
		startJam(station)
	end
end)