-- -------------------------------------------------------------------------------
-- 📂 PROJECT: LAST LOOK
-- 📝 SCRIPT: InteractionController (Client - SAFE MODE)
-- -------------------------------------------------------------------------------

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Player = Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()
local InteractionRemote = ReplicatedStorage:WaitForChild("InteractionEvent")

-- AUDIO
local loopSound = nil
local function playLoopSound(pitch)
    if not Character then return end
    local root = Character:FindFirstChild("HumanoidRootPart")
    if not root then return end
    
	if not loopSound then
		loopSound = Instance.new("Sound")
		loopSound.SoundId = "rbxassetid://12221967"
		loopSound.Looped = true
		loopSound.Parent = root
	end
	loopSound.PlaybackSpeed = pitch or 1
	loopSound:Play()
end

local function stopLoopSound()
	if loopSound then loopSound:Stop() end
end

-- HIGHLIGHT LOGIC (Simplified for robustness)
local currentTarget = nil
local actionButton = nil

local function setupUI()
    local sg = Instance.new("ScreenGui", Player:WaitForChild("PlayerGui"))
    sg.Name = "InteractionHUD"
    sg.ResetOnSpawn = false
    
    local btn = Instance.new("TextButton", sg)
    btn.Name = "ActionButton"
    btn.Size = UDim2.fromOffset(120, 60)
    btn.Position = UDim2.new(1, -120, 1, -180)
    btn.Text = "USE"
    btn.BackgroundColor3 = Color3.fromRGB(0,0,0)
    btn.TextColor3 = Color3.fromRGB(0,255,0)
    btn.Visible = false
    
    -- Corner
    local c = Instance.new("UICorner", btn); c.CornerRadius = UDim.new(1,0)
    local s = Instance.new("UIStroke", btn); s.Color = Color3.fromRGB(0,255,0); s.Thickness = 2
    
    actionButton = btn
    
    btn.MouseButton1Click:Connect(function()
        if currentTarget then
            InteractionRemote:FireServer("StartTask", currentTarget)
        end
    end)
end

RunService.Heartbeat:Connect(function()
    if not Player.Character then return end
    local root = Player.Character:FindFirstChild("HumanoidRootPart")
    if not root then return end
    
    local closest, closestDist = nil, 8
    
    for _, tag in pairs({"Station", "ExitGate", "MannequinStand"}) do
        for _, obj in pairs(CollectionService:GetTagged(tag)) do
            local prim = obj:IsA("Model") and obj.PrimaryPart or obj
            if prim then
                local dist = (root.Position - prim.Position).Magnitude
                if dist < closestDist then
                    closest = obj
                    closestDist = dist
                end
            end
        end
    end
    
    if closest ~= currentTarget then
        currentTarget = closest
        if actionButton then
            actionButton.Visible = (currentTarget ~= nil)
            if currentTarget and CollectionService:HasTag(currentTarget, "Station") then
                 actionButton.Text = "DESIGN"
                 actionButton.TextColor3 = Color3.fromRGB(0,255,127)
            else
                 actionButton.Text = "INTERACT"
                 actionButton.TextColor3 = Color3.fromRGB(255,255,255)
            end
        end
    end
end)

-- REMOTE LISTENER (The Fix)
InteractionRemote.OnClientEvent:Connect(function(action, data)
	if action == "TaskStarted" then
		playLoopSound(0.8)
		
		-- [FIXED LINE 151] Check if it's actually a Station before listening for progress
		if data and data:IsA("Model") and CollectionService:HasTag(data, "Station") then
			data:GetAttributeChangedSignal("CurrentProgress"):Connect(function()
				local cur = data:GetAttribute("CurrentProgress") or 0
				local max = data:GetAttribute("WorkRequired") or 100
				if loopSound then loopSound.PlaybackSpeed = 0.8 + (0.7 * (cur/max)) end
			end)
		end
		
	elseif action == "TaskStopped" or action == "TaskFailed" then
		stopLoopSound()
	end
end)

if Player.PlayerGui then setupUI() end
