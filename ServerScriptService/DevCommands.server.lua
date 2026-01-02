--[[
    DevCommands (Script)
    Path: ServerScriptService
    Parent: ServerScriptService
    Properties:
        Disabled: false
        RunContext: Enum.RunContext.Legacy
    Exported: 2026-01-02 03:27:27
]]
local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

-- MODULES & VALUES
local CorpseController = require(ServerScriptService:WaitForChild("CorpseController"))
local EconomySystem = require(ServerScriptService:WaitForChild("EconomySystem"))

local ChaosLevel = ReplicatedStorage:WaitForChild("Values"):WaitForChild("ChaosLevel")
local GameState = ReplicatedStorage:WaitForChild("Values"):WaitForChild("GameState")
local TaskProgress = ReplicatedStorage:WaitForChild("Values"):WaitForChild("TaskProgress")
local TotalTasksNeeded = ReplicatedStorage.Values:WaitForChild("TotalTasksNeeded")

-- EVENTS
local Events = ReplicatedStorage:WaitForChild("Events")
local EjectionReveal = Events:WaitForChild("EjectionReveal")
local BodyReportedEvent = Events:WaitForChild("BodyReported")

-- INTERNAL EVENTS (For controlling GameLoop)
local ServerEvents = ServerStorage:FindFirstChild("Events") or Instance.new("Folder", ServerStorage)
if ServerEvents.Name ~= "Events" then ServerEvents.Name = "Events" end

local ForceStartEvent = ServerEvents:FindFirstChild("ForceStart") or Instance.new("BindableEvent", ServerEvents)
ForceStartEvent.Name = "ForceStart"

-- 🛡️ SECURITY LIST (UPDATED)
local ADMINS = {
	[6028913754] = true, -- Cedarius
	[98007134] = true,   -- Dewayne
	-- [0] = true, -- Uncomment for Local Studio Test Server
}

print("🛠️ Dev Commands v5 Loaded. IDs Registered.")

Players.PlayerAdded:Connect(function(player)
	player.Chatted:Connect(function(msg)
		if not ADMINS[player.UserId] then return end

		local args = string.split(msg, " ")
		local cmd = string.lower(args[1])

		-- 🚀 COMMAND: /start (Skip Lobby)
		if cmd == "/start" then
			print("🚀 DEV: Forcing Game Start...")
			ForceStartEvent:Fire()
		end

		-- 🏃 COMMAND: /speed [num]
		if cmd == "/speed" and args[2] then
			local val = tonumber(args[2])
			if val and player.Character and player.Character:FindFirstChild("Humanoid") then
				player.Character.Humanoid.WalkSpeed = val
				print("🏃 Speed set to " .. val)
			end
		end

		-- 🐇 COMMAND: /jump [num]
		if cmd == "/jump" and args[2] then
			local val = tonumber(args[2])
			if val and player.Character and player.Character:FindFirstChild("Humanoid") then
				player.Character.Humanoid.UseJumpPower = true
				player.Character.Humanoid.JumpPower = val
				print("🐇 Jump set to " .. val)
			end
		end

		-- 📷 COMMAND: /fixcam (Emergency Camera Reset)
		if cmd == "/fixcam" then
			-- We have to tell the client to do this via Remote
			-- (You can add a simple remote listener on client, or just respawn)
			player:LoadCharacter() 
			print("📷 Respawned to fix camera.")
		end

		-- 💰 /cash [amount]
		if cmd == "/cash" and args[2] then
			local amount = tonumber(args[2])
			if amount then
				EconomySystem.AddSpools(player, amount)
				print("🤑 DEV: Gave " .. amount .. " Spools")
			end
		end

		-- 🎁 /give [Item Name]
		if cmd == "/give" then
			local itemName = table.concat(args, " ", 2)
			if itemName and itemName ~= "" then
				EconomySystem.AddItem(player, itemName)
				print("🎁 DEV: Gave item '" .. itemName .. "'")
			end
		end

		-- 💀 /die
		if cmd == "/die" then
			CorpseController.Spawn(player)
			player:SetAttribute("IsDead", true)
			player:SetAttribute("Role", "Ghost")
			local char = player.Character
			if char then
				if _G.CollisionManager then _G.CollisionManager.SetGhost(char) end
				for _, part in pairs(char:GetDescendants()) do
					if part:IsA("BasePart") then
						part.Massless = true
						part.CanCollide = true 
						if part.Name == "HumanoidRootPart" then part.Transparency = 1 end
					end
				end
			end
		end

		-- ✂️ /eject
		if cmd == "/eject" then
			EjectionReveal:FireAllClients(player)
			task.wait(3)
			local char = player.Character
			if char then char:BreakJoints() end
			player:SetAttribute("IsDead", true)
			player:SetAttribute("Role", "Ghost")
		end

		-- 🚨 /meeting
		if cmd == "/meeting" then
			BodyReportedEvent:Fire(player)
		end

		-- 📍 /tp [lobby/meeting]
		if cmd == "/tp" and args[2] then
			local loc = string.lower(args[2])
			local targetCF = nil
			if loc == "lobby" and workspace.Spawns:FindFirstChild("Lobby") then
				targetCF = workspace.Spawns.Lobby:GetChildren()[1].CFrame + Vector3.new(0,5,0)
			elseif loc == "meeting" and workspace:FindFirstChild("MeetingTable") then
				targetCF = workspace.MeetingTable:GetChildren()[1].CFrame + Vector3.new(0,5,0)
			end
			if targetCF and player.Character then
				player.Character:SetPrimaryPartCFrame(targetCF)
			end
		end

		-- 😇 /revive
		if cmd == "/revive" then
			player:SetAttribute("IsDead", false)
			player:LoadCharacter()
		end

		-- 😈 /sab
		if cmd == "/sab" then player:SetAttribute("Role", "Saboteur") end

		-- 👗 /des
		if cmd == "/des" then player:SetAttribute("Role", "Designer") end

		-- 📉 /chaos [num]
		if cmd == "/chaos" and args[2] then
			local val = tonumber(args[2])
			if val then ChaosLevel.Value = math.clamp(val, 0, 100) end
		end

		-- 📈 /level [num]
		if cmd == "/level" and args[2] then
			local lvl = tonumber(args[2])
			if lvl and _G.LevelManager then _G.LevelManager.SetLevel(player, lvl) end
		end

		-- 🏆 /win [sab/des]
		if cmd == "/win" then
			local team = string.lower(args[2] or "")
			if team == "sab" then ChaosLevel.Value = 100 
			elseif team == "des" then TaskProgress.Value = TotalTasksNeeded.Value end
		end
	end)
end)