--[[
    VoteManager (ModuleScript)
    Path: ServerScriptService
    Parent: ServerScriptService
    Exported: 2026-01-02 14:59:28
]]
--serverscriptservice/votemanager
local VoteManager = {}

local votes = {} -- Stores: [UserId] = Target (Player Instance OR "Skip" string)

function VoteManager.StartVoting()
	votes = {} -- Clear old votes
	print("🗳️ VOTING OPEN.")
end

function VoteManager.RegisterVote(voter, target)
	-- Target can be a Player Object OR the string "Skip"
	votes[voter.UserId] = target

	local targetName = (type(target) == "string") and target or target.Name
	print("🗳️ " .. voter.Name .. " voted for: " .. targetName)
end

function VoteManager.TallyResults()
	print("📊 TALLYING VOTES...")

	local voteCounts = {}
	local maxVotes = 0
	local tied = false
	local winner = nil -- This can be a Player or "Skip"

	-- 1. Count 'em up
	for userId, target in pairs(votes) do
		-- Initialize count for this target if new
		if not voteCounts[target] then voteCounts[target] = 0 end

		voteCounts[target] += 1

		-- Check for lead
		if voteCounts[target] > maxVotes then
			maxVotes = voteCounts[target]
			winner = target
			tied = false
		elseif voteCounts[target] == maxVotes then
			tied = true
		end
	end

	-- 2. Determine Result
	if maxVotes == 0 then
		return nil, "NoVotes"
	elseif tied then
		return nil, "Tie" -- Tie = No Kill
	elseif winner == "Skip" then
		return nil, "Skipped" -- Skip Wins = No Kill
	else
		return winner, "Ejected" -- Player Wins = Kill
	end
end

return VoteManager