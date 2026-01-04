-- -------------------------------------------------------------------------------
-- 📂 PROJECT: LAST LOOK
-- 📝 SCRIPT: StationUIConnector (Client)
-- 💡 DESC: Updates the Progress Bar UI based on Station Attributes.
-- -------------------------------------------------------------------------------

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Player = Players.LocalPlayer
local BGFrame = script.Parent
local FillFrame = BGFrame:WaitForChild("Fill")

-- Remote to know when we start/stop working
-- NOTE: We are listening for the InteractionRemote return fire from Server, 
-- or we can use a simpler Bindable if the Controller handles it.
-- For now, let's assume the InteractionController enables this UI, 
-- OR we listen to a specific "TaskStarted" event if you add it.

-- BETTER APPROACH: Listen to the InteractionController's target.
-- Since they are separate scripts, we'll use a BindableEvent or just a Global variable pattern 
-- but to keep it clean, let's look for a "CurrentTask" ObjectValue in the player 
-- (You'd need to create this) OR use the Remote.

-- Let's use the Remote we already have. 
-- We need to update InteractionServer to FireClient("TaskStarted", station) to make this robust.
-- Assuming InteractionServer fires this:

local InteractionRemote = ReplicatedStorage:WaitForChild("InteractionEvent")
local currentStation = nil
local progressConnection = nil

local tweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Linear)

-- // UPDATE BAR VISUALS
local function updateBar()
	if not currentStation then return end
	
	local current = currentStation:GetAttribute("CurrentProgress") or 0
	local max = currentStation:GetAttribute("WorkRequired") or 100
	local ratio = math.clamp(current / max, 0, 1)
	
	-- Smoothly tween the bar
	TweenService:Create(FillFrame, tweenInfo, {Size = UDim2.fromScale(ratio, 1)}):Play()
end

-- // START TRACKING
local function startTracking(station)
	-- Cleanup old
	if progressConnection then progressConnection:Disconnect() end
	
	currentStation = station
	BGFrame.Visible = true
	
	-- Update immediately
	updateBar()
	
	-- Listen for changes (Attribute is the most efficient way)
	progressConnection = station:GetAttributeChangedSignal("CurrentProgress"):Connect(updateBar)
end

-- // STOP TRACKING
local function stopTracking()
	if progressConnection then progressConnection:Disconnect() end
	currentStation = nil
	BGFrame.Visible = false
end

-- // EVENT LISTENER
InteractionRemote.OnClientEvent:Connect(function(action, data)
	if action == "TaskStarted" then
		startTracking(data) -- data is the Station Model
	elseif action == "TaskFailed" or action == "TaskStopped" then
		stopTracking()
	end
end)

-- Reset on Load
BGFrame.Visible = false