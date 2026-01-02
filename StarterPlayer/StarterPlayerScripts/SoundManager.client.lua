--[[
    SoundManager (LocalScript)
    Path: StarterPlayer → StarterPlayerScripts
    Parent: StarterPlayerScripts
    Properties:
        Disabled: false
    Exported: 2026-01-02 14:59:28
]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local ChaosLevel = ReplicatedStorage:WaitForChild("Values"):WaitForChild("ChaosLevel")
local GameState = ReplicatedStorage:WaitForChild("Values"):WaitForChild("GameState")

print("🔊 Audio Engine (v2 - Mixed) Initializing...")

-- 🎚️ MIXER SETUP (SoundGroups)
-- We create groups so the Settings Menu can control volume easily
local function GetOrCreateGroup(name)
	local g = SoundService:FindFirstChild(name)
	if not g then
		g = Instance.new("SoundGroup", SoundService)
		g.Name = name
	end
	return g
end

local musicGroup = GetOrCreateGroup("Music")
local sfxGroup = GetOrCreateGroup("SFX")

-- 🎵 ASSETS
local SOUNDS = {
	Ambience_Low = "rbxassetid://1845341094",   -- Chill fashion studio hum
	Ambience_High = "rbxassetid://9043360237",  -- Tense horror drone
	Heartbeat = "rbxassetid://9043365993",      -- The "Thumping" sound you hear as chaos rises
	Alarm = "rbxassetid://9119728232",           -- NOW ACTIVE: Plays when Chaos > 75%
	Jumpscare = "rbxassetid://9120367373",      -- Sudden sting
	Footstep_Tile = "rbxassetid://96458369299197",  -- High heel click
	Footstep_Carpet = "rbxassetid://9083849830"  -- Muffled thud
}

-- SETUP CHANNELS (Now with SoundGroup assignment)
local ambLow = Instance.new("Sound", SoundService)
ambLow.Name = "AmbienceLow"
ambLow.SoundId = SOUNDS.Ambience_Low
ambLow.Looped = true
ambLow.Volume = 0
ambLow.SoundGroup = musicGroup -- 👈 Assigned to Music

local ambHigh = Instance.new("Sound", SoundService)
ambHigh.Name = "AmbienceHigh"
ambHigh.SoundId = SOUNDS.Ambience_High
ambHigh.Looped = true
ambHigh.Volume = 0
ambHigh.SoundGroup = musicGroup -- 👈 Assigned to Music

local heartbeat = Instance.new("Sound", SoundService)
heartbeat.Name = "Heartbeat"
heartbeat.SoundId = SOUNDS.Heartbeat
heartbeat.Looped = true
heartbeat.Volume = 0
heartbeat.SoundGroup = musicGroup -- 👈 Assigned to Music

local alarm = Instance.new("Sound", SoundService)
alarm.Name = "Alarm"
alarm.SoundId = SOUNDS.Alarm
alarm.Looped = true
alarm.Volume = 0
alarm.SoundGroup = sfxGroup -- 👈 Assigned to SFX (It's a diegetic sound)

-- 🎚️ DYNAMIC MIXER
local function UpdateMix()
	local chaos = ChaosLevel.Value
	local state = GameState.Value

	if state == "Lobby" or state == "Intermission" then
		-- Chill mode
		TweenService:Create(ambLow, TweenInfo.new(2), {Volume = 0.5}):Play()
		TweenService:Create(ambHigh, TweenInfo.new(2), {Volume = 0}):Play()
		TweenService:Create(heartbeat, TweenInfo.new(2), {Volume = 0}):Play()
		TweenService:Create(alarm, TweenInfo.new(2), {Volume = 0}):Play()

		if not ambLow.Playing then ambLow:Play() end

	elseif state == "Playing" then
		-- Tension Scaling
		local tension = math.clamp(chaos / 100, 0, 1)

		local targetLow = 0.5 - (tension * 0.5)
		local targetHigh = tension * 0.8
		local targetBeat = (tension > 0.3) and ((tension - 0.3) * 1.5) or 0
		local targetAlarm = (tension > 0.75) and 0.5 or 0 

		TweenService:Create(ambLow, TweenInfo.new(1), {Volume = targetLow}):Play()
		TweenService:Create(ambHigh, TweenInfo.new(1), {Volume = targetHigh}):Play()
		TweenService:Create(heartbeat, TweenInfo.new(1), {Volume = targetBeat, PlaybackSpeed = 0.8 + (tension * 0.4)}):Play()
		TweenService:Create(alarm, TweenInfo.new(0.5), {Volume = targetAlarm}):Play()

		if not ambHigh.Playing then ambHigh:Play() end
		if not heartbeat.Playing then heartbeat:Play() end
		if not alarm.Playing and targetAlarm > 0 then alarm:Play() end

	elseif state == "Meeting" then
		-- Silence/Muffle
		TweenService:Create(ambLow, TweenInfo.new(1), {Volume = 0.1}):Play()
		TweenService:Create(ambHigh, TweenInfo.new(1), {Volume = 0}):Play()
		TweenService:Create(heartbeat, TweenInfo.new(1), {Volume = 0}):Play()
		TweenService:Create(alarm, TweenInfo.new(1), {Volume = 0}):Play()
	end
end

-- 👠 FOOTSTEP SYSTEM
local lastStep = 0
local STEP_RATE = 0.4

RunService.RenderStepped:Connect(function()
	UpdateMix() 

	local char = player.Character
	if char then
		local hum = char:FindFirstChild("Humanoid")
		local root = char:FindFirstChild("HumanoidRootPart")

		if hum and root and hum.MoveDirection.Magnitude > 0 and (root.Velocity * Vector3.new(1,0,1)).Magnitude > 1 then
			if os.clock() - lastStep > STEP_RATE then
				lastStep = os.clock()

				local ray = Ray.new(root.Position, Vector3.new(0, -5, 0))
				local hit, pos, normal, mat = workspace:FindPartOnRay(ray, char)

				local soundId = SOUNDS.Footstep_Tile 
				if mat == Enum.Material.Fabric or mat == Enum.Material.Grass then
					soundId = SOUNDS.Footstep_Carpet
				end

				local step = Instance.new("Sound", root)
				step.SoundId = soundId
				step.Volume = 0.3
				step.SoundGroup = sfxGroup -- 👈 Assigned to SFX
				step.PlayOnRemove = true
				step:Destroy()
			end
		end
	end
end)

-- ☠️ DEATH STING
player:GetAttributeChangedSignal("IsDead"):Connect(function()
	if player:GetAttribute("IsDead") then
		local sting = Instance.new("Sound", SoundService)
		sting.SoundId = SOUNDS.Jumpscare
		sting.Volume = 1
		sting.SoundGroup = sfxGroup -- 👈 Assigned to SFX
		sting:Play()
		game.Debris:AddItem(sting, 3)
	end
end)