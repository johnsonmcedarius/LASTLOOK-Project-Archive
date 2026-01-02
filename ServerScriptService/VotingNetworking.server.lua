--[[
    VotingNetworking (Script)
    Path: ServerScriptService
    Parent: ServerScriptService
    Properties:
        Disabled: false
        RunContext: Enum.RunContext.Legacy
    Exported: 2026-01-02 03:27:27
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

-- MODULES
-- Ensure VoteManager exists in ServerScriptService (you pasted it in the prompt before!)
local VoteManager = require(ServerScriptService:WaitForChild("VoteManager"))

-- EVENTS
local Events = ReplicatedStorage:WaitForChild("Events")
local SubmitVoteEvent = Events:FindFirstChild("SubmitVote") or Instance.new("RemoteEvent", Events)
SubmitVoteEvent.Name = "SubmitVote"

print("🗳️ Voting Networking Connected.")

-- LISTENER
SubmitVoteEvent.OnServerEvent:Connect(function(player, target)
	-- Target can be a Player Instance OR string "Skip"
	print("📨 Vote received from " .. player.Name)
	VoteManager.RegisterVote(player, target)
end)