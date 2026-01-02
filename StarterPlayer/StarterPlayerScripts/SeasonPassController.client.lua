--[[
    SeasonPassController (LocalScript)
    Path: StarterPlayer → StarterPlayerScripts
    Parent: StarterPlayerScripts
    Properties:
        Disabled: false
    Exported: 2026-01-02 14:59:28
]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local MarketplaceService = game:GetService("MarketplaceService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

print("🎫 [CLIENT] Season Pass UI (Lookbook) Starting...")

-- ============================================================================
-- 1. SAFE EVENT LOADING
-- ============================================================================
local Events = ReplicatedStorage:WaitForChild("Events", 30)
if not Events then warn("❌ Season Pass Failed: No Events Folder") return end

local ClaimReward = Events:WaitForChild("ClaimReward", 10)
local GetSeasonRewards = Events:WaitForChild("GetSeasonRewards", 10)

if not ClaimReward or not GetSeasonRewards then 
	warn("❌ Season Pass Failed: Missing Remotes") 
	return 
end

-- ============================================================================
-- 2. CONFIG & COLORS
-- ============================================================================
local PASS_ID = 3456789 -- 🚨 REPLACE WITH YOUR REAL GAMEPASS ID
local COLORS = {
	Midnight = Color3.fromRGB(20, 20, 30),
	Cream = Color3.fromRGB(250, 248, 235),
	Gold = Color3.fromRGB(255, 215, 0),
	Green = Color3.fromRGB(100, 255, 120),
	Grey = Color3.fromRGB(60, 60, 65),
	Red = Color3.fromRGB(255, 80, 80)
}

local isOpen = false
local mainFrame, scrollContainer
local rewardsData = {}
local claimData = {}

-- ============================================================================
-- 3. UI BUILDER
-- ============================================================================
local function CreatePassUI()
	if playerGui:FindFirstChild("SeasonPassUI") then playerGui.SeasonPassUI:Destroy() end

	local screen = Instance.new("ScreenGui")
	screen.Name = "SeasonPassUI"
	screen.ResetOnSpawn = false
	screen.DisplayOrder = 8
	screen.Parent = playerGui

	-- 1. OPEN BUTTON (Bottom Center)
	local openBtn = Instance.new("TextButton", screen)
	openBtn.Name = "OpenPass"
	openBtn.Text = "LOOKBOOK 🎫"
	openBtn.Font = Enum.Font.GothamBlack
	openBtn.TextSize = 14
	openBtn.TextColor3 = COLORS.Midnight
	openBtn.BackgroundColor3 = COLORS.Cream
	openBtn.Size = UDim2.new(0.1, 0, 0.05, 0)
	openBtn.Position = UDim2.new(0.5, 0, 0.92, 0)
	openBtn.AnchorPoint = Vector2.new(0.5, 0)
	local oc = Instance.new("UICorner", openBtn) oc.CornerRadius = UDim.new(0, 8)
	local os = Instance.new("UIStroke", openBtn) os.Color = COLORS.Gold os.Thickness = 2

	-- 2. MAIN FRAME
	mainFrame = Instance.new("Frame", screen)
	mainFrame.Size = UDim2.new(0.8, 0, 0.6, 0)
	mainFrame.Position = UDim2.new(0.5, 0, 1.5, 0) -- Start Off-Screen Bottom
	mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	mainFrame.BackgroundColor3 = COLORS.Midnight
	local mc = Instance.new("UICorner", mainFrame) mc.CornerRadius = UDim.new(0, 16)
	local ms = Instance.new("UIStroke", mainFrame) ms.Color = COLORS.Gold ms.Thickness = 2

	-- Header
	local title = Instance.new("TextLabel", mainFrame)
	title.Text = "THE LOOKBOOK // SEASON 1"
	title.Font = Enum.Font.GothamBlack
	title.TextColor3 = COLORS.Cream
	title.TextSize = 24
	title.Size = UDim2.new(1, 0, 0.15, 0)
	title.BackgroundTransparency = 1

	local close = Instance.new("TextButton", mainFrame)
	close.Text = "×"
	close.TextColor3 = COLORS.Red
	close.TextSize = 30
	close.BackgroundTransparency = 1
	close.Size = UDim2.new(0.05, 0, 0.15, 0)
	close.Position = UDim2.new(0.95, 0, 0, 0)

	-- Buy Pass Button (Dynamic Visibility)
	local buyBtn = Instance.new("TextButton", mainFrame)
	buyBtn.Name = "BuyPremiumBtn"
	buyBtn.Text = "UNLOCK PREMIUM 🔒"
	buyBtn.Size = UDim2.new(0.2, 0, 0.1, 0)
	buyBtn.Position = UDim2.new(0.7, 0, 0.02, 0)
	buyBtn.BackgroundColor3 = COLORS.Gold
	buyBtn.TextColor3 = COLORS.Midnight
	buyBtn.Font = Enum.Font.GothamBold
	local bc = Instance.new("UICorner", buyBtn) bc.CornerRadius = UDim.new(0, 8)

	-- Hide if owned
	if player:GetAttribute("HasSeasonPass") then
		buyBtn.Visible = false
		title.Text = "THE LOOKBOOK // PREMIUM ACCESS"
		title.TextColor3 = COLORS.Gold
	end

	buyBtn.MouseButton1Click:Connect(function()
		MarketplaceService:PromptGamePassPurchase(player, PASS_ID)
	end)

	-- 3. SCROLL CONTAINER
	scrollContainer = Instance.new("ScrollingFrame", mainFrame)
	scrollContainer.Size = UDim2.new(0.95, 0, 0.75, 0)
	scrollContainer.Position = UDim2.new(0.025, 0, 0.2, 0)
	scrollContainer.BackgroundTransparency = 1
	scrollContainer.ScrollBarThickness = 6
	scrollContainer.ScrollBarImageColor3 = COLORS.Gold
	scrollContainer.CanvasSize = UDim2.new(0, 0, 0, 0) -- Auto-resizes in RefreshList

	local layout = Instance.new("UIListLayout", scrollContainer)
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.Padding = UDim.new(0, 15)
	layout.SortOrder = Enum.SortOrder.LayoutOrder

	return openBtn, close
end

local openBtn, closeBtn = CreatePassUI()

-- ============================================================================
-- 4. REFRESH LOGIC (GENERATES THE TILES)
-- ============================================================================
local function RefreshList()
	-- Clear old tiles
	for _, c in pairs(scrollContainer:GetChildren()) do
		if c:IsA("Frame") then c:Destroy() end
	end

	-- Fetch Data from Server
	local success, data = pcall(function() return GetSeasonRewards:InvokeServer() end)
	if not success then warn("Failed to fetch Season Pass data") return end

	rewardsData = data.Rewards
	claimData = data.Claims

	local myLevel = player:GetAttribute("Level") or 1
	local hasPass = player:GetAttribute("HasSeasonPass")

	-- Update Title/Button if they bought it while menu was closed
	local mainFrame = playerGui.SeasonPassUI.Frame
	local buyBtn = mainFrame:FindFirstChild("BuyPremiumBtn")
	if hasPass and buyBtn then
		buyBtn.Visible = false
	end

	-- Build 50 Levels
	for i = 1, #rewardsData do
		local levelInfo = rewardsData[i]
		local isClaimedFree = claimData[tostring(i)] and claimData[tostring(i)].Free
		local isClaimedPrem = claimData[tostring(i)] and claimData[tostring(i)].Premium
		local isLocked = (myLevel < i)

		-- Column Frame
		local col = Instance.new("Frame", scrollContainer)
		col.Size = UDim2.new(0, 120, 1, 0)
		col.BackgroundTransparency = 1
		col.LayoutOrder = i

		-- Level Header
		local lvlLabel = Instance.new("TextLabel", col)
		lvlLabel.Text = "LVL " .. i
		lvlLabel.Size = UDim2.new(1, 0, 0.1, 0)
		lvlLabel.TextColor3 = isLocked and COLORS.Grey or COLORS.Cream
		lvlLabel.BackgroundTransparency = 1
		lvlLabel.Font = Enum.Font.GothamBold

		-- BOX MAKER
		local function MakeBox(trackType, reward, claimed, yPos, isPremium)
			local box = Instance.new("Frame", col)
			box.Size = UDim2.new(1, 0, 0.4, 0)
			box.Position = UDim2.new(0, 0, yPos, 0)
			box.BackgroundColor3 = COLORS.Midnight
			local bc = Instance.new("UICorner", box) bc.CornerRadius = UDim.new(0, 8)
			local bs = Instance.new("UIStroke", box) 

			-- Style Logic
			if isPremium then
				bs.Color = COLORS.Gold
				if not hasPass then box.BackgroundColor3 = Color3.fromRGB(30, 20, 0) end -- Dark Gold tint
			else
				bs.Color = COLORS.Cream
			end

			if isLocked then
				box.BackgroundTransparency = 0.5
				bs.Transparency = 0.7
			elseif claimed then
				box.BackgroundColor3 = COLORS.Green
				bs.Transparency = 1
			end

			-- Content Text
			local text = Instance.new("TextLabel", box)
			text.Size = UDim2.new(0.9, 0, 0.5, 0)
			text.Position = UDim2.new(0.05, 0, 0.1, 0)
			text.BackgroundTransparency = 1
			text.TextColor3 = COLORS.Cream
			text.TextWrapped = true
			text.Font = Enum.Font.Gotham
			text.TextSize = 12

			if reward.Type == "Spools" then
				text.Text = "🧵 " .. reward.Amount
			else
				text.Text = "👗 " .. reward.Name
			end

			-- Claim Logic
			if not isLocked and not claimed then
				-- Check Premium Lock
				if isPremium and not hasPass then
					local lock = Instance.new("TextLabel", box)
					lock.Text = "🔒"
					lock.Size = UDim2.new(1,0,0.4,0)
					lock.Position = UDim2.new(0,0,0.6,0)
					lock.BackgroundTransparency = 1
					lock.Font = Enum.Font.GothamBold
					lock.TextColor3 = COLORS.Gold
					lock.TextSize = 24
				else
					-- Show Claim Button
					local btn = Instance.new("TextButton", box)
					btn.Text = "CLAIM"
					btn.Size = UDim2.new(0.8, 0, 0.3, 0)
					btn.Position = UDim2.new(0.1, 0, 0.6, 0)
					btn.BackgroundColor3 = COLORS.Gold
					btn.TextColor3 = COLORS.Midnight
					btn.Font = Enum.Font.GothamBold
					local btc = Instance.new("UICorner", btn) btc.CornerRadius = UDim.new(0, 4)

					btn.MouseButton1Click:Connect(function()
						local res = ClaimReward:InvokeServer(i, trackType) -- "Premium" or "Free"
						if res.Success then
							btn.Text = "OWNED"
							btn.BackgroundColor3 = COLORS.Green
							box.BackgroundColor3 = COLORS.Green
							bs.Transparency = 1
							task.wait(0.5)
							btn:Destroy()
							-- Show Checkmark
							local check = Instance.new("TextLabel", box)
							check.Text = "✓"
							check.Size = UDim2.new(1,0,1,0)
							check.BackgroundTransparency = 1
							check.TextColor3 = COLORS.Midnight
							check.Font = Enum.Font.GothamBlack
							check.TextSize = 30
						else
							btn.Text = "ERROR"
							warn(res.Msg)
							task.wait(1)
							btn.Text = "CLAIM"
						end
					end)
				end
			elseif claimed then
				-- Show Checkmark
				local check = Instance.new("TextLabel", box)
				check.Text = "✓"
				check.Size = UDim2.new(1,0,1,0)
				check.BackgroundTransparency = 1
				check.TextColor3 = COLORS.Midnight
				check.Font = Enum.Font.GothamBlack
				check.TextSize = 30
			end
		end

		-- Create Free Row (Top)
		MakeBox("Free", levelInfo.Free, isClaimedFree, 0.15, false)

		-- Create Premium Row (Bottom)
		MakeBox("Premium", levelInfo.Premium, isClaimedPrem, 0.6, true)
	end

	-- Update Canvas Size based on # of items
	scrollContainer.CanvasSize = UDim2.new(0, #rewardsData * 135, 0, 0)
end

-- ============================================================================
-- 5. ANIMATION
-- ============================================================================
local function TogglePass()
	isOpen = not isOpen
	if isOpen then RefreshList() end

	local targetY = isOpen and 0.5 or 1.5
	TweenService:Create(mainFrame, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Position = UDim2.new(0.5, 0, targetY, 0)
	}):Play()
end

openBtn.MouseButton1Click:Connect(TogglePass)
closeBtn.MouseButton1Click:Connect(TogglePass)