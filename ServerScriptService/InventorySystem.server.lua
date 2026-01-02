--[[
    InventorySystem (Script)
    Path: ServerScriptService
    Parent: ServerScriptService
    Properties:
        Disabled: false
        RunContext: Enum.RunContext.Legacy
    Exported: 2026-01-02 14:59:28
]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local InsertService = game:GetService("InsertService")

-- MODULES
local EconomySystem = require(ServerScriptService:WaitForChild("EconomySystem"))

-- EVENTS (The Fix: Create them, don't wait for them)
local Events = ReplicatedStorage:FindFirstChild("Events")
if not Events then
	Events = Instance.new("Folder", ReplicatedStorage)
	Events.Name = "Events"
end

local EquipItemEvent = Events:FindFirstChild("EquipItem") or Instance.new("RemoteEvent", Events)
EquipItemEvent.Name = "EquipItem"

local GetInvFunc = Events:FindFirstChild("GetInventoryData") or Instance.new("RemoteFunction", Events)
GetInvFunc.Name = "GetInventoryData"

-- 👗 ASSETS
local ITEM_ASSETS = {
	["Basic Scarf"] = 4969876269,    
	["Canvas Tote"] = 5163148135,
	["Stud Earrings"] = 4840547072,
	["Beanie"] = 4995322967,
	["Face Mask"] = 5063567937,
	["Designer Shades"] = 4754564567,
	["Silk Tie"] = 4684966603,
	["Gold Chain"] = 4995891436,
	["Mythic Halo"] = 5063529322,
}

print("👗 [SERVER] Inventory System Ready.")

-- 1. DATA REQUEST
function GetInvFunc.OnServerInvoke(player)
	if not EconomySystem or not EconomySystem.GetInventory then return {} end
	return EconomySystem.GetInventory(player)
end

-- 2. EQUIP LOGIC
EquipItemEvent.OnServerEvent:Connect(function(player, itemName)
	local char = player.Character
	if not char then return end

	-- Verify Ownership
	local inv = EconomySystem.GetInventory(player)
	local ownsIt = false
	for _, item in ipairs(inv) do
		if item == itemName then ownsIt = true break end
	end

	if not ownsIt then return end

	-- Clear Old
	for _, child in pairs(char:GetChildren()) do
		if child:IsA("Accessory") and child:GetAttribute("IsNovaeItem") then
			child:Destroy()
		end
	end

	-- Load New
	local assetId = ITEM_ASSETS[itemName]
	if assetId then
		local success, model = pcall(function() return InsertService:LoadAsset(assetId) end)
		if success and model then
			local accessory = model:FindFirstChildWhichIsA("Accessory")
			if accessory then
				accessory:SetAttribute("IsNovaeItem", true)
				accessory.Parent = char
				print("✨ Equipped: " .. itemName)
			end
			model:Destroy()
		else
			warn("❌ Asset Load Failed: " .. tostring(assetId))
		end
	end
end)