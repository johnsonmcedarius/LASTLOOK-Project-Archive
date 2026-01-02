--[[
    RoleManager (ModuleScript)
    Path: ServerScriptService
    Parent: ServerScriptService
    Exported: 2026-01-02 14:59:28
]]
--ServerScriptServince Role Manager Script
local RoleManager = {}

local function Log(msg)
	print("🎲 [ROLE MGR] " .. msg)
end

function RoleManager.AssignRoles(players)
	Log("Rolling roles for " .. #players .. " players...")

	-- 1. Reset everyone locally
	for _, player in pairs(players) do
		player:SetAttribute("Role", "Designer") -- Default
		player:SetAttribute("IsDead", false)
		player:SetAttribute("IsGhost", false)
	end

	-- 2. Calculate Saboteur Count 
	local sabCount = 1
	if #players >= 7 then sabCount = 2 end
	if #players >= 12 then sabCount = 3 end -- Optional scaling

	Log("Assigning " .. sabCount .. " Saboteur(s).")

	-- 3. Pick Saboteurs
	local available = {unpack(players)} -- Copy table
	local count = 0

	while count < sabCount and #available > 0 do
		local index = math.random(1, #available)
		local chosenOne = available[index]

		chosenOne:SetAttribute("Role", "Saboteur")
		Log("😈 ASSIGNED SABOTEUR: " .. chosenOne.Name)

		table.remove(available, index)
		count += 1
	end

	Log("Roles Assigned Successfully.")
end

function RoleManager.CheckWinCondition()
	-- only log if state changes
	local designers = 0
	local saboteurs = 0

	for _, player in pairs(game.Players:GetPlayers()) do
		if not player:GetAttribute("IsDead") then
			local role = player:GetAttribute("Role")
			if role == "Saboteur" then
				saboteurs += 1
			else
				designers += 1
			end
		end
	end

	-- LOGIC
	if saboteurs == 0 then
		return "DesignersWin"
	elseif saboteurs >= designers then
		return "SaboteursWin"
	end

	return "Ongoing"
end

return RoleManager