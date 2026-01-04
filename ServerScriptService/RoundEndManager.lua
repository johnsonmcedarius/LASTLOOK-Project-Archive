-- -------------------------------------------------------------------------------
-- 📂 PROJECT: LAST LOOK
-- 📝 SCRIPT: RoundEndManager (Server)
-- 🛠️ AUTH: Novae Studios
-- 💡 DESC: Calculates "Best Dressed" (MVP), Payouts, and Lobby Reset.
-- -------------------------------------------------------------------------------

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local DataManager = require(game.ServerScriptService.DataManager)

-- EVENTS
local RoundOverRemote = Instance.new("RemoteEvent")
RoundOverRemote.Name = "RoundOverEvent" -- Fires to Client with final stats
RoundOverRemote.Parent = ReplicatedStorage

-- BINDABLES (For other scripts to talk to this one)
local AddScoreBindable = Instance.new("BindableEvent")
AddScoreBindable.Name = "AddScore"
AddScoreBindable.Parent = ServerStorage

local EndGameBindable = Instance.new("BindableEvent")
EndGameBindable.Name = "TriggerEndGame"
EndGameBindable.Parent = ServerStorage

-- CONFIG
local SCORES = {
	ESCAPE = 50,
	GREAT_STITCH = 10,
	RESCUE = 30,
	SURVIVAL_MINUTE = 5, -- Points per minute survived
	KILL = 50, -- Per kill (Saboteur)
	WIPEOUT = 100 -- All 4 dead (Saboteur)
}

-- STATE
local PlayerScores = {} -- [UserId] = {Total = 0, Breakdown = {}}

-- // HELPER: Init Score Table
local function initScore(player)
	if not PlayerScores[player.UserId] then
		PlayerScores[player.UserId] = {
			Total = 0,
			Breakdown = {
				["Great Stitches"] = 0,
				["Rescues"] = 0,
				["Escaped"] = 0
			}
		}
	end
end

-- // FUNCTION: Add Score
AddScoreBindable.Event:Connect(function(player, category, amount)
	if not player then return end
	initScore(player)
	
	local data = PlayerScores[player.UserId]
	local points = amount or SCORES[category] or 10
	
	data.Total += points
	
	-- Track specific stats for the UI breakdown
	if category == "GREAT_STITCH" then
		data.Breakdown["Great Stitches"] += 1
	elseif category == "RESCUE" then
		data.Breakdown["Rescues"] += 1
	elseif category == "ESCAPE" then
		data.Breakdown["Escaped"] = 1
	end
	
	print("📈 " .. player.Name .. " + " .. points .. " pts (" .. category .. ")")
end)

-- // CORE: Process End Game
EndGameBindable.Event:Connect(function(winnerTeam)
	print("📸 FLASHING LIGHTS. CALCULATING MVP.")
	
	local MVP = nil
	local highestScore = -1
	local finalStats = {}
	
	-- 1. Calculate MVP & Distribute Spools
	for _, player in pairs(Players:GetPlayers()) do
		initScore(player)
		local data = PlayerScores[player.UserId]
		
		-- Saboteur Bonus Check
		if player:GetAttribute("Role") == "Saboteur" then
			if winnerTeam == "Saboteur" then
				data.Total += SCORES.WIPEOUT
			end
		end
		
		-- MVP Check
		if data.Total > highestScore then
			highestScore = data.Total
			MVP = player
		end
		
		-- PAYOUT (Spools)
		-- Convert Score to Spools (1:1 ratio or whatever balance you want)
		local spoolEarned = math.floor(data.Total)
		DataManager:AdjustSpools(player, spoolEarned)
		
		-- Add to table to send to clients
		table.insert(finalStats, {
			Name = player.Name,
			UserId = player.UserId,
			Score = data.Total,
			Role = player:GetAttribute("Role") or "Designer",
			IsMVP = false
		})
	end
	
	-- Mark MVP in the table
	for _, stat in pairs(finalStats) do
		if MVP and stat.UserId == MVP.UserId then
			stat.IsMVP = true
		end
	end
	
	-- 2. Broadcast to Clients (The Vogue Cover)
	RoundOverRemote:FireAllClients(winnerTeam, finalStats, MVP)
	
	-- 3. Reset Data for Next Round
	PlayerScores = {} 
	
	-- Note: GameLoop handles the actual teleport back to lobby after X seconds
end)

-- Cleanup on leave
Players.PlayerRemoving:Connect(function(player)
	PlayerScores[player.UserId] = nil
end)