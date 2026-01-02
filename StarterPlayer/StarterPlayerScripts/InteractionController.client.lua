--[[
    InteractionController (LocalScript)
    Path: StarterPlayer → StarterPlayerScripts
    Parent: StarterPlayerScripts
    Properties:
        Disabled: false
    Exported: 2026-01-02 14:59:28
]]
local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

print("🔘 [CLIENT] Interaction Controller (Strict Roles) Loaded.")

-- 🎨 COLORS
local COLORS = {
	Use = Color3.fromRGB(0, 255, 150),      -- Green (Task)
	Sabotage = Color3.fromRGB(255, 60, 60), -- Red (Sabotage)
	Report = Color3.fromRGB(255, 100, 50),  -- Orange (Body)

	NormalPart = Color3.fromRGB(0, 100, 255), -- Blue (Safe State)
	TrappedPart = Color3.fromRGB(255, 0, 0),  -- Red (Trapped State)
	SuccessPart = Color3.fromRGB(0, 255, 0)   -- Green (Completed State)
}

local activePrompt = nil
local activeHighlight = nil
local actionBtn = nil

-- ============================================================================
-- 1. UI BUILDER (The Button)
-- ============================================================================
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
	btn.Position = UDim2.new(0.8, 0, 0.7, 0) -- Mobile thumb area
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

-- ============================================================================
-- 2. VISUALS (The Red Glow Logic)
-- ============================================================================
local function UpdateTrappedVisuals()
	local role = player:GetAttribute("Role")
	local isSaboteur = (role == "Saboteur")
	local taskFolder = workspace:FindFirstChild("TaskNodes")

	if not taskFolder then return end

	for _, node in pairs(taskFolder:GetChildren()) do
		if node:IsA("BasePart") then
			local isTrapped = node:GetAttribute("IsTrapped")

			-- Don't touch Green (Completed) parts
			if node.Color == COLORS.SuccessPart then 
				node.Material = Enum.Material.Plastic
				continue 
			end

			if isSaboteur then
				-- Saboteurs see the Truth
				if isTrapped then
					node.Color = COLORS.TrappedPart -- Red
					node.Material = Enum.Material.Neon -- Glow
				else
					node.Color = COLORS.NormalPart -- Blue
					node.Material = Enum.Material.Plastic
				end
			else
				-- Designers see Lies (Always Blue)
				node.Color = COLORS.NormalPart
				node.Material = Enum.Material.Plastic
			end
		end
	end
end

-- Run visuals constantly to catch updates
RunService.Heartbeat:Connect(UpdateTrappedVisuals)

-- ============================================================================
-- 3. PROMPT HANDLING (Role Filtering)
-- ============================================================================

-- Force Custom Style globally
local function SetupPrompt(prompt)
	prompt.Style = Enum.ProximityPromptStyle.Custom
end
for _, v in pairs(workspace:GetDescendants()) do if v:IsA("ProximityPrompt") then SetupPrompt(v) end end
workspace.DescendantAdded:Connect(function(v) if v:IsA("ProximityPrompt") then SetupPrompt(v) end end)

ProximityPromptService.PromptShown:Connect(function(prompt, inputType)
	local role = player:GetAttribute("Role")
	local isSaboteur = (role == "Saboteur")

	-- ⛔ HARD FILTERING (The Anti-Flicker)
	-- If Saboteur: Hide Task Prompts
	if isSaboteur and prompt.Name == "InteractionPrompt" then
		prompt.Enabled = false 
		return
	end

	-- If Designer: Hide Sabotage Prompts
	if not isSaboteur and prompt.Name == "SabotagePrompt" then
		prompt.Enabled = false
		return
	end

	-- If we survived filter, show UI
	activePrompt = prompt

	-- Determine Visuals
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

-- ============================================================================
-- 4. INPUT HANDLING (Instant Fix)
-- ============================================================================

actionBtn.MouseButton1Click:Connect(function()
	if activePrompt then
		-- Fire manually for instant prompts
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