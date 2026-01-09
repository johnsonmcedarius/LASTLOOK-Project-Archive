-- -------------------------------------------------------------------------------
-- 📂 PROJECT: LAST LOOK
-- 📝 SCRIPT: ThreadJamController (Client - MOUSE FIX)
-- -------------------------------------------------------------------------------

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")
local SkillCheckRemote = ReplicatedStorage:WaitForChild("SkillCheckEvent")

local isJammed = false
local threadsRemaining = 0
local currentStation = nil

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
	frame.Parent = screen
	JamHUD = frame
	
	local label = Instance.new("TextLabel")
	label.Text = "JAMMED! CLICK THREADS!" -- Updated Text for PC
	label.Size = UDim2.fromScale(1, 0.2)
	label.TextColor3 = Color3.fromRGB(255, 0, 0)
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

local function clearThread(threadUI)
	if not isJammed then return end
	
	threadsRemaining -= 1
	if threadUI then threadUI:Destroy() end
	
	-- Sound
	local s = Instance.new("Sound")
	s.SoundId = "rbxassetid://12221967"
	s.Parent = PlayerGui
	s:Play()
	game.Debris:AddItem(s, 1)
	
	if threadsRemaining <= 0 then
		isJammed = false
		JamHUD.Visible = false
		SkillCheckRemote:FireServer("ClearJam", currentStation)
	end
end

local function startJam(station)
	isJammed = true
	currentStation = station
	threadsRemaining = 3
	
	if not JamHUD then setupJamHUD() end
	JamHUD.Visible = true
	ThreadContainer:ClearAllChildren()
	
	-- Create Clickable Threads
	for i = 1, threadsRemaining do
		local thread = Instance.new("TextButton") -- Changed to Button for clicking
		thread.Text = ""
		thread.Size = UDim2.new(0, 15, 0.8, 0)
		thread.Position = UDim2.fromScale(0.25 * i, 0.1)
		thread.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
		thread.Rotation = math.random(-15, 15)
		thread.Parent = ThreadContainer
		
		thread.MouseButton1Click:Connect(function()
			clearThread(thread)
		end)
	end
end

-- // REMOTE LISTENER
SkillCheckRemote.OnClientEvent:Connect(function(action, station)
	if action == "Jam" then
		startJam(station)
	end
end)
