-- THE CODE BELOW WAS CODED BY BLACKTIDE STUDIOS

-- THIS IS A ROLL SYSTEM FOR MY GAME "FART RNG"

-- I EXPLAINED THE MAJORITY OF THE SCRIPT




-- VARIABLES

local RS = game:GetService("ReplicatedStorage")
local SSS = game:GetService("ServerScriptService")
local Players = game:GetService("Players")
local RollEvent = RS:WaitForChild("Remotes"):WaitForChild("RollEvent")
local FartDataModule = require(RS:WaitForChild("FartData"))
local DataStoreService = game:GetService("DataStoreService")

local InventoryDataStore = DataStoreService:GetDataStore("InventoryCountSave")
local CutscenesModule = require(script:WaitForChild("CutscenesModule"))
local FartCountDataStore = DataStoreService:GetDataStore("FartCountSave")

local Config = require(RS.Config)
local dataManager = require(SSS:WaitForChild("Modules"):WaitForChild("DataManager"))
local FartHandler = require(SSS:WaitForChild("FartHandler"))

local MAX_RETRIES = 1
local RETRY_DELAY = 5

local isOnBlackFrame = Config.IsOnBlackFrame

local PlaySoundEvent = RS:WaitForChild("Remotes"):WaitForChild("PlaySound")

-- =1 TO THE GLOBAL FARTS OF THE ROLLED FART

local function incrementFartCount(fartName)
	local success, currentCount = pcall(function()
		return FartCountDataStore:GetAsync(fartName)
	end)

	if success then
		currentCount = currentCount or 0
		currentCount = currentCount + 1

		local success, errorMsg = pcall(function()
			return FartCountDataStore:SetAsync(fartName, currentCount)
		end)

		if not success then
		end

		return currentCount
	else
		return nil
	end
end

-- -1 TO THE GLOBAL FARTS OF THE DELETED FART

local function decrementFartCount(fartName)
	local success, currentCount = pcall(function()
		return FartCountDataStore:GetAsync(fartName)
	end)

	if success then
		currentCount = currentCount or 0
		if currentCount > 0 then
			currentCount = currentCount - 1
		else
			currentCount = 0
		end

		local success, errorMsg = pcall(function()
			return FartCountDataStore:SetAsync(fartName, currentCount)
		end)

		if not success then
			warn("Failed to save fart count: " .. errorMsg)
		end

		warn(fartName, currentCount)
		return currentCount
	else
		warn("Failed to save fart count: " .. currentCount)
		return nil
	end
end

-- THIS FUNCTION IS CHOOSING THE FART THAT UR GOING TO GET

local function ChooseFart(farts, player)
	if #farts == 0 then
		return nil
	end

	local luck = player:GetAttribute("Luck") or 1
	local totalEntries = 0
	local adjustedEntries = {}
	local validFarts = {}

	local currentTime = game:GetService("Lighting").ClockTime
	local isDayTime = (currentTime >= 6 and currentTime < 18) and "Day" or "Night"
	local selectedWeather = RS:WaitForChild("SelectedWeather"):WaitForChild("Name").Value

	for _, fart in pairs(farts) do
		local meetsTimeRequirement = not fart.Time or fart.Time == isDayTime
		local meetsWeatherRequirement = not fart.Weather or fart.Weather == selectedWeather

		if fart.Chance and meetsTimeRequirement and meetsWeatherRequirement then
			local adjustedChance = fart.Chance ^ (1 / luck)
			if adjustedChance then
				local entryValue = 1 / adjustedChance
				table.insert(adjustedEntries, entryValue)
				table.insert(validFarts, fart)
				totalEntries = totalEntries + entryValue
			end
		end
	end

	if totalEntries == 0 then
		return nil
	end

	local randomEntry = math.random() * totalEntries
	local cumulativeEntry = 0

	for index, entryValue in pairs(adjustedEntries) do
		cumulativeEntry += entryValue
		if randomEntry <= cumulativeEntry then
			local SelectedFart = validFarts[index]
			if SelectedFart then
				player:SetAttribute("SelectedFart", SelectedFart.Name)
				player:SetAttribute("IsMutated", SelectedFart.FartMutated)
				return SelectedFart.Name, SelectedFart.Chance, SelectedFart.TextColor, SelectedFart.TextFont, if SelectedFart.Cutscene then SelectedFart.Cutscene else nil, SelectedFart.FartMutated, SelectedFart.FartMutatedColor, SelectedFart.FartMutatedFont, SelectedFart.FartMutatedName, SelectedFart.RegularName
			end
		end
	end

	return nil
end

-- I MADE THIS FUNCTION BECAUSE SOMETIMES THE PROFILESTORE WAS WIPING THE PLAYER

local function retryOperation(operation, ...)
	local attempts = 0
	while attempts < MAX_RETRIES do
		local success, result = pcall(operation, ...)
		if success then
			return true, result
		else
			warn(result)
			attempts = attempts + 1
			wait(RETRY_DELAY)
		end
	end
end

-- THIS FUNCTION SAVES THE FARTS USING PROFILESTORESERVICE

local function saveFarts(player)
	local fartsFolder = player:FindFirstChild("FartsFolder")
	if not fartsFolder then
		warn("FartsFolder not found for player " .. player.Name)
		return
	end

	local farts = fartsFolder:GetChildren()
	local fartNames = {}

	for _, fart in ipairs(farts) do
		if fart:IsA("StringValue") then
			table.insert(fartNames, fart.Name)
		end
	end

	local success, errorMsg = retryOperation(function()
		InventoryDataStore:SetAsync(player.UserId, fartNames)
	end)
end

-- THIS FUNCTION LOADS THE FARTS FROM PROFILESTORESERVICE

local function loadFarts(player)
	local success, fartNames = retryOperation(function()
		return InventoryDataStore:GetAsync(player.UserId)
	end)

	if success and fartNames then
		local fartsFolder = player:FindFirstChild("FartsFolder")
		if not fartsFolder then
			fartsFolder = Instance.new("Folder", player)
			fartsFolder.Name = "FartsFolder"
		end

		for _, fartName in ipairs(fartNames) do
				local stringValue = Instance.new("StringValue")
				stringValue.Value = fartName
				stringValue.Name = fartName
				stringValue.Parent = fartsFolder
			end
		end
		local FartDataEvent = RS:WaitForChild("Remotes"):WaitForChild("FartData")
		FartDataEvent:FireClient(player, fartNames)
	end

-- THIS FUNCTION UPDATE THE ROLLS FROM LEADERBOARD

local function updateRolls(player)
	local profile = dataManager.Profiles[player]

	profile.Data.Rolls = (profile.Data.Rolls or 0) + 1
	player.leaderstats.Rolls.Value = profile.Data.Rolls
end

-- THIS FUNCTION IS FOR THE MAX INVENTORY SPACE

local function updateMaxRolls(player, price)
	local profile = dataManager.Profiles[player]

	profile.Data.MaxFart = (profile.Data.MaxFart or 5) + 1
	player.MaxFart.Value = profile.Data.MaxFart

	profile.Data.ExpandPrice = (profile.Data.ExpandPrice or 100) * Config.PriceIncreaseFactor
	player.ExpandPrice.Value = profile.Data.ExpandPrice

	profile.Data.Cash = (profile.Data.Cash or 1000)
	player.Cash.Value = profile.Data.Cash - price
end

-- THIS FUNCTION IS FOR THE CHAT WARNING WHEN SOMEONE GETS A RARE FART

local function DetermineColor(chance)
	if chance <= 4999 then
		return Color3.fromRGB(160, 32, 240)
	elseif chance <= 49999 then
		return Color3.fromRGB(255, 255, 0)
	else
		return Color3.fromRGB(255, 165, 0)
	end
end

-- THIS FUNCTION SHOWS RANDOM FARTS WHEN ROLLING

local function showRandomFarts(player, duration, label, rnglabel, startRNGPos, endRNGPos, StartPos, EndPos)
	local farts = FartDataModule.Farts

	local shuffledFarts = {}
	for _, fart in pairs(farts) do
		table.insert(shuffledFarts, fart)
	end

	for i = #shuffledFarts, 2, -1 do
		local random = math.random(i)
		shuffledFarts[i], shuffledFarts[random] = shuffledFarts[random], shuffledFarts[i]
	end

	local fartsToShow = math.min(#shuffledFarts, 7)
	for i = 1, fartsToShow do
		local fart = shuffledFarts[i]
		label.Text = fart.Name
		label.TextColor3 = fart.TextColor
		label.Font = fart.TextFont
		rnglabel.Text = "1 in " .. tostring(fart.Chance)

		label.Position = StartPos
		rnglabel.Position = startRNGPos

		local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)
		local tween = game:GetService("TweenService"):Create(label, tweenInfo, {Position = EndPos})
		tween:Play()

		local rngtweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)
		local rngtween = game:GetService("TweenService"):Create(rnglabel, rngtweenInfo, {Position = endRNGPos})
		rngtween:Play()

		local PlaySoundEvent = RS.Remotes.PlaySound
		PlaySoundEvent:FireClient(player, "Tick")

		wait(duration)
	end
end

-- THIS FUNCTION SHOWS THE CONFIRM SKIP FRAME

function ShowSkipFrame(player, ActualFrame, cdFrame, frame, skipButton, cd)
	ActualFrame.Visible = false
	player:SetAttribute("OnCooldown", true)

	cdFrame.Visible = true
	cdFrame:TweenSize(UDim2.new(0,0,1,0), "Out", "Linear", cd, true)

	ActualFrame.Visible = false
	frame.Visible = false

	task.wait(cd)

	cdFrame.Visible = false
	cdFrame.Size = UDim2.new(1, 0, 1, 0)

	player:SetAttribute("OnCooldown", false)

	skipButton.Active = true
end

-- THIS ONSERVEREVENT HAPPENS WHEN U PRESS THE ROLL BUTTON

RollEvent.OnServerEvent:Connect(function(player)
	if player:GetAttribute("OnCooldown") then
		return
	end

	local displayDuration
	if player:GetAttribute("Quick") then
		displayDuration = Config.QuickDisplayDuration
	else
		displayDuration = Config.NormalDisplayDuration	
	end

	local startPosition = UDim2.new(0.5, 0, 0.5, 0)
	local startRngPosition = UDim2.new(0.5, 0, 0.44, 0)
	local endRNGPosition = UDim2.new(0.5, 0, 0.5, 0)
	local endPosition = UDim2.new(0.5, 0, 0.44, 0)

	player:SetAttribute("OnCooldown", true)

	local fartname, fartchance, farttextcolor, farttextfont, hasCutscene, ismutated, mutatedcolor, mutatedfont, mutatedtext, regularname = ChooseFart(FartDataModule.Farts, player)

	player:SetAttribute("FartName", fartname)

	local cd = player:GetAttribute("RollCooldown")

	if fartname and fartchance and farttextcolor and farttextfont then
		local playerGui = player:WaitForChild("PlayerGui")
		local frame = playerGui:WaitForChild("RollUI"):WaitForChild("ChooseFrame")
		if frame.Visible then return end
		frame.Visible = false
		local skipButton = frame:WaitForChild("SkipButton")
		local equipButton = frame:WaitForChild("EquipButton")
		local obtaimentLabel = frame:WaitForChild("ObtainmentLabel")
		local RNGlabel = frame.RNGlabel
		local cdFrame = frame.Parent.RollButton.CooldownFrame
		local SkipWarning = frame.Parent.SkipWarningFrame
		local mutationLabel = frame.MutationLabel

		mutationLabel.Visible = false

		local blackScreenFrame = playerGui.RollUI.BlackFrame
		local vignette: ImageLabel = blackScreenFrame.vignette
		local star = blackScreenFrame.Star 

		local server = RS.Remotes.Messages.Server
		local global = RS.Remotes.Messages.Global

		updateRolls(player)

		if fartchance >= isOnBlackFrame then

			if hasCutscene ~= nil then

				frame.Visible = true
				equipButton.Visible = false
				skipButton.Visible = false

				showRandomFarts(player, displayDuration, obtaimentLabel, RNGlabel, startRngPosition, startPosition, endPosition)

				task.wait(displayDuration)

				CutscenesModule.PlayCutscene(player, hasCutscene, farttextcolor, blackScreenFrame, vignette, star)

				task.wait(3.5)

				blackScreenFrame.Visible = false
				equipButton.Visible = true
				skipButton.Visible = true

				PlaySoundEvent:FireClient(player, "BoomEnd")
				local CamShakeEvent = RS.Remotes.CamShakeEvent
				CamShakeEvent:FireClient(player)

				star.Rotation = 0
				star.Size = UDim2.new(0,0,0,0)
			else
				frame.Visible = true
				equipButton.Visible = false
				skipButton.Visible = false

				showRandomFarts(player, displayDuration, obtaimentLabel, RNGlabel, startRngPosition, startPosition, endPosition)

				task.wait(displayDuration)
				blackScreenFrame.Visible = true

				PlaySoundEvent:FireClient(player, "Boom")

				vignette.ImageTransparency = 1
				vignette.ImageColor3 = farttextcolor

				star.ImageColor3 = farttextcolor
				star.Visible = true
				star.ImageTransparency = 1

				star:TweenSize(UDim2.new(0.5, 0, 0.5, 0))
				game.TweenService:Create(vignette, TweenInfo.new(3.5), {ImageTransparency = 0.8}):Play()
				game.TweenService:Create(star, TweenInfo.new(3.5), {Rotation = 1580, ImageTransparency = 0}):Play()

				task.wait(3.5)

				blackScreenFrame.Visible = false
				equipButton.Visible = true
				skipButton.Visible = true


				PlaySoundEvent:FireClient(player, "BoomEnd")
				local CamShakeEvent = RS.Remotes.CamShakeEvent
				CamShakeEvent:FireClient(player)

				star.Rotation = 0
				star.Size = UDim2.new(0,0,0,0)
			end

			local autoEquips = player.AutoEquip.Value

      -- THIS CODE IS FOR AUTOEQUIP IF THE VALUE IS 10 THEN THE FARTS THAT HAVE A HIGHER RARITY THAN 10 ARE GONNA AUTOMATICALY EQUIP

			if autoEquips > 0 then
				if fartchance >= autoEquips then
					local message
					local color = DetermineColor(fartchance)
					if fartchance >= Config.GlobalMessageThreshold then
						message = string.format(Config.Messages.GlobalFormat, player.DisplayName, player.Name, fartname , tostring(fartchance))
						global:FireAllClients(message, color)
					else
						if fartchance >= 1000 then
							message = string.format(Config.Messages.ServerFormat, player.DisplayName, player.Name, fartname , tostring(fartchance))
							server:FireAllClients(message, color)
						else
							return 
						end
					end

					equipButton.Active = false
					FartHandler.UnequipAll(player, player.Character)

					if fartname ~= nil then
						FartHandler.EquipFart(player, player.Character)
					end

					obtaimentLabel.Text = ""
					RNGlabel.Text = ""

					player:SetAttribute("OnCooldown", true)

					cdFrame.Visible = true
					cdFrame:TweenSize(UDim2.new(0,0,1,0), "Out", "Linear", cd, true)

					frame.Visible = false

					task.delay(0.2, function()
						if player.Character:FindFirstChild("FART"):FindFirstChildOfClass("Folder") then
							local fart = player.Character:FindFirstChild("FART"):FindFirstChildOfClass("Folder")
							local Remotes = RS:WaitForChild("Remotes")
							local StoreEvent = Remotes:WaitForChild("Store")
							local MAX_FART = player:FindFirstChild("MaxFart") and player.MaxFart.Value
							local FartFolder = player:FindFirstChild("FartsFolder")

							StoreEvent:FireClient(player, fart.Name)

							if #FartFolder:GetChildren() >= MAX_FART then return end
							local stringValue = Instance.new("StringValue", player.FartsFolder)
							stringValue.Value = fart.Name
							stringValue.Name = fart.Name
						end
					end)

					task.wait(cd)

					cdFrame.Visible = false
					cdFrame.Size = UDim2.new(1, 0, 1, 0)

					player:SetAttribute("OnCooldown", false)

					fartname = nil
					player:SetAttribute("SelectedFart", nil)

					equipButton.Active = true

				elseif fartchance < autoEquips then
					local message
					local color = DetermineColor(fartchance)
					if fartchance >= Config.GlobalMessageThreshold then
						message = string.format(Config.Messages.GlobalFormat, player.DisplayName, player.Name, fartname , tostring(fartchance))
						global:FireAllClients(message, color)
					else
						if fartchance >= 1000 then
							message = string.format(Config.Messages.ServerFormat, player.DisplayName, player.Name, fartname , tostring(fartchance))
							server:FireAllClients(message, color)
						else
							return 
						end
					end

					SkipWarning.Visible = false

					cdFrame.Visible = true
					cdFrame:TweenSize(UDim2.new(0,0,1,0), "Out", "Linear", cd, true)
					frame.Visible = false

					task.wait(cd)

					cdFrame.Visible = false
					cdFrame.Size = UDim2.new(1, 0, 1, 0)

					player:SetAttribute("OnCooldown", false)

					fartname = nil
					player:SetAttribute("SelectedFart", nil)

					return
				end
			end
		else
			frame.Visible = true
			equipButton.Visible = false
			skipButton.Visible = false

			showRandomFarts(player, displayDuration, obtaimentLabel, RNGlabel, startRngPosition, startPosition, endPosition)

			task.wait(displayDuration)

			local autoEquips = player.AutoEquip.Value

			if autoEquips > 0 then
				if fartchance >= autoEquips then
					local message
					local color = DetermineColor(fartchance)
					if fartchance >= Config.GlobalMessageThreshold then
						message = string.format(Config.Messages.GlobalFormat, player.DisplayName, player.Name, fartname , tostring(fartchance))
						global:FireAllClients(message, color)
					else
						if fartchance >= 1000 then
							message = string.format(Config.Messages.ServerFormat, player.DisplayName, player.Name, fartname , tostring(fartchance))
							server:FireAllClients(message, color)
						else
							return 
						end
					end

					equipButton.Active = false
					FartHandler.UnequipAll(player, player.Character)

					if fartname ~= nil then
						FartHandler.EquipFart(player, player.Character)
					end

					obtaimentLabel.Text = ""
					RNGlabel.Text = ""

					player:SetAttribute("OnCooldown", true)

					cdFrame.Visible = true
					cdFrame:TweenSize(UDim2.new(0,0,1,0), "Out", "Linear", cd, true)

					frame.Visible = false

					task.delay(0.2, function()
						if player.Character:FindFirstChild("FART"):FindFirstChildOfClass("Folder") then
							local fart = player.Character:FindFirstChild("FART"):FindFirstChildOfClass("Folder")
							local Remotes = RS:WaitForChild("Remotes")
							local StoreEvent = Remotes:WaitForChild("Store")
							local MAX_FART = player:FindFirstChild("MaxFart") and player.MaxFart.Value
							local FartFolder = player:FindFirstChild("FartsFolder")

							StoreEvent:FireClient(player, fart.Name)

							if #FartFolder:GetChildren() >= MAX_FART then return end
							local stringValue = Instance.new("StringValue", player.FartsFolder)
							stringValue.Value = fart.Name
							stringValue.Name = fart.Name
						end
					end)

					task.wait(cd)

          -- THIS IS THE COOLDOWNFRAME THAT SHOWS UP ON THE ROLL BUTTON

					cdFrame.Visible = false
					cdFrame.Size = UDim2.new(1, 0, 1, 0)

					player:SetAttribute("OnCooldown", false)

					fartname = nil
					player:SetAttribute("SelectedFart", nil)

					equipButton.Active = true

          -- THIS IS THE CHAT WARNING WHEN SOMEONE ROLLS A RARE FART

				elseif fartchance < autoEquips then
					local message
					local color = DetermineColor(fartchance)
					if fartchance >= Config.GlobalMessageThreshold then
						message = string.format(Config.Messages.GlobalFormat, player.DisplayName, player.Name, fartname , tostring(fartchance))
						global:FireAllClients(message, color)
					else
						if fartchance >= 1000 then
							message = string.format(Config.Messages.ServerFormat, player.DisplayName, player.Name, fartname , tostring(fartchance))
							server:FireAllClients(message, color)
						else
							return 
						end
					end

					SkipWarning.Visible = false

					cdFrame.Visible = true
					cdFrame:TweenSize(UDim2.new(0,0,1,0), "Out", "Linear", cd, true)
					frame.Visible = false

					task.wait(cd)

					cdFrame.Visible = false
					cdFrame.Size = UDim2.new(1, 0, 1, 0)

					player:SetAttribute("OnCooldown", false)

					fartname = nil
					player:SetAttribute("SelectedFart", nil)

					return
				end
			end

			equipButton.Visible = true
			skipButton.Visible = true
		end

		obtaimentLabel.Text = fartname
		obtaimentLabel.TextColor3 = farttextcolor
		obtaimentLabel.Font = farttextfont

		if ismutated then
			mutationLabel.Font = mutatedfont
			mutationLabel.Text = tostring(mutatedtext)
			mutationLabel.TextColor3 = mutatedcolor
			obtaimentLabel.Text = regularname
			mutationLabel.Visible = true
		end

		RNGlabel.Text = "1 in " .. tostring(fartchance)

		skipButton.MouseButton1Click:Connect(function()
			local Yes = SkipWarning.Yes
			SkipWarning.Visible = true
			Yes.MouseButton1Click:Connect(function()
				ShowSkipFrame(player, SkipWarning, cdFrame, frame, skipButton, cd)
			end)
			local No = SkipWarning.No
			No.MouseButton1Click:Connect(function()
				SkipWarning.Visible = false
				frame.Visible = true
			end)
		end)

		equipButton.MouseButton1Click:Once(function()
			SkipWarning.Visible = false
			equipButton.Active = false

			FartHandler.UnequipAll(player, player.Character)

			if fartname ~= nil then
				FartHandler.EquipFart(player, player.Character)
			end

			obtaimentLabel.Text = ""
			RNGlabel.Text = ""

			player:SetAttribute("OnCooldown", true)

			incrementFartCount(fartname)

			cdFrame.Visible = true
			cdFrame:TweenSize(UDim2.new(0,0,1,0), "Out", "Linear", cd, true)

			for _, fartOwned in pairs(player:FindFirstChild("FartsOwned"):GetChildren()) do
				if fartname == fartOwned.Name then
					fartOwned.Value = true
				end
			end

			frame.Visible = false

			task.delay(0.2, function()
				if player.Character:FindFirstChild("FART"):FindFirstChildOfClass("Folder") then
					local fart = player.Character:FindFirstChild("FART"):FindFirstChildOfClass("Folder")
					local Remotes = RS:WaitForChild("Remotes")
					local StoreEvent = Remotes:WaitForChild("Store")
					local MAX_FART = player:FindFirstChild("MaxFart") and player.MaxFart.Value
					local FartFolder = player:FindFirstChild("FartsFolder")
					
					StoreEvent:FireClient(player, fart.Name)
					
					if #FartFolder:GetChildren() >= MAX_FART then return end
					local stringValue = Instance.new("StringValue", player.FartsFolder)
					stringValue.Value = fart.Name
					stringValue.Name = fart.Name
				end
			end)

			task.wait(cd)

			cdFrame.Visible = false
			cdFrame.Size = UDim2.new(1, 0, 1, 0)

			player:SetAttribute("OnCooldown", false)

			fartname = nil
			player:SetAttribute("SelectedFart", nil)

			equipButton.Active = true
		end)

		local message
		local color = DetermineColor(fartchance)
		if fartchance >= Config.GlobalMessageThreshold then
			message = string.format(Config.Messages.GlobalFormat, player.DisplayName, player.Name, fartname , tostring(fartchance))
			global:FireAllClients(message, color)
		else
			if fartchance >= 1000 then
				message = string.format(Config.Messages.ServerFormat, player.DisplayName, player.Name, fartname , tostring(fartchance))
				server:FireAllClients(message, color)
			else
				return 
			end
		end

		player:SetAttribute("OnCooldown", false)
		return
	else
		player:SetAttribute("OnCooldown", false)
		return
	end
end)

-- THIS IS THE PROFILEDATASTORE TO SAVE AND LOAD FARTS

game.Players.PlayerRemoving:Connect(saveFarts)
game.Players.PlayerAdded:Connect(loadFarts)

local Remotes = RS:WaitForChild("Remotes")
local DeleteFartDataEvent = Remotes:WaitForChild("DeleteFartData")

-- THIS ONSERVEREVENT DESTROYS THE STRING AND THE TEMPLATE FROM INVENTORY

DeleteFartDataEvent.OnServerEvent:Connect(function(player, fartName)
	local fartsFolder = player:FindFirstChild("FartsFolder")
	if fartsFolder then

		decrementFartCount(fartName)

		local fartString = fartsFolder:FindFirstChild(fartName)
		if fartString then
			fartString:Destroy()
		end
	end
end)

local SaveMaxFartEvent = Remotes:WaitForChild("SaveMaxFart")

-- THIS SAVESTHEMAXFARTS IN INVENTORY

SaveMaxFartEvent.OnServerEvent:Connect(function(player, price)
	if player.Cash.Value >= price then
		updateMaxRolls(player, price)
	end
end)
