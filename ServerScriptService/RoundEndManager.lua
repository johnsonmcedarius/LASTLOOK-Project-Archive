-- -------------------------------------------------------------------------------
-- 📂 PROJECT: LAST LOOK
-- 📝 SCRIPT: RoundEndManager (Server - PAYOUT UPDATE)
-- 🛠️ AUTH: Novae Studios
-- 💡 DESC: Calculates "Best Dressed" (MVP) and Double Spool Payouts.
-- -------------------------------------------------------------------------------

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local DataManager = require(game.ServerScriptService.DataManager)

-- EVENTS
local RoundOverRemote = Instance.new("RemoteEvent")
RoundOverRemote.Name = "RoundOverEvent" 
RoundOverRemote.Parent = ReplicatedStorage

local AddScoreBindable = Instance.new("BindableEvent")
AddScoreBindable.Name = "AddScore"
AddScoreBindable.Parent = ServerStorage

local EndGameBindable = Instance.new("BindableEvent")
EndGameBindable.Name = "TriggerEndGame"
EndGameBindable.Parent = ServerStorage

-- BINDABLES (Outputs)
local AddXPBindable = ServerStorage:WaitForChild("AddXP", 10)

-- CONFIG
local SCORES = {
	ESCAPE = 50,
	GREAT_STITCH = 10,
	RESCUE = 30,
	SURVIVAL_MINUTE = 5, 
	KILL = 50, 
	WIPEOUT = 100 
}

local XP_CONVERSION_RATE = 10 

-- STATE
local PlayerScores = {} 

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

AddScoreBindable.Event:Connect(function(player, category, amount)
	if not player then return end
	initScore(player)
	
	local data = PlayerScores[player.UserId]
	local points = amount or SCORES[category] or 10
	
	data.Total += points
	
	if category == "GREAT_STITCH" then
		data.Breakdown["Great Stitches"] += 1
	elseif category == "RESCUE" then
		data.Breakdown["Rescues"] += 1
	elseif category == "ESCAPE" then
		data.Breakdown["Escaped"] = 1
	end
end)

EndGameBindable.Event:Connect(function(winnerTeam)
	print("📸 FLASHING LIGHTS. CALCULATING MVP.")
	
	local MVP = nil
	local highestScore = -1
	local finalStats = {}
	
	-- 1. Calculate MVP & Distribute Rewards
	for _, player in pairs(Players:GetPlayers()) do
		initScore(player)
		local data = PlayerScores[player.UserId]
		
		if player:GetAttribute("Role") == "Saboteur" then
			if winnerTeam == "Saboteur" then
				data.Total += SCORES.WIPEOUT
			end
		end
		
		if data.Total > highestScore then
			highestScore = data.Total
			MVP = player
		end
		
		-- A. SPOOL PAYOUT (Money)
		local spoolEarned = math.floor(data.Total)
		
		-- [UPDATED] Check for Double Spools Pass
		if DataManager:HasPass(player, "DoubleSpools") then
			spoolEarned = spoolEarned * 2
			-- print("🧵 2x Spools Applied for " .. player.Name)
		end
		
		DataManager:AdjustSpools(player, spoolEarned)
		
		-- B. XP HANDSHAKE (Leveling)
		-- XP Manager handles the 2x XP Pass check internally now
		local xpEarned = math.floor(data.Total * XP_CONVERSION_RATE)
		if AddXPBindable then
			AddXPBindable:Fire(player, xpEarned)
		end
		
		table.insert(finalStats, {
			Name = player.Name,
			UserId = player.UserId,
			Score = data.Total,
			Role = player:GetAttribute("Role") or "Designer",
			IsMVP = false
		})
	end
	
	for _, stat in pairs(finalStats) do
		if MVP and stat.UserId == MVP.UserId then
			stat.IsMVP = true
		end
	end
	
	RoundOverRemote:FireAllClients(winnerTeam, finalStats, MVP)
	
	PlayerScores = {} 
	
	print("🏁 Round Audit Complete.")
end)

Players.PlayerRemoving:Connect(function(player)
	PlayerScores[player.UserId] = nil
end)
