-- -------------------------------------------------------------------------------
-- 📂 PROJECT: LAST LOOK
-- 📝 SCRIPT: UI_Manager (Client)
-- 🛠️ AUTH: Novae Studios
-- 💡 DESC: Handles Auras, Quality Bars, and Killer Visual Pings (Neon Noir).
-- -------------------------------------------------------------------------------

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")
local CombatRemote = ReplicatedStorage:WaitForChild("CombatEvent") -- Assuming visual events come here

-- CONFIG
local AURA_RANGE = 60
local AURA_COLOR_HOOKED = Color3.fromRGB(255, 20, 20) -- Vogue Red
local PING_COLOR = Color3.fromRGB(255, 0, 50) -- Neon Red

-- STATE
local activeAuras = {} -- [Player] = HighlightInstance

-- // SETUP: Quality Bar (BillboardGui)
-- Nerd needs to style this. We create a template here.
local function createQualityBar()
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "QualityHUD"
	billboard.Size = UDim2.fromScale(4, 1)
	billboard.StudsOffset = Vector3.new(0, 4, 0)
	billboard.AlwaysOnTop = true
	
	local bg = Instance.new("Frame")
	bg.Name = "BarBG"
	bg.Size = UDim2.fromScale(1, 0.2)
	bg.BackgroundColor3 = Color3.new(0,0,0)
	bg.Parent = billboard
	
	local fill = Instance.new("Frame")
	fill.Name = "QualityFill"
	fill.Size = UDim2.fromScale(1, 1)
	fill.BackgroundColor3 = Color3.fromRGB(255, 215, 0) -- Gold (Quality)
	fill.Parent = bg
	
	return billboard
end

local QualityTemplate = createQualityBar()

-- // FUNCTION: Update Auras
local function updateAuras()
	for _, targetPlayer in pairs(Players:GetPlayers()) do
		if targetPlayer == Player then continue end
		
		local char = targetPlayer.Character
		if not char then continue end
		
		-- CHECK 1: Is Hooked?
		local isHooked = targetPlayer:GetAttribute("HealthState") == "Hooked"
		
		if isHooked then
			-- Create Aura if missing
			if not activeAuras[targetPlayer] then
				local hl = Instance.new("Highlight")
				hl.Name = "VogueAura"
				hl.FillColor = AURA_COLOR_HOOKED
				hl.FillTransparency = 0.5
				hl.OutlineColor = Color3.new(1,1,1)
				hl.Parent = char
				activeAuras[targetPlayer] = hl
				
				-- Add Quality Bar
				local bar = QualityTemplate:Clone()
				bar.Parent = char.Head or char.PrimaryPart
			end
		else
			-- Cleanup
			if activeAuras[targetPlayer] then
				activeAuras[targetPlayer]:Destroy()
				activeAuras[targetPlayer] = nil
				if char:FindFirstChild("QualityHUD") then
					char.QualityHUD:Destroy()
				end
			end
		end
	end
end

-- // FUNCTION: Visual Ping (Killer Intelligence)
-- Triggered when a survivor fails a skill check
local function spawnKillerPing(position)
	-- Only show if LocalPlayer is the Saboteur (check attribute or team)
	-- For now, we assume this event is only sent to the Killer client
	
	local pingPart = Instance.new("Part")
	pingPart.Anchored = true
	pingPart.CanCollide = false
	pingPart.Transparency = 1
	pingPart.Position = position
	pingPart.Parent = workspace
	
	-- Create Billboard Icon (Neon Pulse)
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.fromScale(0, 0) -- Start small
	bb.AlwaysOnTop = true
	bb.Parent = pingPart
	
	local icon = Instance.new("ImageLabel")
	icon.Size = UDim2.fromScale(1, 1)
	icon.Image = "rbxassetid://12345678" -- Nerd needs a "Noise" icon
	icon.BackgroundTransparency = 1
	icon.ImageColor3 = PING_COLOR
	icon.Parent = bb
	
	-- Animate Pop
	TweenService:Create(bb, TweenInfo.new(0.5, Enum.EasingStyle.Back), {Size = UDim2.fromScale(5, 5)}):Play()
	
	-- Fade out
	task.delay(2, function()
		TweenService:Create(icon, TweenInfo.new(1), {ImageTransparency = 1}):Play()
		task.wait(1)
		pingPart:Destroy()
	end)
end

-- // LOOP
RunService.Heartbeat:Connect(function()
	updateAuras()
end)

-- // REMOTE LISTENER
-- StationManager needs to fire this when a check is missed
CombatRemote.OnClientEvent:Connect(function(action, data)
	if action == "LoudNoise" then
		-- Data is position vector
		spawnKillerPing(data)
	end
end)