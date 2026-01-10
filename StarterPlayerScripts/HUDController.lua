-- -------------------------------------------------------------------------------
-- 📂 PROJECT: LAST LOOK
-- 📝 SCRIPT: HUDController (Client - TOP BAR)
-- 🛠️ AUTH: Coding Partner
-- 💡 DESC: Shows Round Timer and Status.
-- -------------------------------------------------------------------------------

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

local GameValues = ReplicatedStorage:WaitForChild("GameValues")
local TimerVal = GameValues:WaitForChild("TimeRemaining")
local StatusVal = GameValues:WaitForChild("Status")

local Screen = Instance.new("ScreenGui")
Screen.Name = "TopHUD"
Screen.ResetOnSpawn = false
Screen.Parent = PlayerGui

local TopBar = Instance.new("Frame")
TopBar.Size = UDim2.fromScale(1, 0.1)
TopBar.BackgroundTransparency = 1
TopBar.Parent = Screen

local TimerLabel = Instance.new("TextLabel")
TimerLabel.Size = UDim2.fromScale(0.2, 0.8)
TimerLabel.Position = UDim2.fromScale(0.4, 0)
TimerLabel.BackgroundTransparency = 1
TimerLabel.TextColor3 = Color3.new(1,1,1)
TimerLabel.Font = Enum.Font.GothamBold
TimerLabel.TextSize = 32
TimerLabel.Text = "00:00"
TimerLabel.Parent = TopBar

local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size = UDim2.fromScale(1, 0.3)
StatusLabel.Position = UDim2.fromScale(0, 0.8)
StatusLabel.BackgroundTransparency = 1
StatusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
StatusLabel.Font = Enum.Font.Gotham
StatusLabel.TextSize = 18
StatusLabel.Text = "WAITING..."
StatusLabel.Parent = TopBar

local function fmt(seconds)
	local m = math.floor(seconds / 60)
	local s = seconds % 60
	return string.format("%02d:%02d", m, s)
end

TimerVal.Changed:Connect(function(val)
	TimerLabel.Text = fmt(val)
	if val <= 10 and StatusVal.Value == "InGame" then
		TimerLabel.TextColor3 = Color3.fromRGB(255, 50, 50) -- Red alert
	else
		TimerLabel.TextColor3 = Color3.new(1,1,1)
	end
end)

StatusVal.Changed:Connect(function(val)
	if val == "Intermission" then
		StatusLabel.Text = "NEXT RUNWAY STARTS IN..."
	elseif val == "InGame" then
		StatusLabel.Text = "SURVIVE THE NIGHT"
	elseif val == "WaitingForPlayers" then
		StatusLabel.Text = "WAITING FOR MODELS..."
	else
		StatusLabel.Text = val
	end
end)
