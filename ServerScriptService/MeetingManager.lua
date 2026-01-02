--[[
    MeetingManager (ModuleScript)
    Path: ServerScriptService
    Parent: ServerScriptService
    Exported: 2026-01-02 14:59:28
]]
-- ServerScriptService/MeetingManager
local MeetingManager = {}
local SEAT_FOLDER = workspace:WaitForChild("MeetingTable")

local savedPositions = {} -- Cache for positions

local function Log(msg)
	print("🪑 [MEETING MGR] " .. msg)
end

-- Shuffle Function
local function shuffleTable(t)
	for i = #t, 2, -1 do
		local j = math.random(i)
		t[i], t[j] = t[j], t[i]
	end
	return t
end

function MeetingManager.StartMeeting(players)
	Log("Teleporting players to meeting...")
	savedPositions = {} 

	local availableSeats = SEAT_FOLDER:GetChildren()
	shuffleTable(availableSeats)

	local seatIndex = 1

	for _, player in pairs(players) do
		-- 🔓 GHOST CHECK REMOVED FOR TESTING
		-- We are letting everyone sit, even dead people, so you can test the UI.

		local char = player.Character

		-- Only sit if we have a seat available
		if char and availableSeats[seatIndex] then
			local hrp = char:FindFirstChild("HumanoidRootPart")
			local hum = char:FindFirstChild("Humanoid")

			if hrp and hum then
				-- Save Position
				savedPositions[player.UserId] = hrp.CFrame

				-- Freeze & Teleport
				hum.WalkSpeed = 0
				hum.JumpPower = 0

				local seat = availableSeats[seatIndex]
				-- Teleport slightly above the seat
				hrp.CFrame = seat.CFrame + Vector3.new(0, 2, 0)
				-- Force look at center (Assuming seat looks at center)
				hrp.CFrame = CFrame.new(hrp.Position, seat.Position + seat.CFrame.LookVector * 5)

				seatIndex += 1 -- Move to next chair
			end
		end
	end
	Log("Meeting Seating Complete.")
end

function MeetingManager.EndMeeting(players)
	Log("Meeting Adjourned. Restoring positions.")

	for _, player in pairs(players) do
		-- Note: We allow ghosts to be restored too in this test version
		local char = player.Character
		if char then
			local hrp = char:FindFirstChild("HumanoidRootPart")
			local hum = char:FindFirstChild("Humanoid")

			if hrp and hum then
				if savedPositions[player.UserId] then
					hrp.CFrame = savedPositions[player.UserId]
				else
					-- Fallback to Spawn
					hrp.CFrame = workspace.Spawns:GetChildren()[1].CFrame + Vector3.new(0,5,0)
				end

				hum.WalkSpeed = 16
				hum.JumpPower = 50
			end
		end
	end

	savedPositions = {} -- Clear cache
end

return MeetingManager