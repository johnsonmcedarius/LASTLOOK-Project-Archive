--[[
    VotingController (LocalScript)
    Path: StarterGui → GameHUD → MeetingHUD
    Parent: MeetingHUD
    Properties:
        Disabled: false
    Exported: 2026-01-02 14:59:28
]]
-- StarterGui/GameHUD/MeetingHUD/VotingController
-- 🔓 SMARTER CLICK DEBUG VERSION
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local mouse = player:GetMouse()
local camera = workspace.CurrentCamera

-- UI REFERENCES
local meetingHUD = script.Parent
local confirmBtn = meetingHUD:WaitForChild("ConfirmButton")
local skipBtn = meetingHUD:WaitForChild("SkipButton")

-- ASSETS & EVENTS
local ASSETS = ReplicatedStorage:WaitForChild("Assets")
local HighlightTemplate = ASSETS:WaitForChild("SelectionHighlight")
local GameState = ReplicatedStorage.Values:WaitForChild("GameState")
local SubmitVote = ReplicatedStorage.Events:WaitForChild("SubmitVote")
local EjectionReveal = ReplicatedStorage.Events:WaitForChild("EjectionReveal")

-- STATE
local selectedPlayer = nil
local currentHighlight = nil
local isVotingOpen = false

-- 🔦 HIGHLIGHT HELPER
local function HighlightChar(char)
	if currentHighlight then currentHighlight:Destroy() end

	if char then
		currentHighlight = HighlightTemplate:Clone()
		currentHighlight.Parent = char
		currentHighlight.Adornee = char
	end
end

-- 🕵️‍♂️ SMART CHARACTER FINDER
local function FindCharacterFromPart(part)
	if not part then return nil end

	-- 1. Check if the part itself is inside a Character model
	local model = part:FindFirstAncestorOfClass("Model")
	if model and model:FindFirstChild("Humanoid") then
		return model
	end

	-- 2. Check if we clicked a Seat that has a occupant
	if part:IsA("Seat") or part:IsA("VehicleSeat") then
		if part.Occupant then
			return part.Occupant.Parent -- The Character sitting there
		end
	end

	return nil
end

-- 🎯 CLICK LOGIC
UserInputService.InputBegan:Connect(function(input, processed)
	if not isVotingOpen then return end
	if processed then return end 

	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		local target = mouse.Target
		if target then
			print("🖱️ You clicked: " .. target.Name) -- DEBUG PRINT

			local char = FindCharacterFromPart(target)

			if char then
				local clickedPlayer = Players:GetPlayerFromCharacter(char)

				-- 🔓 DEBUG: Allow selecting ANYONE (even yourself/ghosts)
				if clickedPlayer then
					selectedPlayer = clickedPlayer
					HighlightChar(char)
					confirmBtn.Text = "CONFIRM VOTE: " .. clickedPlayer.Name:upper()
					confirmBtn.BackgroundColor3 = Color3.fromRGB(255, 170, 0) -- Gold
				end
			else
				print("❌ That is not a player.")
			end
		end
	end
end)

-- ✅ CONFIRM BUTTON
confirmBtn.MouseButton1Click:Connect(function()
	if selectedPlayer then
		confirmBtn.Text = "VOTE LOCKED"
		confirmBtn.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
		isVotingOpen = false 
		SubmitVote:FireServer(selectedPlayer)
		HighlightChar(nil) 
	else
		confirmBtn.Text = "SELECT A PLAYER FIRST"
	end
end)

-- ⏭️ SKIP BUTTON
skipBtn.MouseButton1Click:Connect(function()
	confirmBtn.Text = "SKIPPED"
	isVotingOpen = false
	SubmitVote:FireServer("Skip")
	HighlightChar(nil)
end)

-- 🎥 CINEMATIC CAMERA ZOOM
EjectionReveal.OnClientEvent:Connect(function(victim)
	if victim and victim.Character then
		local char = victim.Character
		local head = char:FindFirstChild("Head")
		if head then
			camera.CameraType = Enum.CameraType.Scriptable
			local targetCFrame = CFrame.new(head.Position + (head.CFrame.LookVector * 5) + Vector3.new(0, 2, 0), head.Position)
			local tweenInfo = TweenInfo.new(1.5, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out)
			TweenService:Create(camera, tweenInfo, {CFrame = targetCFrame}):Play()
		end
	end
end)

-- 👂 GAME STATE LISTENER
GameState.Changed:Connect(function(newState)
	if newState == "Meeting" then
		meetingHUD.Visible = true
		isVotingOpen = true
		confirmBtn.Text = "SELECT A PLAYER"
		confirmBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
		skipBtn.Visible = true
		selectedPlayer = nil
	elseif newState == "Playing" then
		meetingHUD.Visible = false
		isVotingOpen = false
		HighlightChar(nil)
		camera.CameraType = Enum.CameraType.Custom
	end
end)