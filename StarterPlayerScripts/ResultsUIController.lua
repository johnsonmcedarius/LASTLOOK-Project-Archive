-- -------------------------------------------------------------------------------
-- 📂 PROJECT: LAST LOOK
-- 📝 SCRIPT: ResultsUIController (Client)
-- 🛠️ AUTH: Novae Studios
-- 💡 DESC: The "Vogue Cover" Generator. Shows MVP and Payouts.
-- -------------------------------------------------------------------------------

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")
local RoundOverRemote = ReplicatedStorage:WaitForChild("RoundOverEvent")

-- ASSETS (Placeholder colors/fonts for Nerd)
local GOLD = Color3.fromRGB(255, 215, 0)
local VOID = Color3.fromRGB(10, 10, 10)
local FONT = Enum.Font.Bodoni -- High fashion serif font

-- STATE
local ResultsScreen = nil

-- // SETUP UI
local function createResultsUI()
	local screen = Instance.new("ScreenGui")
	screen.Name = "ResultsHUD"
	screen.ResetOnSpawn = false
	screen.IgnoreGuiInset = true
	screen.Parent = PlayerGui
	
	local bg = Instance.new("Frame")
	bg.Name = "Background"
	bg.Size = UDim2.fromScale(1, 1)
	bg.BackgroundColor3 = VOID
	bg.BackgroundTransparency = 0 -- Start black
	bg.Visible = false
	bg.Parent = screen
	
	-- THE COVER TITLE
	local title = Instance.new("TextLabel")
	title.Text = "THE EDIT"
	title.Font = FONT
	title.TextSize = 80
	title.TextColor3 = Color3.new(1,1,1)
	title.Size = UDim2.fromScale(1, 0.2)
	title.Position = UDim2.fromScale(0, 0.05)
	title.BackgroundTransparency = 1
	title.Parent = bg
	
	-- MVP SPOTLIGHT (ViewportFrame would go here, using ImageLabel for now)
	local mvpFrame = Instance.new("ImageLabel")
	mvpFrame.Name = "MVP_Portrait"
	mvpFrame.Size = UDim2.fromScale(0.3, 0.5)
	mvpFrame.Position = UDim2.fromScale(0.35, 0.25)
	mvpFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	mvpFrame.Image = "" -- Set via script
	mvpFrame.Parent = bg
	
	local mvpLabel = Instance.new("TextLabel")
	mvpLabel.Name = "MVP_Name"
	mvpLabel.Text = "MVP NAME"
	mvpLabel.Font = Enum.Font.GothamBold
	mvpLabel.TextColor3 = GOLD
	mvpLabel.TextSize = 30
	mvpLabel.Size = UDim2.fromScale(1, 0.1)
	mvpLabel.Position = UDim2.fromScale(0, 0.8) -- Bottom of portrait
	mvpLabel.BackgroundTransparency = 1
	mvpLabel.Parent = mvpFrame
	
	-- MY STATS
	local earnings = Instance.new("TextLabel")
	earnings.Name = "MyEarnings"
	earnings.Text = "+0 SPOOLS"
	earnings.Font = Enum.Font.GothamBlack
	earnings.TextColor3 = GOLD
	earnings.TextSize = 40
	earnings.Size = UDim2.fromScale(1, 0.1)
	earnings.Position = UDim2.fromScale(0, 0.85)
	earnings.BackgroundTransparency = 1
	earnings.Parent = bg
	
	ResultsScreen = bg
end

-- // ANIMATION SEQUENCE
local function playSequence(winnerTeam, stats, mvpPlayer)
	if not ResultsScreen then createResultsUI() end
	ResultsScreen.Visible = true
	
	-- 1. Reset
	ResultsScreen.BackgroundTransparency = 1
	local title = ResultsScreen:FindFirstChild("TextLabel")
	title.Position = UDim2.fromScale(0, -0.2) -- Start off screen
	
	-- 2. Fade In BG
	TweenService:Create(ResultsScreen, TweenInfo.new(1), {BackgroundTransparency = 0}):Play()
	task.wait(0.5)
	
	-- 3. Drop Title ("THE EDIT")
	TweenService:Create(title, TweenInfo.new(1, Enum.EasingStyle.Bounce), {Position = UDim2.fromScale(0, 0.05)}):Play()
	task.wait(1)
	
	-- 4. Show MVP
	if mvpPlayer then
		local mvpFrame = ResultsScreen.MVP_Portrait
		mvpFrame.MVP_Name.Text = string.upper(mvpPlayer.Name)
		-- Get Avatar Headshot
		local content, isReady = Players:GetUserThumbnailAsync(mvpPlayer.UserId, Enum.ThumbnailType.AvatarBust, Enum.ThumbnailSize.Size420x420)
		mvpFrame.Image = content
		
		-- Pop Effect
		mvpFrame.Size = UDim2.fromScale(0, 0)
		TweenService:Create(mvpFrame, TweenInfo.new(0.5, Enum.EasingStyle.Back), {Size = UDim2.fromScale(0.3, 0.5)}):Play()
	end
	
	-- 5. Show My Earnings
	local myStat = nil
	for _, s in pairs(stats) do
		if s.UserId == Player.UserId then myStat = s end
	end
	
	if myStat then
		local label = ResultsScreen.MyEarnings
		label.Text = "+0 SPOOLS"
		
		-- Number Counter Animation
		local score = 0
		local target = myStat.Score
		local duration = 2
		local start = tick()
		
		task.spawn(function()
			while (tick() - start) < duration do
				local alpha = (tick() - start) / duration
				score = math.floor(target * alpha)
				label.Text = "+" .. score .. " SPOOLS"
				task.wait()
			end
			label.Text = "+" .. target .. " SPOOLS"
		end)
	end
	
	-- 6. Hide after 8 seconds (Lobby Reset)
	task.delay(10, function()
		TweenService:Create(ResultsScreen, TweenInfo.new(1), {BackgroundTransparency = 1}):Play()
		ResultsScreen.Visible = false
	end)
end

RoundOverRemote.OnClientEvent:Connect(playSequence)

-- Init
createResultsUI()