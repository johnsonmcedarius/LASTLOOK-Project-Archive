-- -------------------------------------------------------------------------------
-- 📂 PROJECT: LAST LOOK
-- 📝 SCRIPT: MapAuditor (Server)
-- 🛠️ AUTH: Novae Studios
-- 💡 DESC: Dev Tool. Checks Map for missing Tags/Parts before round starts.
-- -------------------------------------------------------------------------------

local CollectionService = game:GetService("CollectionService")

local function audit()
	print("🔍 STARTING MAP AUDIT...")
	local errors = 0
	
	-- 1. CHECK STATIONS
	local stations = CollectionService:GetTagged("Station")
	if #stations < 5 then
		warn("⚠️ CRITICAL: Less than 5 Stations found! Found: " .. #stations)
		errors += 1
	end
	
	for _, s in pairs(stations) do
		if not s.PrimaryPart then
			warn("⚠️ Station " .. s.Name .. " missing PrimaryPart!")
			errors += 1
		end
		if not s:FindFirstChild("StatusLight") then
			warn("⚠️ Station " .. s.Name .. " missing 'StatusLight' part!")
			errors += 1
		end
	end
	
	-- 2. CHECK EXITS
	local exits = CollectionService:GetTagged("ExitGate")
	if #exits < 1 then
		warn("⚠️ CRITICAL: No Exit Gates found!")
		errors += 1
	end
	
	for _, e in pairs(exits) do
		if not e:FindFirstChild("WinZone") then
			warn("⚠️ Exit " .. e.Name .. " missing 'WinZone'!")
			errors += 1
		end
	end
	
	-- 3. CHECK MANNEQUINS
	local mannequins = CollectionService:GetTagged("MannequinStand")
	if #mannequins < 4 then
		warn("⚠️ Low Mannequin Count! Found: " .. #mannequins)
	end
	
	if errors == 0 then
		print("✅ MAP AUDIT PASSED. READY FOR RUNWAY.")
	else
		print("❌ MAP AUDIT FAILED WITH " .. errors .. " ERRORS.")
	end
end

-- Run once on startup
task.delay(5, audit)