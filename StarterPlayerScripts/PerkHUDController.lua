-- -------------------------------------------------------------------------------
-- 📂 PROJECT: LAST LOOK
-- 📝 SCRIPT: PerkHUDController (Client - VISUALS)
-- -------------------------------------------------------------------------------

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

-- Assumption: UI built in Studio named "PerkHUD" with "Slot1", "Slot2", "Slot3"
local HUD = PlayerGui:WaitForChild("PerkHUD")

local function cooldown(perkName, time)
	-- Find slot with perkName (logic needed to match perk to slot)
	-- For MVP, just assuming Slot1
	local slot = HUD.Slot1.CooldownOverlay
	slot.Size = UDim2.fromScale(1, 1)
	TweenService:Create(slot, TweenInfo.new(time), {Size = UDim2.fromScale(1, 0)}):Play()
end

ReplicatedStorage:WaitForChild("TriggerCooldown", 10).Event:Connect(cooldown)
