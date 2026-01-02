--[[
    VotingController (LocalScript)
    Path: StarterPlayer → StarterPlayerScripts
    Parent: StarterPlayerScripts
    Properties:
        Disabled: false
    Exported: 2026-01-02 14:59:28
]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local camera = Workspace.CurrentCamera

-- EVENTS & VALUES
local Events = ReplicatedStorage:WaitForChild("Events")
local SubmitVote = Events:WaitForChild("SubmitVote")
local GameState = ReplicatedStorage:WaitForChild("Values"):WaitForChild("GameState")

-- STATE
local gui = nil
local candidates = {} -- List of players to look at
local currentIndex = 1
local hasVoted = false

-- 🎨 UI BUILDER
local function CreateVotingUI()
	if gui then gui:Destroy() end

	local screen = Instance.new("ScreenGui")
	screen.Name = "VotingHUD"
	screen.IgnoreGuiInset = true
	screen.ResetOnSpawn = false
	screen.Parent = playerGui
	gui = screen

	-- 1. CONTROLS CONTAINER (Bottom)
	local controls = Instance.new("Frame", screen)
	controls.Size = UDim2.new(0.6, 0, 0.2, 0)
	controls.Position = UDim2.new(0.5, 0, 0.85, 0)
	controls.AnchorPoint = Vector2.new(0.5, 0.5)
	controls.BackgroundTransparency = 1

	-- Prev Button
	local prev = Instance.new("TextButton", controls)
	prev.Text = "<"
	prev.Font = Enum.Font.GothamBlack
	prev.TextSize = 40
	prev.TextColor3 = Color3.new(1,1,1)
	prev.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	prev.Size = UDim2.new(0.15, 0, 0.8, 0)
	prev.Position = UDim2.new(0, 0, 0.1, 0)
	local pc = Instance.new("UICorner", prev) pc.CornerRadius = UDim.new(0, 16)

	-- Next Button
	local nextBtn = Instance.new("TextButton", controls)
	nextBtn.Text = ">"
	nextBtn.Font = Enum.Font.GothamBlack
	nextBtn.TextSize = 40
	nextBtn.TextColor3 = Color3.new(1,1,1)
	nextBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	nextBtn.Size = UDim2.new(0.15, 0, 0.8, 0)
	nextBtn.Position = UDim2.new(0.85, 0, 0.1, 0)
	local nc = Instance.new("UICorner", nextBtn) nc.CornerRadius = UDim.new(0, 16)

	-- Name Label
	local nameLabel = Instance.new("TextLabel", controls)
	nameLabel.Name = "CandidateName"
	nameLabel.Text = "LOADING..."
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextSize = 24
	nameLabel.TextColor3 = Color3.fromRGB(255, 215, 0) -- Gold
	nameLabel.Size = UDim2.new(0.6, 0, 0.5, 0)
	nameLabel.Position = UDim2.new(0.2, 0, 0, 0)
	nameLabel.BackgroundTransparency = 1

	-- Accuse Button
	local accuseBtn = Instance.new("TextButton", controls)
	accuseBtn.Name = "AccuseButton"
	accuseBtn.Text = "ACCUSE"
	accuseBtn.Font = Enum.Font.GothamBlack
	accuseBtn.TextSize = 24
	accuseBtn.TextColor3 = Color3.new(0,0,0)
	accuseBtn.BackgroundColor3 = Color3.fromRGB(255, 50, 50) -- Red
	accuseBtn.Size = UDim2.new(0.4, 0, 0.5, 0)
	accuseBtn.Position = UDim2.new(0.3, 0, 0.5, 0)
	local ac = Instance.new("UICorner", accuseBtn) ac.CornerRadius = UDim.new(0, 8)

	-- Skip Button (Top Right)
	local skipBtn = Instance.new("TextButton", screen)
	skipBtn.Text = "SKIP VOTE ⏭️"
	skipBtn.Font = Enum.Font.GothamBold
	skipBtn.TextSize = 18
	skipBtn.TextColor3 = Color3.new(1,1,1)
	skipBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
	skipBtn.Size = UDim2.new(0.15, 0, 0.08, 0)
	skipBtn.Position = UDim2.new(0.82, 0, 0.05, 0)
	local sc = Instance.new("UICorner", skipBtn) sc.CornerRadius = UDim.new(0, 8)

	return prev, nextBtn, accuseBtn, skipBtn, nameLabel
end

-- 📸 CAMERA LOGIC
local function UpdateCamera()
	local target = candidates[currentIndex]
	local nameLabel = gui:FindFirstChild("CandidateName", true)
	local accuseBtn = gui:FindFirstChild("AccuseButton", true)

	if target and target.Character then
		local head = target.Character:FindFirstChild("Head")
		if head then
			-- Cinematic Angle
			local camPos = head.Position + (head.CFrame.LookVector * 4) + Vector3.new(0, 0.5, 0)
			local newCF = CFrame.new(camPos, head.Position)

			TweenService:Create(camera, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				CFrame = newCF
			}):Play()

			-- Update UI
			if nameLabel then nameLabel.Text = string.upper(target.Name) end

			-- Disable vote if self or dead
			if accuseBtn then
				if target == player or target:GetAttribute("IsDead") then
					accuseBtn.Visible = false
					nameLabel.Text = nameLabel.Text .. " (UNAVAILABLE)"
				else
					accuseBtn.Visible = true
				end
			end
		end
	end
end

local function Cycle(dir)
	currentIndex += dir
	if currentIndex > #candidates then currentIndex = 1 end
	if currentIndex < 1 then currentIndex = #candidates end
	UpdateCamera()
end

-- 🏁 START/STOP
local function StartVotingSession()
	hasVoted = false
	candidates = {}

	-- Build list of everyone sitting
	for _, p in pairs(Players:GetPlayers()) do
		table.insert(candidates, p)
	end

	-- Setup UI
	local prev, nextBtn, accuse, skip, lbl = CreateVotingUI()
	camera.CameraType = Enum.CameraType.Scriptable

	-- Bindings
	prev.MouseButton1Click:Connect(function() Cycle(-1) end)
	nextBtn.MouseButton1Click:Connect(function() Cycle(1) end)

	accuse.MouseButton1Click:Connect(function()
		if hasVoted then return end
		hasVoted = true
		SubmitVote:FireServer(candidates[currentIndex])
		accuse.Text = "VOTED"
		accuse.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	end)

	skip.MouseButton1Click:Connect(function()
		if hasVoted then return end
		hasVoted = true
		SubmitVote:FireServer("Skip")
		skip.Text = "SKIPPED"
		accuse.Visible = false
	end)

	-- Init Camera
	UpdateCamera()
end

local function EndVotingSession()
	if gui then gui:Destroy() end
	camera.CameraType = Enum.CameraType.Custom
	-- Reset subject to self
	if player.Character then
		camera.CameraSubject = player.Character:FindFirstChild("Humanoid")
	end
end

-- 📡 LISTENER
GameState.Changed:Connect(function(state)
	if state == "Meeting" then
		task.wait(1) -- Wait for teleport to finish
		StartVotingSession()
	elseif state == "Playing" or state == "GameOver" then
		EndVotingSession()
	end
end)