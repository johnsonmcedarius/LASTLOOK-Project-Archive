--[[
    LevelManager (Script)
    Path: ServerScriptService
    Parent: ServerScriptService
    Properties:
        Disabled: false
        RunContext: Enum.RunContext.Legacy
    Exported: 2026-01-02 03:27:27
]]
local Players = game:GetService("Players")

-- CONFIG
local XP_PER_LEVEL = 100 
local MAX_LEVEL = 999 
local MOCK_STARTING_LEVEL = 1 

-- 📊 RANK DEFINITIONS
local RANKS = {
	{Min=1,   Max=50,  Title="Design Intern",       Color=Color3.fromRGB(150, 150, 150)}, 
	{Min=51,  Max=100, Title="Junior Stylist",      Color=Color3.fromRGB(255, 253, 240)}, 
	{Min=101, Max=200, Title="Lead Tailor",         Color=Color3.fromRGB(100, 200, 255)}, 
	{Min=201, Max=300, Title="Atelier Associate",   Color=Color3.fromRGB(180, 100, 255)}, 
	{Min=301, Max=400, Title="Runway Specialist",   Color=Color3.fromRGB(255, 80, 80)},   
	{Min=401, Max=500, Title="House Icon",          Color=Color3.fromRGB(255, 215, 0)},   
	{Min=501, Max=9999,Title="Creative Director",   Color=Color3.fromRGB(0, 0, 0)}        
}

local function GetRankData(level)
	for _, rank in ipairs(RANKS) do
		if level >= rank.Min and level <= rank.Max then
			return rank
		end
	end
	return RANKS[1] -- Default
end

local function UpdatePlayerRank(player, level)
	local data = GetRankData(level)
	player:SetAttribute("RankName", data.Title)
	player:SetAttribute("RankColor", data.Color)
	print("⭐ RANK UPDATE: " .. player.Name .. " is now " .. data.Title)
end

local function OnPlayerAdded(player)
	-- Leaderstats
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then
		leaderstats = Instance.new("Folder")
		leaderstats.Name = "leaderstats"
		leaderstats.Parent = player
	end

	if not leaderstats:FindFirstChild("Level") then
		local lvl = Instance.new("IntValue")
		lvl.Name = "Level"
		lvl.Value = MOCK_STARTING_LEVEL
		lvl.Parent = leaderstats
	end

	-- Attributes
	player:SetAttribute("Level", MOCK_STARTING_LEVEL)
	player:SetAttribute("XP", 0)

	UpdatePlayerRank(player, MOCK_STARTING_LEVEL)
end

-- EXPORTED FUNCTIONS
local Exported = {}

function Exported.AddXP(player, amount)
	if not player then return end
	local currentXP = player:GetAttribute("XP") or 0
	local currentLevel = player:GetAttribute("Level") or 1

	local newXP = currentXP + amount
	if newXP >= XP_PER_LEVEL then
		local nextLevel = math.min(currentLevel + 1, MAX_LEVEL)
		player:SetAttribute("Level", nextLevel)
		player:SetAttribute("XP", newXP - XP_PER_LEVEL)

		-- Update Leaderstats
		local stats = player:FindFirstChild("leaderstats")
		if stats and stats:FindFirstChild("Level") then
			stats.Level.Value = nextLevel
		end

		UpdatePlayerRank(player, nextLevel)
	else
		player:SetAttribute("XP", newXP)
	end
end

-- 🚨 NEW FUNCTION FOR DEV COMMANDS
function Exported.SetLevel(player, level)
	if not player then return end
	level = math.clamp(level, 1, MAX_LEVEL)

	player:SetAttribute("Level", level)
	player:SetAttribute("XP", 0)

	-- Sync Leaderstats
	local stats = player:FindFirstChild("leaderstats")
	if stats and stats:FindFirstChild("Level") then
		stats.Level.Value = level
	end

	-- Force Rank Update
	UpdatePlayerRank(player, level)
end

Players.PlayerAdded:Connect(OnPlayerAdded)
for _, p in ipairs(Players:GetPlayers()) do OnPlayerAdded(p) end

_G.LevelManager = Exported
return Exported