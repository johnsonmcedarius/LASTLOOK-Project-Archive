-- -------------------------------------------------------------------------------
-- 📂 PROJECT: LAST LOOK
-- 📝 SCRIPT: PatternTraceController (Client)
-- 🛠️ AUTH: Novae Studios
-- 💡 DESC: Minigame C. Handles 2D Pattern Tracing for bonuses.
-- -------------------------------------------------------------------------------

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")
local SkillCheckRemote = ReplicatedStorage:WaitForChild("SkillCheckEvent")

-- CONFIG
local MAX_DIST_ERROR = 30 -- Pixels allowed off the line
local WAYPOINT_COUNT = 5

-- STATE
local isActive = false
local waypoints = {} -- {Vector2, Vector2...}
local currentWaypointIndex = 1
local currentStation = nil

-- UI
local TraceHUD = nil

-- // MATH: Dist from Point to Line Segment
local function distToSegment(p, a, b)
	local pa = p - a
	local ba = b - a
	local h = math.clamp(pa:Dot(ba) / ba:Dot(ba), 0, 1)
	return (pa - ba * h).Magnitude
end

-- // SETUP UI
local function setupTraceHUD()
	local screen = Instance.new("ScreenGui")
	screen.Name = "TraceHUD"
	screen.ResetOnSpawn = false
	screen.Parent = PlayerGui
	
	local frame = Instance.new("Frame")
	frame.Size = UDim2.fromOffset(400, 300)
	frame.Position = UDim2.fromScale(0.5, 0.5)
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	frame.Visible = false
	frame.Parent = screen
	TraceHUD = frame
	
	-- Generate Waypoints (Zig Zag Pattern for demo)
	waypoints = {}
	for i = 1, WAYPOINT_COUNT do
		local dot = Instance.new("Frame")
		dot.Size = UDim2.fromOffset(20, 20)
		dot.BackgroundColor3 = Color3.fromRGB(0, 255, 255) -- Cyan
		dot.AnchorPoint = Vector2.new(0.5, 0.5)
		
		-- Random Zig Zag
		local x = (i / (WAYPOINT_COUNT + 1))
		local y = (i % 2 == 0) and 0.3 or 0.7
		
		dot.Position = UDim2.fromScale(x, y)
		dot.Parent = frame
		
		-- Store Absolute Position (We need to update this when UI shows)
		table.insert(waypoints, dot)
	end
end

-- // FUNCTION: Start Trace
local function startTrace(station)
	isActive = true
	currentStation = station
	currentWaypointIndex = 1
	
	if not TraceHUD then setupTraceHUD() end
	TraceHUD.Visible = true
	
	-- Highlight first target
	waypoints[1].BackgroundColor3 = Color3.fromRGB(0, 255, 0)
end

-- // FUNCTION: Fail
local function failTrace()
	isActive = false
	TraceHUD.Visible = false
	SkillCheckRemote:FireServer("Result", currentStation, "Miss")
	-- Play fail sound
end

-- // LOOP: Check Mouse Position
RunService.RenderStepped:Connect(function()
	if not isActive or not TraceHUD.Visible then return end
	
	local mouse = UserInputService:GetMouseLocation()
	
	-- 1. Check if we hit next waypoint
	local targetUI = waypoints[currentWaypointIndex]
	local targetPos = targetUI.AbsolutePosition + (targetUI.AbsoluteSize/2)
	
	if (mouse - targetPos).Magnitude < 40 then -- Hit radius
		targetUI.BackgroundColor3 = Color3.fromRGB(100, 100, 100) -- Dim it
		currentWaypointIndex += 1
		
		if currentWaypointIndex > #waypoints then
			-- SUCCESS!
			isActive = false
			TraceHUD.Visible = false
			SkillCheckRemote:FireServer("Result", currentStation, "Great")
		else
			-- Highlight next
			waypoints[currentWaypointIndex].BackgroundColor3 = Color3.fromRGB(0, 255, 0)
		end
		return
	end
	
	-- 2. Check if we strayed too far from path (Projected line)
	if currentWaypointIndex > 1 then
		local prevUI = waypoints[currentWaypointIndex - 1]
		local prevPos = prevUI.AbsolutePosition + (prevUI.AbsoluteSize/2)
		
		local dist = distToSegment(mouse, prevPos, targetPos)
		if dist > MAX_DIST_ERROR then
			failTrace()
		end
	end
end)

-- REMOTE
SkillCheckRemote.OnClientEvent:Connect(function(action, station)
	if action == "Trace" then
		startTrace(station)
	end
end)