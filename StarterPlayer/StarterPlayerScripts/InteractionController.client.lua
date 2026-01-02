--[[
    InteractionController (LocalScript)
    Path: StarterPlayer → StarterPlayerScripts
    Parent: StarterPlayerScripts
    Properties:
        Disabled: false
    Exported: 2026-01-02 03:27:27
]]
local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CollectionService = game:GetService("CollectionService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- 🎨 COLORS
local COLORS = {
	Use = Color3.fromRGB(0, 255, 150),      -- Green
	Sabotage = Color3.fromRGB(255, 60, 60), -- Red
	Report = Color3.fromRGB(255, 100, 50)   -- Orange
}

local activePrompt = nil
local activeHighlight = nil
local actionBtn = nil

-- 🛠️ CREATE UI
local function CreateInteractionUI()
	if playerGui:FindFirstChild("InteractionHUD") then playerGui.InteractionHUD:Destroy() end

	local screen = Instance.new("ScreenGui")
	screen.Name = "InteractionHUD"
	screen.ResetOnSpawn = false
	screen.Parent = playerGui

	local btn = Instance.new("TextButton", screen)
	btn.Name = "ActionButton"
	btn.Text = "USE"
	btn.Font = Enum.Font.GothamBlack
	btn.TextSize = 24
	btn.TextColor3 = Color3.new(0,0,0)
	btn.BackgroundColor3 = COLORS.Use
	btn.Size = UDim2.new(0.15, 0, 0.08, 0)
	btn.Position = UDim2.new(0.8, 0, 0.7, 0) 
	btn.AnchorPoint = Vector2.new(0.5, 0.5)
	btn.Visible = false

	local corner = Instance.new("UICorner", btn) corner.CornerRadius = UDim.new(0, 12)
	local stroke = Instance.new("UIStroke", btn) stroke.Thickness = 3 stroke.Color = Color3.new(1,1,1)

	return btn
end

actionBtn = CreateInteractionUI()

local function ClearHighlight()
	if activeHighlight then activeHighlight:Destroy() activeHighlight = nil end
	actionBtn.Visible = false
	activePrompt = nil
end

-- 🛡️ ROLE ENFORCER (THE FIX)
-- This runs BEFORE you even walk up to a prompt.
local function ApplyRoleFilter(prompt)
	if not prompt:IsA("ProximityPrompt") then return end

	-- Force Custom Style globally
	prompt.Style = Enum.ProximityPromptStyle.Custom

	local role = player:GetAttribute("Role")
	local isSaboteur = (role == "Saboteur")

	-- LOGIC: PRE-EMPTIVE STRIKE
	if prompt.Name == "InteractionPrompt" then
		-- Designers see Tasks. Saboteurs DO NOT.
		prompt.Enabled = not isSaboteur

	elseif prompt.Name == "SabotagePrompt" then
		-- Saboteurs see Sabotage. Designers DO NOT.
		prompt.Enabled = isSaboteur

	elseif prompt.Name == "ReportPrompt" then
		-- Everyone sees Bodies
		prompt.Enabled = true
	end
end

-- Refresh ALL prompts when role changes
local function UpdateAllPrompts()
	for _, prompt in pairs(workspace:GetDescendants()) do
		ApplyRoleFilter(prompt)
	end
end

-- Listeners for Dynamic Filtering
player:GetAttributeChangedSignal("Role"):Connect(UpdateAllPrompts)
workspace.DescendantAdded:Connect(ApplyRoleFilter) -- Handle streaming/new parts

-- Force run once on load
task.defer(UpdateAllPrompts)


-- 👁️ VISUALS ONLY (No Logic Fighting)
ProximityPromptService.PromptShown:Connect(function(prompt, inputType)
	activePrompt = prompt

	-- Determine Colors
	local color = COLORS.Use
	local text = "USE"

	if prompt.Name == "SabotagePrompt" then
		color = COLORS.Sabotage
		text = "SABOTAGE"
	elseif prompt.Name == "ReportPrompt" then
		color = COLORS.Report
		text = "REPORT BODY"
	end

	actionBtn.BackgroundColor3 = color
	actionBtn.Text = text
	actionBtn.Visible = true

	-- Highlight
	if prompt.Parent then
		if activeHighlight then activeHighlight:Destroy() end
		local h = Instance.new("Highlight")
		h.Parent = prompt.Parent
		h.FillColor = color
		h.OutlineColor = Color3.new(1,1,1)
		h.FillTransparency = 0.5
		h.OutlineTransparency = 0
		activeHighlight = h
	end
end)

ProximityPromptService.PromptHidden:Connect(function(prompt)
	if prompt == activePrompt then
		ClearHighlight()
	end
end)

-- 👆 BUTTON INPUT
actionBtn.MouseButton1Click:Connect(function()
	if activePrompt then
		activePrompt:InputHoldBegin()
		if activePrompt.HoldDuration <= 0 then
			activePrompt:InputHoldEnd()
		end
	end
end)

actionBtn.MouseButton1Down:Connect(function()
	if activePrompt and activePrompt.HoldDuration > 0 then activePrompt:InputHoldBegin() end
end)
actionBtn.MouseButton1Up:Connect(function()
	if activePrompt and activePrompt.HoldDuration > 0 then activePrompt:InputHoldEnd() end
end)