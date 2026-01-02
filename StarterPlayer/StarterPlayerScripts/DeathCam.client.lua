--[[
    DeathCam (LocalScript)
    Path: StarterPlayer → StarterPlayerScripts
    Parent: StarterPlayerScripts
    Properties:
        Disabled: false
    Exported: 2026-01-02 03:27:27
]]
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera

-- 🎥 CONFIG: THE EDITORIAL FALL
local CAM_DURATION = 1.5 -- Total length of the cutscene
local ZOOM_FOV = 50 
local NORMAL_FOV = 70
local SHAKE_INTENSITY = 0.3

-- HELPER: Wait for the ragdoll to actually exist
local function WaitForRagdoll(myPos)
	local startTime = tick()
	print("🔎 [DEATH CAM] Searching for body near:", myPos)

	while tick() - startTime < 2 do -- Try for 2 seconds
		for _, child in pairs(Workspace:GetChildren()) do
			if child.Name == "DeadBody" and child:FindFirstChild("Head") then
				local dist = (child.Head.Position - myPos).Magnitude
				-- WIDENED RADIUS: 10 -> 40 studs (In case it flings slightly)
				if dist < 40 then 
					print("✅ [DEATH CAM] Found body! Distance:", dist)
					return child
				end
			end
		end
		task.wait(0.1)
	end

	warn("❌ [DEATH CAM] Timed out looking for body.")
	return nil
end

local function PlayEditorialFall(ragdoll)
	if not ragdoll then return end
	local head = ragdoll:WaitForChild("Head", 1)
	if not head then return end

	print("📸 [DEATH CAM] Action!")

	-- 1. SETUP CAMERA (Lock it)
	camera.CameraType = Enum.CameraType.Scriptable
	camera.FieldOfView = NORMAL_FOV

	-- 2. CALCULATE ANGLES (The 3/4 Profile)
	-- Start: Slightly higher and further back
	local startOffset = Vector3.new(4, 5, 4) 
	-- End: Lower and tighter (The "Oh no" angle)
	local endOffset = Vector3.new(2.5, 2, 2.5) 

	local startCFrame = CFrame.new(head.Position + startOffset, head.Position)
	local endCFrame = CFrame.new(head.Position + endOffset, head.Position)

	-- Snap to start immediately
	camera.CFrame = startCFrame

	-- 3. ANIMATION TWEEN
	local tweenInfo = TweenInfo.new(CAM_DURATION, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out)

	local tween = TweenService:Create(camera, tweenInfo, {
		CFrame = endCFrame,
		FieldOfView = ZOOM_FOV
	})
	tween:Play()

	-- 4. LIGHT SHAKE (Impact Effect)
	local shakeTime = 0
	local shakeConnection

	shakeConnection = RunService.RenderStepped:Connect(function(dt)
		shakeTime += dt
		if shakeTime > 0.4 then -- Shake only lasts 0.4s
			shakeConnection:Disconnect()
			return
		end

		-- Random noise shake
		local rx = (math.random() - 0.5) * SHAKE_INTENSITY
		local ry = (math.random() - 0.5) * SHAKE_INTENSITY
		camera.CFrame = camera.CFrame * CFrame.new(rx, ry, 0)
	end)

	-- 5. CUT! (Reset to Ghost)
	task.delay(CAM_DURATION, function()
		if shakeConnection then shakeConnection:Disconnect() end

		print("🎬 [DEATH CAM] Cut! Returning control.")

		-- 🚨 FORCE RESET
		camera.FieldOfView = NORMAL_FOV
		camera.CameraType = Enum.CameraType.Custom

		-- Ensure we are looking at our Ghost Character, not the dead body
		if player.Character then
			-- Try to find humanoid, otherwise look at PrimaryPart
			local hum = player.Character:FindFirstChild("Humanoid")
			local root = player.Character:FindFirstChild("HumanoidRootPart")

			if hum then camera.CameraSubject = hum
			elseif root then camera.CameraSubject = root end
		end
	end)
end

-- ☠️ LISTENER
player:GetAttributeChangedSignal("IsDead"):Connect(function()
	if player:GetAttribute("IsDead") then
		-- We need our position to find the body
		local myChar = player.Character
		-- If primary part is nil, try to grab torso
		local root = myChar and (myChar:FindFirstChild("HumanoidRootPart") or myChar:FindFirstChild("Torso"))
		local myPos = root and root.Position

		if myPos then
			local body = WaitForRagdoll(myPos)
			if body then
				PlayEditorialFall(body)
			else
				-- FAIL SAFE: If we didn't find the body, reset immediately
				camera.CameraType = Enum.CameraType.Custom
			end
		end
	end
end)