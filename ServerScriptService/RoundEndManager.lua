-- -------------------------------------------------------------------------------
-- 📂 PROJECT: LAST LOOK
-- 📝 SCRIPT: RoundEndManager (Server - PLATINUM MASTER)
-- 🛠️ AUTH: Novae Studios
-- 💡 DESC: Calculates "Best Dressed" (MVP), Payouts (Spools + XP), and Lobby Reset.
-- -------------------------------------------------------------------------------

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local DataManager = require(game.ServerScriptService.DataManager)

-- EVENTS
local RoundOverRemote = Instance.new("RemoteEvent")
RoundOverRemote.Name = "RoundOverEvent" -- Fires to Client with final stats
RoundOverRemote.Parent = ReplicatedStorage

-- BINDABLES (Inputs)
local AddScoreBindable = Instance.new("BindableEvent")
AddScoreBindable.Name = "AddScore"
AddScoreBindable.Parent = ServerStorage

local EndGameBindable = Instance.new("BindableEvent")
EndGameBindable.Name = "TriggerEndGame"
EndGameBindable.Parent = ServerStorage

-- BINDABLES (Outputs)
-- We use WaitForChild for AddXP because XPManager might load a split second later
local AddXPBindable = ServerStorage:WaitForChild("AddXP", 10)

-- CONFIG
local SCORES = {
	ESCAPE = 50,
	GREAT_STITCH = 10,
	RESCUE = 30,
	SURVIVAL_MINUTE = 5, -- Points per minute survived (Calculated in loop if needed)
	KILL = 50, -- Per kill (Saboteur)
	WIPEOUT = 100 -- All 4 dead (Saboteur)
}

local XP_CONVERSION_RATE = 10 -- 1 Score Point = 10 XP

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

-- // FUNCTION: Add Score (Called live during match)
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

-- // CORE: Process End Game (Triggered by GameLoop)
EndGameBindable.Event:Connect(function(winnerTeam)
	print("📸 FLASHING LIGHTS. CALCULATING MVP.")
	
	local MVP = nil
	local highestScore = -1
	local finalStats = {}
	
	-- 1. Calculate MVP & Distribute Rewards
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
		
		-- A. SPOOL PAYOUT (Money)
		local spoolEarned = math.floor(data.Total) -- 1:1 Ratio for Money
		DataManager:AdjustSpools(player, spoolEarned)
		
		-- B. XP HANDSHAKE (Leveling)
		local xpEarned = math.floor(data.Total * XP_CONVERSION_RATE)
		if AddXPBindable then
			AddXPBindable:Fire(player, xpEarned)
		end
		
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
	
	print("🏁 Round Audit Complete. Spools & XP Distributed.")
end)

-- Cleanup on leave
Players.PlayerRemoving:Connect(function(player)
	PlayerScores[player.UserId] = nil
end)
