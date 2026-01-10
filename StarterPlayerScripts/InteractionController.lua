-- -------------------------------------------------------------------------------
-- 📂 PROJECT: LAST LOOK
-- 📝 SCRIPT: InteractionController (Client - VISUALS UPDATE)
-- 🛠️ AUTH: Novae Studios
-- 💡 DESC: Adapts UI text & Highlights 3D targets (Glows).
-- -------------------------------------------------------------------------------

local Players = game:GetService("Players")
local ContextActionService = game:GetService("ContextActionService")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Player = Players.LocalPlayer
local InteractionRemote = ReplicatedStorage:WaitForChild("InteractionEvent")

-- // STATE
local currentTarget = nil
local currentHighlight = nil -- The glowing effect
local lastText = ""
local canInteract = false

-- // UI REFS
local PlayerGui = Player:WaitForChild("PlayerGui")
local HUD = PlayerGui:WaitForChild("InteractionHUD")
local ActionButton = HUD:WaitForChild("ActionButton")
HUD.Enabled = true
ActionButton.Visible = false

-- // CONFIG COLORS (Updated for Visuals)
local COL_USE = Color3.fromRGB(0, 255, 120)     -- Green (Tasks)
local COL_RESCUE = Color3.fromRGB(255, 50, 50)  -- Red (Rescue)
local COL_LOCKED = Color3.fromRGB(150, 150, 150)-- Gray (Locked Door)
local COL_ESCAPE = Color3.fromRGB(50, 255, 255) -- Cyan (Open Door)

-- // HELPER: Get Context
local function getContext(obj)
	if CollectionService:HasTag(obj, "Station") then
		return "USE", COL_USE, true
		
	elseif CollectionService:HasTag(obj, "MannequinStand") then
		return "RESCUE", COL_RESCUE, true
		
	elseif CollectionService:HasTag(obj, "ExitGate") then
		local powered = workspace:GetAttribute("ExitPowered") == true
		if powered then
			return "ESCAPE", COL_ESCAPE, true
		else
			return "LOCKED", COL_LOCKED, false -- False = Cannot interact
		end
	end
	
	return "INTERACT", Color3.fromRGB(255, 255, 255), true
end

-- // HELPER: Manage Highlight
local function updateHighlight(target, color)
	-- If we switched targets, destroy the old glow
	if currentHighlight and currentHighlight.Parent ~= target then
		currentHighlight:Destroy()
		currentHighlight = nil
	end
	
	-- Create new glow if missing
	if target and not currentHighlight then
		local hl = Instance.new("Highlight")
		hl.Name = "InteractionGlow"
		hl.Adornee = target -- Use Adornee so we don't mess up Model children
		hl.Parent = target
		hl.FillTransparency = 0.8 -- Subtle fill
		hl.OutlineTransparency = 0 -- Sharp outline
		currentHighlight = hl
	end
	
	-- Update Color
	if currentHighlight then
		currentHighlight.FillColor = color
		currentHighlight.OutlineColor = color
	end
end

-- // INPUT HANDLER
local function handleInteraction(actionName, inputState, inputObj)
	if inputState == Enum.UserInputState.Begin then
		if currentTarget and canInteract then
			ActionButton.Size = UDim2.fromOffset(110, 50)
			InteractionRemote:FireServer("StartTask", currentTarget)
		end
	elseif inputState == Enum.UserInputState.End then
		ActionButton.Size = UDim2.fromOffset(120, 60)
		InteractionRemote:FireServer("StopTask")
	end
end

-- // SCANNER LOOP
RunService.Heartbeat:Connect(function()
	local char = Player.Character
	if not char then return end
	local root = char:FindFirstChild("HumanoidRootPart")
	if not root then return end
	
	local closest = nil
	local minDst = 10 -- Max Interaction Distance
	
	-- 1. Scan Candidates
	local candidates = {}
	for _, t in pairs(CollectionService:GetTagged("Station")) do table.insert(candidates, t) end
	for _, t in pairs(CollectionService:GetTagged("ExitGate")) do table.insert(candidates, t) end
	for _, t in pairs(CollectionService:GetTagged("MannequinStand")) do table.insert(candidates, t) end
	
	-- 2. Find Closest
	for _, obj in pairs(candidates) do
		local prim = obj:IsA("Model") and obj.PrimaryPart or obj
		if prim then
			local dst = (root.Position - prim.Position).Magnitude
			if dst < minDst then
				closest = obj
				minDst = dst
			end
		end
	end
	
	-- 3. Update State
	if closest ~= currentTarget then
		-- Clean up old highlight immediately
		if currentHighlight then 
			currentHighlight:Destroy()
			currentHighlight = nil
		end
		
		currentTarget = closest
		
		if currentTarget then
			local text, color, active = getContext(currentTarget)
			
			-- Update UI
			ActionButton.Visible = true
			ActionButton.Text = text
			ActionButton.BackgroundColor3 = color:Lerp(Color3.new(0,0,0), 0.8)
			ActionButton.TextColor3 = color
			
			local stroke = ActionButton:FindFirstChildOfClass("UIStroke")
			if stroke then stroke.Color = color end
			
			-- Update Visuals (Glow)
			updateHighlight(currentTarget, color)
			
			canInteract = active
			lastText = text
			
			-- Bind Input
			if active then
				ContextActionService:BindAction("InteractAction", handleInteraction, true, Enum.KeyCode.E, Enum.KeyCode.ButtonY)
				ContextActionService:SetTitle("InteractAction", text)
			else
				ContextActionService:UnbindAction("InteractAction")
			end
			
			-- Animation Pop
			ActionButton.Size = UDim2.fromOffset(0, 0)
			TweenService:Create(ActionButton, TweenInfo.new(0.3, Enum.EasingStyle.Back), {Size = UDim2.fromOffset(120, 60)}):Play()
			
		else
			-- Lost Target
			canInteract = false
			ActionButton.Visible = false
			ContextActionService:UnbindAction("InteractAction")
			InteractionRemote:FireServer("StopTask")
		end
		
	elseif currentTarget then
		-- Dynamic updates (e.g., Gate powers on while looking at it)
		local text, color, active = getContext(currentTarget)
		
		-- Always keep the highlight color synced
		updateHighlight(currentTarget, color)
		
		if text ~= lastText then
			lastText = text
			canInteract = active
			ActionButton.Text = text
			ActionButton.TextColor3 = color
			ActionButton.BackgroundColor3 = color:Lerp(Color3.new(0,0,0), 0.8)
			
			local stroke = ActionButton:FindFirstChildOfClass("UIStroke")
			if stroke then stroke.Color = color end
			
			if active then
				ContextActionService:BindAction("InteractAction", handleInteraction, true, Enum.KeyCode.E, Enum.KeyCode.ButtonY)
			else
				ContextActionService:UnbindAction("InteractAction")
			end
		end
	end
end)
