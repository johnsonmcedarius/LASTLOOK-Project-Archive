-- -------------------------------------------------------------------------------
-- 📂 PROJECT: LAST LOOK
-- 📝 SCRIPT: InteractionController (Client - VISUALS + PROGRESS BAR)
-- 🛠️ AUTH: Novae Studios
-- 💡 DESC: Adapts UI text, Highlights, and Progress Bar.
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
local currentHighlight = nil
local lastText = ""
local canInteract = false

-- // UI REFS
local PlayerGui = Player:WaitForChild("PlayerGui")
local HUD = PlayerGui:WaitForChild("InteractionHUD") -- Ensure this ScreenGui exists!
local ActionButton = HUD:WaitForChild("ActionButton")
local ProgressBarBg = HUD:FindFirstChild("ProgressBarBg") -- NEW: Progress Bar Background
local ProgressBarFill = ProgressBarBg and ProgressBarBg:FindFirstChild("Fill") -- NEW: Fill

HUD.Enabled = true
ActionButton.Visible = false
if ProgressBarBg then ProgressBarBg.Visible = false end

-- // CONFIG COLORS
local COL_USE = Color3.fromRGB(0, 255, 120)     
local COL_RESCUE = Color3.fromRGB(255, 50, 50)  
local COL_LOCKED = Color3.fromRGB(150, 150, 150)
local COL_ESCAPE = Color3.fromRGB(50, 255, 255) 

-- // HELPER: Get Context
local function getContext(obj)
	if CollectionService:HasTag(obj, "Station") then
		return "REPAIR", COL_USE, true
	elseif CollectionService:HasTag(obj, "MannequinStand") then
		return "RESCUE", COL_RESCUE, true
	elseif CollectionService:HasTag(obj, "ExitGate") then
		local powered = workspace:GetAttribute("ExitPowered") == true
		if powered then
			return "ESCAPE", COL_ESCAPE, true
		else
			return "LOCKED", COL_LOCKED, false
		end
	end
	return "INTERACT", Color3.fromRGB(255, 255, 255), true
end

-- // HELPER: Update Highlight
local function updateHighlight(target, color)
	if currentHighlight and currentHighlight.Parent ~= target then
		currentHighlight:Destroy()
		currentHighlight = nil
	end
	if target and not currentHighlight then
		local hl = Instance.new("Highlight")
		hl.Name = "InteractionGlow"
		hl.Adornee = target
		hl.Parent = target
		hl.FillTransparency = 0.8
		hl.OutlineTransparency = 0
		currentHighlight = hl
	end
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
	local minDst = 12
	
	local candidates = {}
	for _, t in pairs(CollectionService:GetTagged("Station")) do table.insert(candidates, t) end
	for _, t in pairs(CollectionService:GetTagged("ExitGate")) do table.insert(candidates, t) end
	for _, t in pairs(CollectionService:GetTagged("MannequinStand")) do table.insert(candidates, t) end
	
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
	
	-- PROGRESS BAR UPDATER
	if closest and closest:GetAttribute("Progress") and ProgressBarFill then
		local progress = closest:GetAttribute("Progress") or 0
		local max = closest:GetAttribute("WorkRequired") or 100 -- Default to 100 if missing
		local ratio = math.clamp(progress / max, 0, 1)
		
		ProgressBarBg.Visible = true
		ProgressBarFill.Size = UDim2.fromScale(ratio, 1)
	else
		if ProgressBarBg then ProgressBarBg.Visible = false end
	end
	
	if closest ~= currentTarget then
		if currentHighlight then currentHighlight:Destroy() currentHighlight = nil end
		
		currentTarget = closest
		
		if currentTarget then
			local text, color, active = getContext(currentTarget)
			
			ActionButton.Visible = true
			ActionButton.Text = text
			ActionButton.BackgroundColor3 = color:Lerp(Color3.new(0,0,0), 0.8)
			ActionButton.TextColor3 = color
			
			updateHighlight(currentTarget, color)
			
			canInteract = active
			lastText = text
			
			if active then
				ContextActionService:BindAction("InteractAction", handleInteraction, true, Enum.KeyCode.E, Enum.KeyCode.ButtonY)
				ContextActionService:SetTitle("InteractAction", text)
			else
				ContextActionService:UnbindAction("InteractAction")
			end
			
		else
			canInteract = false
			ActionButton.Visible = false
			ContextActionService:UnbindAction("InteractAction")
			InteractionRemote:FireServer("StopTask")
		end
	elseif currentTarget then
		local text, color, active = getContext(currentTarget)
		updateHighlight(currentTarget, color)
		if text ~= lastText then
			lastText = text
			canInteract = active
			ActionButton.Text = text
			ActionButton.TextColor3 = color
		end
	end
end)
