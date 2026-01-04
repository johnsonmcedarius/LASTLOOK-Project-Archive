-- -------------------------------------------------------------------------------
-- 📂 PROJECT: LAST LOOK
-- 📝 SCRIPT: SoundManager (Module)
-- 🛠️ AUTH: Novae Studios
-- 💡 DESC: Centralized Audio Engine. Handles 3D Sound, UI SFX, and EQ Filters.
-- -------------------------------------------------------------------------------

local SoundManager = {}

local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local ContentProvider = game:GetService("ContentProvider")

-- // SETUP: Create Groups if they don't exist
local sfxGroup = SoundService:FindFirstChild("SFXGroup") or Instance.new("SoundGroup", SoundService)
sfxGroup.Name = "SFXGroup"

local musicGroup = SoundService:FindFirstChild("MusicGroup") or Instance.new("SoundGroup", SoundService)
musicGroup.Name = "MusicGroup"

-- Create LowPass Filter (The Muffled Effect)
local lowPass = musicGroup:FindFirstChild("MuffleEffect") or Instance.new("EqualizerSoundEffect", musicGroup)
lowPass.Name = "MuffleEffect"
lowPass.HighGain = 0 -- Start Clear
lowPass.MidGain = 0
lowPass.LowGain = 0

-- // CACHE: Preload specific assets here if needed
local soundCache = {
	["Click"] = "rbxassetid://12221967", -- Placeholder
	["Snap"] = "rbxassetid://12221967", -- Thread Snap
	["Heartbeat"] = "rbxassetid://12221967", -- Chase
}

-- // FUNCTION: Play 2D Sound (UI)
function SoundManager.PlayUI(soundName)
	local id = soundCache[soundName]
	if not id then return end
	
	local sound = Instance.new("Sound")
	sound.SoundId = id
	sound.SoundGroup = sfxGroup
	sound.Parent = SoundService
	sound:Play()
	game.Debris:AddItem(sound, 3)
end

-- // FUNCTION: Play 3D Sound (World)
function SoundManager.Play3D(soundId, position, volume)
	local part = Instance.new("Part")
	part.Anchored = true
	part.CanCollide = false
	part.Transparency = 1
	part.Position = position
	part.Parent = workspace
	
	local sound = Instance.new("Sound")
	sound.SoundId = soundId
	sound.Volume = volume or 1
	sound.RollOffMaxDistance = 80
	sound.RollOffMinDistance = 5
	sound.SoundGroup = sfxGroup
	sound.Parent = part
	sound:Play()
	
	game.Debris:AddItem(part, (sound.TimeLength > 0 and sound.TimeLength) or 3)
end

-- // FUNCTION: Update Terror Radius (Music Muffle)
-- distance: 0 (Close) to 100 (Far)
function SoundManager.UpdateTerror(distance, maxDist)
	local ratio = math.clamp(distance / maxDist, 0, 1)
	
	-- Logic: 
	-- Close (0) -> HighGain = 0 (Crisp)
	-- Far (1) -> HighGain = -80 (Muffled)
	
	local targetGain = -80 * ratio
	
	-- Smooth tween? Or direct set for responsiveness?
	-- Direct set is better for heartbeat loop
	lowPass.HighGain = targetGain
	lowPass.MidGain = targetGain / 2
end

return SoundManager