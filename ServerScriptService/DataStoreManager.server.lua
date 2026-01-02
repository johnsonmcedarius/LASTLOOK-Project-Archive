--[[
    DataStoreManager (Script)
    Path: ServerScriptService
    Parent: ServerScriptService
    Properties:
        Disabled: false
        RunContext: Enum.RunContext.Legacy
    Exported: 2026-01-02 14:59:28
]]
local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

local EconomySystem = require(ServerScriptService:WaitForChild("EconomySystem"))
local LevelManager = require(ServerScriptService:WaitForChild("LevelManager"))

local PlayerData = DataStoreService:GetDataStore("NovaeData_v1")

local function SaveData(player)
	local inv = EconomySystem.GetInventory(player)
	local spools = 0
	if player:FindFirstChild("leaderstats") then
		spools = player.leaderstats.SewingSpools.Value
	end

	local data = {
		Spools = spools,
		Level = player:GetAttribute("Level") or 1,
		XP = player:GetAttribute("XP") or 0,
		Inventory = inv
	}

	local success, err = pcall(function()
		PlayerData:SetAsync(player.UserId, data)
	end)

	if success then
		print("💾 Saved data for " .. player.Name)
	else
		warn("❌ Failed to save data: " .. tostring(err))
	end
end

local function LoadData(player)
	local success, data = pcall(function()
		return PlayerData:GetAsync(player.UserId)
	end)

	if success and data then
		print("📂 Loaded data for " .. player.Name)
		-- Restore Spools
		EconomySystem.AddSpools(player, data.Spools or 0)
		-- Restore Level
		LevelManager.SetLevel(player, data.Level or 1)
		player:SetAttribute("XP", data.XP or 0)
		-- Restore Inventory
		if data.Inventory then
			for _, item in pairs(data.Inventory) do
				EconomySystem.AddItem(player, item)
			end
		end
	else
		print("🆕 New player (or load failed): " .. player.Name)
		EconomySystem.AddSpools(player, 100) -- Starting Bonus
	end
end

Players.PlayerAdded:Connect(LoadData)
Players.PlayerRemoving:Connect(SaveData)

-- Auto-Save Loop (Every 2 mins)
task.spawn(function()
	while true do
		task.wait(120)
		for _, p in pairs(Players:GetPlayers()) do
			SaveData(p)
		end
	end
end)

return {}