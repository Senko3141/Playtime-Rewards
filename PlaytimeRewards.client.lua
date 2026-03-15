local players = game:GetService("Players")
local replicatedStorage = game:GetService("ReplicatedStorage")

local remotes = replicatedStorage:FindFirstChild("Remotes")
local modules = replicatedStorage:WaitForChild("Modules")

local rebirthLib = require(modules.Shared.RebirthLib)
local simpleFormat = require(modules.Packages.FormatNumber.Simple)
local localPlayer = players.LocalPlayer

local uiController = {}

local playerGui = localPlayer.PlayerGui
local mainGui = playerGui:WaitForChild("UI", math.huge)

local frames = mainGui.Frames
local playtimeRewardsFrame = frames.Rewards
local mainFrame = playtimeRewardsFrame.Background.Frame.MainFrame
local mainList = playtimeRewardsFrame.Background.Frame.MainFrame.List

local rewardTimer = localPlayer:FindFirstChild("RewardTimer", math.huge)

local function Format(Int)
	return string.format("%02i", Int)
end

local function convertToHMS(Seconds)
	local Minutes = (Seconds - Seconds%60)/60
	Seconds = Seconds - Minutes*60
	local Hours = (Minutes - Minutes%60)/60
	Minutes = Minutes - Hours*60
	return Format(Hours)..":"..Format(Minutes)..":"..Format(Seconds)
end

function uiController.onClientEvent(action: string, data: any)
	if action == "Claimed" then
		local number: number = data.Number
		if number then
			local frame = mainList:FindFirstChild(tostring(number))
			if frame then
				frame.Label.Text = "Claimed!"
				frame:SetAttribute("Claimed", true)
			end
		end
	elseif action == "UpdateAllClaimed" then
		local amountClaimed: number = data.AmountClaimed
		if amountClaimed then
			mainFrame.ClaimedLabel.Text = tostring(amountClaimed).."/9 Claimed"
		end
	elseif action == "ResetAll" then
		for _,v in mainList:GetChildren() do
			if v:IsA("Frame") then
				v.Label.Text = "00:00:00"
				v:SetAttribute("Claimed", nil)
				v:SetAttribute("Notified", nil)
			end
		end
	end
end
function uiController.init()
	remotes.ClaimPlaytimeReward.OnClientEvent:Connect(uiController.onClientEvent)
	
	local Button_Notices = require("../Button_Notices")
	
	-- First Load In
	local alreadyClaimed = nil
	repeat task.wait(1) 
		alreadyClaimed = remotes.GetClaimedRewards:InvokeServer()	
	until alreadyClaimed
	
	local a = 0
	for number: index, bool: boolean in alreadyClaimed do
		if bool == true then
			a += 1
			uiController.onClientEvent("Claimed", {Number = number})
		end
	end
	uiController.onClientEvent("UpdateAllClaimed", {AmountClaimed = a})
	
	-- Handling Claim Click
	for _, frame: Frame in mainList:GetChildren() do
		if frame:IsA("Frame") then
			frame.Button.MouseButton1Click:Connect(function()
				if frame.Label.Text == "Redeem!" then
					remotes.ClaimPlaytimeReward:FireServer(tonumber(frame.Name))
				end
			end)
		end
	end
	
	-- Timer
	local NumberToTimeNeeded = {
		[1] = 0,
		[2] = 5*60,
		[3] = 10*60,
		[4] = 15*60,
		[5] = 20*60,
		[6] = 25*60,
		[7] = 30*60,
		[8] = 45*60,
		[9] = 60*60,
	}
	task.spawn(function()
		while true do
			local currentTime = rewardTimer.Value
			for _, frame: Frame in mainList:GetChildren() do
				if frame:IsA("Frame") then
					local timeNeeded = NumberToTimeNeeded[tonumber(frame.Name)]
					if timeNeeded then
						if frame:GetAttribute("Claimed") ~= true then
							if currentTime >= timeNeeded then
								-- Set Claim to True
								if frame:GetAttribute("Notified") ~= true then
									frame:SetAttribute("Notified", true)
									Button_Notices:RollCount("Rewards", 1)
								end
								frame.Label.Text = "Redeem!"
							else
								frame.Label.Text = convertToHMS(timeNeeded-currentTime)
							end
						else
							frame.Label.Text = "Claimed!"
						end
					end
				end
			end
			
			-- Updating Actual Label
			local rewardLabel = mainGui.HUD.Left_Container.Buttons.Rewards
			local nextClaim
			-- Getting Next Possible Claimed Item
			for _, frame:Frame in mainList:GetChildren() do
				if frame:IsA("Frame") and frame:GetAttribute("Claimed") ~= true and frame.Label.Text ~= "Redeem!" then
					nextClaim = frame
					break
				end
			end
			if nextClaim then
				rewardLabel.Frame.Title.Text = nextClaim.Label.Text
				rewardLabel.Frame.Title.TextLabel.Text = nextClaim.Label.Text
			else
				rewardLabel.Frame.Title.Text = "Rewards"
				rewardLabel.Frame.Title.TextLabel.Text = "Rewards"
			end
			task.wait(1)
		end
	end)
	
end

return uiController
