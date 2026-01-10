-- -------------------------------------------------------------------------------
-- 📂 PROJECT: LAST LOOK
-- 📝 SCRIPT: StationManager (Server - HARDENED)
-- 🛠️ AUTH: Novae Studios
-- 💡 DESC: Manages Task A/B assignments and verifies results.
-- -------------------------------------------------------------------------------

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SkillCheckRemote = ReplicatedStorage:FindFirstChild("SkillCheckEvent") or Instance.new("RemoteEvent")
SkillCheckRemote.Name = "SkillCheckEvent"
SkillCheckRemote.Parent = ReplicatedStorage

local StationManager = {}
local activeSessions = {} -- { [Player] = {Station=Obj, StartTime=Tick} }

function StationManager.AssignPlayer(player, station)
	activeSessions[player] = {Station = station, StartTime = os.clock()}
	
	-- Randomly decide task type
	local taskType = math.random() > 0.5 and "TriggerSpin" or "TriggerWire"
	SkillCheckRemote:FireClient(player, taskType, station)
end

function StationManager.RemovePlayer(player)
	activeSessions[player] = nil
end

-- Verify Results
SkillCheckRemote.OnServerEvent:Connect(function(player, action, station, result)
	if action == "Result" then
		local session = activeSessions[player]
		if not session or session.Station ~= station then 
			-- Exploit Attempt: Submitting result for wrong/inactive station
			return 
		end
		
		-- Time Check (Did they finish instantly?)
		local elapsed = os.clock() - session.StartTime
		if elapsed < 0.5 then
			warn(player.Name .. " completed task impossibly fast. Possible Exploit.")
			return
		end
		
		if result == "Great" then
			-- Add Progress
			local cur = station:GetAttribute("Progress") or 0
			station:SetAttribute("Progress", cur + 10)
		end
		
		-- Reset session for next check loop
		activeSessions[player].StartTime = os.clock()
	end
end)

return StationManager
