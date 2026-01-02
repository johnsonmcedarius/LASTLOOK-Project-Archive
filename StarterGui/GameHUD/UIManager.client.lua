--[[
    UIManager (LocalScript)
    Path: StarterGui → GameHUD
    Parent: GameHUD
    Properties:
        Disabled: false
    Exported: 2026-01-02 14:59:28
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local gui = script.Parent
local topBar = gui:WaitForChild("TopBar")
local statusLabel = topBar:WaitForChild("StatusLabel")
local roleRevealFrame = gui:WaitForChild("RoleReveal")
local roleTitle = roleRevealFrame:WaitForChild("RoleTitle")
local roleDesc = roleRevealFrame:WaitForChild("RoleDesc")

-- VALUES
local GameState = ReplicatedStorage.Values:WaitForChild("GameState")
local TimerEnd = ReplicatedStorage.Values:WaitForChild("TimerEnd")
local Status = ReplicatedStorage.Values:WaitForChild("Status")

-- HELPER: Format Time
local function FormatTime(seconds)
	if seconds < 0 then return "00:00" end
	local m = math.floor(seconds / 60)
	local s = math.floor(seconds % 60)
	return string.format("%02d:%02d", m, s)
end

-- HELPER: Role Reveal / Update
local function ShowRole(newRole)
	local color = Color3.fromRGB(255, 255, 255)
	local desc = "Unknown"

	print("🎨 UI Updating Role to: " .. tostring(newRole))

	if newRole == "Designer" then
		color = Color3.fromRGB(0, 255, 128) -- Teal
		desc = "Complete tasks. Identify the saboteurs."
	elseif newRole == "Saboteur" then
		color = Color3.fromRGB(255, 50, 50) -- Red
		desc = "Sabotage the fashion house. Don't get caught."
	elseif newRole == "Ghost" then
		color = Color3.fromRGB(150, 255, 255) -- Blue
		desc = "You are dead. Haunt the house."
	else
		return -- Ignore "None" or "Lobby"
	end

	roleTitle.Text = string.upper(newRole)
	roleTitle.TextColor3 = color
	roleDesc.Text = desc

	-- Only animate big reveal if not Ghost (Ghosts usually get a death cam instead)
	if newRole ~= "Ghost" then
		roleRevealFrame.Visible = true
		roleRevealFrame.BackgroundTransparency = 1
		roleTitle.TextTransparency = 1
		roleDesc.TextTransparency = 1

		local fadeIn = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		TweenService:Create(roleTitle, fadeIn, {TextTransparency = 0}):Play()
		TweenService:Create(roleDesc, fadeIn, {TextTransparency = 0}):Play()

		task.delay(4, function()
			local fadeOut = TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
			TweenService:Create(roleTitle, fadeOut, {TextTransparency = 1}):Play()
			TweenService:Create(roleDesc, fadeOut, {TextTransparency = 1}):Play()
			task.wait(1)
			roleRevealFrame.Visible = false
		end)
	end
end

-- TIMER LOOP
RunService.Heartbeat:Connect(function()
	if GameState.Value == "Playing" then
		local timeLeft = TimerEnd.Value - workspace:GetServerTimeNow()
		if timeLeft < 0 then timeLeft = 0 end
		statusLabel.Text = Status.Value .. " | " .. FormatTime(timeLeft)
	else
		statusLabel.Text = Status.Value
	end
end)

-- ROLE LISTENER
player:GetAttributeChangedSignal("Role"):Connect(function()
	local role = player:GetAttribute("Role")
	task.wait(0.1) 
	ShowRole(role)
end)

-- Init
if player:GetAttribute("Role") then
	ShowRole(player:GetAttribute("Role"))
end