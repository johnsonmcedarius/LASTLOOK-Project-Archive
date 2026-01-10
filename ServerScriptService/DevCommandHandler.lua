-- -------------------------------------------------------------------------------
-- 📂 PROJECT: LAST LOOK
-- 📝 SCRIPT: DevCommandHandler (Server - RESTRICTED ACCESS & FIXED LISTENER)
-- 🛠️ AUTH: Coding Partner
-- 💡 DESC: Extended Chat commands for testing game flow, roles, and stats.
-- -------------------------------------------------------------------------------

local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextChatService = game:GetService("TextChatService")

-- // MODULES
local DataManager = require(game.ServerScriptService.DataManager)

-- // CONFIG
local ADMIN_IDS = {
	[6028913754] = true, -- Your ID
	-- Add other dev IDs here like: [12345678] = true,
}

-- // EVENTS
local ForceStartEvent = ServerStorage:FindFirstChild("DevForceStart")
if not ForceStartEvent then
	ForceStartEvent = Instance.new("BindableEvent")
	ForceStartEvent.Name = "DevForceStart"
	ForceStartEvent.Parent = ServerStorage
end

local TriggerEndGame = ServerStorage:FindFirstChild("TriggerEndGame")
if not TriggerEndGame then
	TriggerEndGame = Instance.new("BindableEvent")
	TriggerEndGame.Name = "TriggerEndGame"
	TriggerEndGame.Parent = ServerStorage
end

local AddXPBindable = ServerStorage:FindFirstChild("AddXP")

-- // COMMAND LOGIC
local COMMANDS = {
	-- GAME FLOW
	["/start"] = function(player, args)
		print("⚡ DEV: Forcing Game Start...")
		ForceStartEvent:Fire()
		return "Game Start Triggered!"
	end,
	
	["/win"] = function(player, args)
		local winner = (args[2] and string.lower(args[2]) == "survivor") and "Designer" or "Saboteur"
		print("⚡ DEV: Forcing Win for " .. winner)
		TriggerEndGame:Fire(winner)
		return "Forced Round End: " .. winner .. " Wins!"
	end,
	
	-- ROLES
	["/survivor"] = function(player, args)
		player:SetAttribute("Role", "Designer")
		player:LoadCharacter()
		return "Role set to Designer (Respawning...)"
	end,
	
	["/killer"] = function(player, args)
		player:SetAttribute("Role", "Saboteur")
		player:LoadCharacter()
		return "Role set to Saboteur (Respawning...)"
	end,
	
	-- STATS
	["/speed"] = function(player, args)
		local amount = tonumber(args[2]) or 16
		local hum = player.Character and player.Character:FindFirstChild("Humanoid")
		if hum then
			hum.WalkSpeed = amount
			player:SetAttribute("IsSprinting", true) 
			return "Speed set to " .. amount
		end
		return "Character not found."
	end,
	
	["/god"] = function(player, args)
		local state = player:GetAttribute("HealthState")
		if state == "God" then
			player:SetAttribute("HealthState", "Healthy")
			return "God Mode OFF"
		else
			player:SetAttribute("HealthState", "God")
			return "God Mode ON (Invincible)"
		end
	end,
	
	["/hurt"] = function(player, args)
		player:SetAttribute("HealthState", "Injured")
		return "Set HealthState to Injured"
	end,
	
	["/down"] = function(player, args)
		player:SetAttribute("HealthState", "Downed")
		return "Set HealthState to Downed"
	end,
	
	["/heal"] = function(player, args)
		player:SetAttribute("HealthState", "Healthy")
		return "Set HealthState to Healthy"
	end,
	
	-- ECONOMY & PROGRESSION
	["/xp"] = function(player, args)
		local amount = tonumber(args[2]) or 1000
		if AddXPBindable then
			AddXPBindable:Fire(player, amount)
			return "Added " .. amount .. " XP"
		else
			return "Error: AddXP Bindable not found."
		end
	end,
	
	["/spools"] = function(player, args)
		local amount = tonumber(args[2]) or 1000
		local newTotal = DataManager:AdjustSpools(player, amount)
		return "Added " .. amount .. " Spools. Total: " .. (newTotal or "?")
	end,
	
	-- UTILITY
	["/tp"] = function(player, args)
		local location = args[2]
		local spawns
		if location == "map" then
			spawns = workspace:FindFirstChild("MapSpawns")
		else
			spawns = workspace:FindFirstChild("LobbySpawns")
		end
		
		if spawns and player.Character then
			local t = spawns:GetChildren()
			if #t > 0 then
				local s = t[math.random(1, #t)]
				player.Character:PivotTo(s.CFrame + Vector3.new(0,5,0))
				return "Teleported to " .. location
			end
		end
		return "Spawn location not found."
	end
}

-- // CHAT HANDLING (Fixed: Uses Player.Chatted)
local function onPlayerAdded(player)
	player.Chatted:Connect(function(text)
		-- 1. Check Admin Access
		if not ADMIN_IDS[player.UserId] then return end
		
		-- 2. Check if command
		if string.sub(text, 1, 1) ~= "/" then return end
		
		local args = string.split(text, " ")
		local cmd = string.lower(args[1])
		
		if COMMANDS[cmd] then
			local success, response = pcall(function()
				return COMMANDS[cmd](player, args)
			end)
			
			if not success then
				warn("Command Error: " .. tostring(response))
				response = "Error executing command."
			end
			
			-- 3. Feedback (System Message via TextChatService)
			-- This sends a message only the specific player can see
			local channel = TextChatService:FindFirstChild("TextChannels") and TextChatService.TextChannels:FindFirstChild("RBXGeneral")
			if channel then
				channel:DisplaySystemMessage(string.format("<font color='#FFD700'>[DEV] %s</font>", response or "Done."))
			end
		end
	end)
end

-- Hook up existing and future players
for _, p in pairs(Players:GetPlayers()) do
	onPlayerAdded(p)
end
Players.PlayerAdded:Connect(onPlayerAdded)
