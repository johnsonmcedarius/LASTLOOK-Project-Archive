-- -------------------------------------------------------------------------------
-- 📂 PROJECT: LAST LOOK
-- 📝 SCRIPT: StationUIConnector (Client - AUTO BUILD VERSION)
-- 💡 DESC: Creates the UI automatically so you don't have to build it.
-- -------------------------------------------------------------------------------

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

-- 1. AUTO-BUILD THE UI
local screen = Instance.new("ScreenGui")
screen.Name = "StationGUI"
screen.ResetOnSpawn = false
screen.Parent = PlayerGui

local bgFrame = Instance.new("Frame")
bgFrame.Name = "ProgressBarBG"
bgFrame.Size = UDim2.fromOffset(200, 20)
bgFrame.Position = UDim2.fromScale(0.5, 0.7) -- Center bottom
bgFrame.AnchorPoint = Vector2.new(0.5, 0.5)
bgFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
bgFrame.BorderSizePixel = 2
bgFrame.BorderColor3 = Color3.fromRGB(255, 255, 255)
bgFrame.Visible = false -- Hidden by default
bgFrame.Parent = screen

local fillFrame = Instance.new("Frame")
fillFrame.Name = "Fill"
fillFrame.Size = UDim2.fromScale(0, 1) -- Start empty
fillFrame.BackgroundColor3 = Color3.fromRGB(255, 215, 0) -- Gold
fillFrame.BorderSizePixel = 0
fillFrame.Parent = bgFrame

-- 2. LOGIC (Same as before)
local InteractionRemote = ReplicatedStorage:WaitForChild("InteractionEvent")
local currentStation = nil
local progressConnection = nil
local tweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Linear)

local function updateBar()
	if not currentStation then return end
	local current = currentStation:GetAttribute("CurrentProgress") or 0
	local max = currentStation:GetAttribute("WorkRequired") or 100
	local ratio = math.clamp(current / max, 0, 1)
	TweenService:Create(fillFrame, tweenInfo, {Size = UDim2.fromScale(ratio, 1)}):Play()
end

local function startTracking(station)
	if progressConnection then progressConnection:Disconnect() end
	currentStation = station
	bgFrame.Visible = true
	updateBar()
	progressConnection = station:GetAttributeChangedSignal("CurrentProgress"):Connect(updateBar)
end

local function stopTracking()
	if progressConnection then progressConnection:Disconnect() end
	currentStation = nil
	bgFrame.Visible = false
end

InteractionRemote.OnClientEvent:Connect(function(action, data)
	if action == "TaskStarted" then
		startTracking(data)
	elseif action == "TaskFailed" or action == "TaskStopped" then
		stopTracking()
	end
end)
