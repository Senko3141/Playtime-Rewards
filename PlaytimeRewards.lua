-- Playtime Rewards

local players = game:GetService("Players")
local replicatedStorage = game:GetService("ReplicatedStorage")

local remotes = replicatedStorage.Remotes
local profiles = require("./DataService/Profiles")
local dataService = require("./DataService")
local petService = require("./PetService")

local Service = {
	NumberToTimeNeeded = {
		[1] = 0,
		[2] = 5*60,
		[3] = 10*60,
		[4] = 15*60,
		[5] = 20*60,
		[6] = 25*60,
		[7] = 30*60,
		[8] = 45*60,
		[9] = 60*60,
	},
}

function Service.claimPlaytimeReward(player: Player, rewardNumber: number)
	if not player or not rewardNumber then return end
	if typeof(rewardNumber) ~= "number" then return end
	
	local playerData = profiles[player]
	if playerData then
		
		-- Sanity Checks
		local leaderstats: Folder = player:FindFirstChild("leaderstats")
		if not leaderstats then return end
		
		local currentTimer = playerData.Data.CurrentPlaytimeRewardTimer
		local rewardsClaimed = playerData.Data.PlaytimeRewardsClaimed
		if rewardsClaimed[rewardNumber] == nil then return end
		if rewardsClaimed[rewardNumber] then
			-- Already Claimed
			return
		end
		local requiredTime = Service.NumberToTimeNeeded[rewardNumber]
		if requiredTime and currentTimer < requiredTime then
			-- Hasn't Played Long Enough
			return
		end
		------
		
		rewardsClaimed[rewardNumber] = true
		
		-- Give Rewards
		if rewardNumber == 1 then
			dataService.incrementCash(player, 5000)
			leaderstats.Studs.Value += 500
			
			remotes.Notify:FireClient(player, "+5,000 Cash", 4, {Gradient = "Quest_Completed"})
			remotes.Notify:FireClient(player, "+500 Studs", 4)
		elseif rewardNumber == 2 then
			
			--5 Minutes = 3x Speed for 2 Minutes
			remotes.Notify:FireClient(player, "3x Speed for 2 Minutes!", 6, {Gradient = "Quest_Completed"})
			player.GameData.Rewards["3xSpeed"]:SetAttribute("Active",true)
			task.spawn(function()
				for i=120,1,-1 do
					player.GameData.Rewards["3xSpeed"]:SetAttribute("TimeLeft",i)
					task.wait(1)
				end
				player.GameData.Rewards["3xSpeed"]:SetAttribute("Active",false)
				player.GameData.Rewards["3xSpeed"]:SetAttribute("TimeLeft",0)
			end)
			
		elseif rewardNumber == 3 then
			local labubuModels = {
				"Blue Labubu",
				"Green Labubu",
				"OG Labubu",
				"Pink Labubu",
			}
			local chosenLabubu = labubuModels[math.random(#labubuModels)]
			petService.givePet(player, chosenLabubu, 1)
			remotes.Notify:FireClient(player, "New Labubu! (".. chosenLabubu..")", 6)
		elseif rewardNumber == 4 then
			
			player.GameData.Rewards["3xSpeed"]:SetAttribute("Active",true)
			remotes.Notify:FireClient(player, "3x Speed for 60 Seconds!", 6, {Gradient = "Quest_Completed"})
			
			task.spawn(function()
				for i=60,1,-1 do
					player.GameData.Rewards["3xSpeed"]:SetAttribute("TimeLeft",i)
					task.wait(1)
				end
				player.GameData.Rewards["3xSpeed"]:SetAttribute("Active",false)
				player.GameData.Rewards["3xSpeed"]:SetAttribute("TimeLeft",0)
			end)
			
		elseif rewardNumber == 5 then
			dataService.incrementCash(player, 10000)
			remotes.Notify:FireClient(player, "+10,000 Cash", 4, {Gradient = "Quest_Completed"})
		elseif rewardNumber == 6 then
			leaderstats.Studs.Value += 3000
			remotes.Notify:FireClient(player, "+3,000 Studs", 4)
		elseif rewardNumber == 7 then
			
			player.GameData.Rewards["3xSpeed"]:SetAttribute("Active",true)
			remotes.Notify:FireClient(player, "3x Speed for 3 Minutes!", 6, {Gradient = "Quest_Completed"})
			
			task.spawn(function()
				for i=180,1,-1 do
					player.GameData.Rewards["3xSpeed"]:SetAttribute("TimeLeft",i)
					task.wait(1)
				end
				player.GameData.Rewards["3xSpeed"]:SetAttribute("Active",false)
				player.GameData.Rewards["3xSpeed"]:SetAttribute("TimeLeft",0)
			end)
			
			--
			
			dataService.incrementCash(player, 30000)
			remotes.Notify:FireClient(player, "+30,000 Cash", 4, {Gradient = "Quest_Completed"})
		elseif rewardNumber == 8 then
			leaderstats.Studs.Value += 5000
			remotes.Notify:FireClient(player, "+5,000 Studs", 4)
		elseif rewardNumber == 9 then
			local labubuModels = {
				"Blue Labubu",
				"Green Labubu",
				"Grey Labubu",
				"Monster Labubu",
				"OG Labubu",
				"Pink Labubu",
				"Tan Labubu",
				"White Labubu"
			}
			local chosenLabubu = labubuModels[math.random(#labubuModels)]
			petService.givePet(player, chosenLabubu, 1)
			remotes.Notify:FireClient(player, "New Labubu! (".. chosenLabubu..")", 6)
		end
		
		-- Client Replication
		remotes.ClaimPlaytimeReward:FireClient(player, "Claimed", {Number = rewardNumber})
		
		local amount = 0
		for _, bool: boolean in rewardsClaimed do
			if bool == true then amount += 1 end
		end
		remotes.ClaimPlaytimeReward:FireClient(player, "UpdateAllClaimed", {AmountClaimed = amount})
		remotes.Notify:FireClient(player, "Playtime Reward Claimed!", 5, {Confetti = true})
	end
end
function Service.init()
	
	remotes.GetClaimedRewards.OnServerInvoke = function(player: Player)
		local playerData = profiles[player]
		if not playerData then
			return nil
		end
		return playerData.Data.PlaytimeRewardsClaimed
	end
	remotes.ClaimPlaytimeReward.OnServerEvent:Connect(Service.claimPlaytimeReward)
	
	local function onPlayerAdded(player: Player)
		local rewardTimer = Instance.new("IntValue")
		rewardTimer.Name = "RewardTimer"
		rewardTimer.Value = 0
		rewardTimer.Parent = player
	end
	players.PlayerAdded:Connect(onPlayerAdded)
	for _, plr: Player in players:GetPlayers() do
		task.spawn(onPlayerAdded, plr)
	end
	
	task.spawn(function()
		while task.wait(1) do
			for _, plr: Player in players:GetPlayers() do
				local playerData = profiles[plr]
				if playerData then
					-- Incrementing Overall Playtime
					playerData.Data.OverallPlaytime += 1
					
					-- Incrementing In-Game Playtime (Playtime Rewards)
					if playerData.Data.CurrentPlaytimeRewardTimer >= 3600 then
						-- Checking if All Claimed Before Resetting
						local allClaimed = true
						for index: number, _ in playerData.Data.PlaytimeRewardsClaimed do
							if playerData.Data.PlaytimeRewardsClaimed[index] == false then
								allClaimed = false
								break
							end
						end
						if allClaimed then
							-- Reset
							playerData.Data.CurrentPlaytimeRewardTimer = 0
							for index: number, _ in playerData.Data.PlaytimeRewardsClaimed do
								playerData.Data.PlaytimeRewardsClaimed[index] = false
							end
							remotes.ClaimPlaytimeReward:FireClient(plr, "ResetAll")
							remotes.ClaimPlaytimeReward:FireClient(plr, "UpdateAllClaimed", {AmountClaimed = 0})
						else
							-- Do Nothing, Needs to Claim Rewards First
						end
					else
						playerData.Data.CurrentPlaytimeRewardTimer =
							math.clamp(playerData.Data.CurrentPlaytimeRewardTimer+1, 0, 3600)
					end
					local rewardTimerValue = plr:FindFirstChild("RewardTimer")
					if rewardTimerValue then
						rewardTimerValue.Value = playerData.Data.CurrentPlaytimeRewardTimer
					end
				end
			end
		end
	end)
end

return Service
