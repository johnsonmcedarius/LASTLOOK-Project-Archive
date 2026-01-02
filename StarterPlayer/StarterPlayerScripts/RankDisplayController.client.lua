--[[
    RankDisplayController (LocalScript)
    Path: StarterPlayer → StarterPlayerScripts
    Parent: StarterPlayerScripts
    Properties:
        Disabled: false
    Exported: 2026-01-02 03:27:27
]]
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- CONFIG
local MAX_DISPLAY_DIST = 40 -- Studs
local FONT = Enum.Font.GothamBold

-- 🛠️ CREATE TAG FUNCTION
local function CreateNametag(char)
	if char:FindFirstChild("RankTag") then char.RankTag:Destroy() end
	local head = char:WaitForChild("Head", 5)
	if not head then return end

	local bb = Instance.new("BillboardGui")
	bb.Name = "RankTag"
	bb.Size = UDim2.new(4, 0, 1.5, 0)
	bb.StudsOffset = Vector3.new(0, 2.5, 0) -- Above head
	bb.AlwaysOnTop = false -- Hides behind walls (Tactical!)
	bb.Parent = head

	local container = Instance.new("Frame", bb)
	container.Size = UDim2.new(1, 0, 1, 0)
	container.BackgroundTransparency = 1

	-- Name
	local nameLabel = Instance.new("TextLabel", container)
	nameLabel.Name = "Name"
	nameLabel.Text = char.Name
	nameLabel.Size = UDim2.new(1, 0, 0.4, 0)
	nameLabel.Position = UDim2.new(0, 0, 0.2, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.TextColor3 = Color3.new(1, 1, 1)
	nameLabel.Font = FONT
	nameLabel.TextStrokeTransparency = 0.5
	nameLabel.TextSize = 16

	-- Rank
	local rankLabel = Instance.new("TextLabel", container)
	rankLabel.Name = "Rank"
	rankLabel.Text = "LOADING..."
	rankLabel.Size = UDim2.new(1, 0, 0.3, 0)
	rankLabel.Position = UDim2.new(0, 0, 0.55, 0)
	rankLabel.BackgroundTransparency = 1
	rankLabel.Font = Enum.Font.Gotham
	rankLabel.TextStrokeTransparency = 0.5
	rankLabel.TextSize = 12

	-- Function to Refresh Text
	local player = Players:GetPlayerFromCharacter(char)
	local function UpdateText()
		if not player then return end
		local lvl = player:GetAttribute("Level") or 1
		local rank = player:GetAttribute("RankName") or "Intern"
		local color = player:GetAttribute("RankColor") or Color3.new(1,1,1)

		rankLabel.Text = "Lv. " .. lvl .. " " .. string.upper(rank)
		rankLabel.TextColor3 = color

		-- Creative Director Effect (Rainbow/Special)
		if lvl > 500 then
			rankLabel.Font = Enum.Font.GothamBlack
			-- Add special effect logic here later if you want
		end
	end

	-- Connect Listeners
	if player then
		player:GetAttributeChangedSignal("Level"):Connect(UpdateText)
		player:GetAttributeChangedSignal("RankName"):Connect(UpdateText)
		UpdateText()
	end
end

-- 🔄 LOOP TO HANDLE JOINING/RESPAWNING
local function SetupCharacter(player)
	player.CharacterAdded:Connect(function(char)
		char:WaitForChild("HumanoidRootPart")
		CreateNametag(char)
	end)
	if player.Character then CreateNametag(player.Character) end
end

Players.PlayerAdded:Connect(SetupCharacter)
for _, p in ipairs(Players:GetPlayers()) do SetupCharacter(p) end

-- 🕵️ DISTANCE HIDING LOOP (Optimization)
RunService.Heartbeat:Connect(function()
	local myChar = LocalPlayer.Character
	local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
	if not myRoot then return end

	for _, p in pairs(Players:GetPlayers()) do
		if p ~= LocalPlayer and p.Character then
			local head = p.Character:FindFirstChild("Head")
			local tag = head and head:FindFirstChild("RankTag")
			if tag and head then
				local dist = (head.Position - myRoot.Position).Magnitude
				tag.Enabled = (dist <= MAX_DISPLAY_DIST)
			end
		end
	end
end)