-- -------------------------------------------------------------------------------
-- 📂 PROJECT: LAST LOOK
-- 📝 SCRIPT: SpectatorController (Client - 2v8 UPDATE)
-- 🛠️ AUTH: Novae Studios
-- 💡 DESC: Handles Spectator Cam. Hides ALL Saboteurs.
-- -------------------------------------------------------------------------------

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")

local Player = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local isSpectating = false
local targets = {}
local currentIndex = 1

local SpectateHUD = nil
local NameLabel = nil

local function setupSpectatorUI()
	local screen = Instance.new("ScreenGui")
	screen.Name = "SpectatorHUD"
	screen.ResetOnSpawn = false
	screen.Parent = Player:WaitForChild("PlayerGui")
	
	local label = Instance.new("TextLabel")
	label.Name = "TargetName"
	label.Text = "SPECTATING"
	label.Font = Enum.Font.GothamBold 
	label.TextColor3 = Color3.fromRGB(255, 215, 0) 
	label.TextSize = 24
	label.Size = UDim2.fromScale(1, 0.1)
	label.Position = UDim2.fromScale(0, 0.85)
	label.BackgroundTransparency = 1
	label.Visible = false
	label.Parent = screen
	
	NameLabel = label
	SpectateHUD = screen
end

local function refreshTargets()
	targets = {}
	for _, p in pairs(Players:GetPlayers()) do
		if p ~= Player then
			-- [UPDATED] ANTI-CHEAT: Hide ANY Saboteur
			local role = p:GetAttribute("Role")
			if role ~= "Saboteur" then
				local state = p:GetAttribute("HealthState")
				if state ~= "Scrapped" and state ~= "Escaped" then
					table.insert(targets, p)
				end
			end
		end
	end
end

local function updateCam()
	if #targets == 0 then
		Camera.CameraSubject = nil
		if NameLabel then NameLabel.Text = "NO TARGETS AVAILABLE" end
		return
	end
	
	if currentIndex > #targets then currentIndex = 1 end
	if currentIndex < 1 then currentIndex = #targets end
	
	local targetPlayer = targets[currentIndex]
	if targetPlayer and targetPlayer.Character then
		local hum = targetPlayer.Character:FindFirstChild("Humanoid")
		if hum then
			Camera.CameraSubject = hum
			if NameLabel then NameLabel.Text = "WATCHING: " .. string.upper(targetPlayer.Name) end
		end
	end
end

local function cycle(actionName, inputState)
	if inputState == Enum.UserInputState.Begin then
		if actionName == "NextCam" then
			currentIndex += 1
		elseif actionName == "PrevCam" then
			currentIndex -= 1
		end
		updateCam()
	end
end

RunService.Heartbeat:Connect(function()
	local myState = Player:GetAttribute("HealthState")
	
	if (myState == "Scrapped" or myState == "Escaped") and not isSpectating then
		isSpectating = true
		if not SpectateHUD then setupSpectatorUI() end
		NameLabel.Visible = true
		
		refreshTargets()
		updateCam()
		
		ContextActionService:BindAction("NextCam", cycle, true, Enum.KeyCode.E, Enum.KeyCode.ButtonR1)
		ContextActionService:BindAction("PrevCam", cycle, true, Enum.KeyCode.Q, Enum.KeyCode.ButtonL1)
		
		task.spawn(function()
			while isSpectating do
				refreshTargets()
				task.wait(2)
			end
		end)
	end
end)
