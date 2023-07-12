UIS = game:GetService("UserInputService")
tweenService = game:GetService("TweenService")
runService = game:GetService("RunService")

player = game.Players.LocalPlayer
char = workspace:WaitForChild(player.Name)
humanoid = char:WaitForChild("Humanoid")
hrp = char:WaitForChild("HumanoidRootPart")
head = char:WaitForChild("Head")
animator = humanoid:WaitForChild("Animator")

lampOn = false
tpOn = false

local device = "Pc"
-- local device = "Mobile" -- for testing ui
if UIS.TouchEnabled and  not UIS.MouseEnabled then
	device = "Mobile"
end

lighting = game.Lighting
interactiveFolder = workspace:WaitForChild("InteractiveFolder")

camera = workspace.CurrentCamera
cursorX = 0
cursorY = 0

oreSize = 6
hardnessIncr = 1 -- Each layer makes it harder to dig down

currentZone = ""
maxMiningDepth = -100
pastMaxDepth = false

screenGui = script.Parent
mainFrame = screenGui:WaitForChild(device)
tpFrame = mainFrame:WaitForChild("TpFrame")
mainFrame.Visible = true

zoneIndicator = mainFrame:WaitForChild("ZoneIndicator")
depthometer = mainFrame:WaitForChild("Depthometer")

mineProg = mainFrame:WaitForChild("MineProg")
progBar = mineProg:WaitForChild("ProgBar"):WaitForChild("Bar")
ProgNameLabel = mineProg:WaitForChild("NameLabel")

repStor = game.ReplicatedStorage
zoneFolder = repStor:WaitForChild("ZoneFolder")
oreLibrary = repStor:WaitForChild("OreLibrary")
pickaxeFolder = repStor:WaitForChild("PickaxeFolder")
animations = repStor:WaitForChild("Animations")

equipRemote = repStor:WaitForChild("EquipRemote")
lampRemote = repStor:WaitForChild("LampRemote")
mineRemote = repStor:WaitForChild("MineRemote")
checkInvRemote = repStor:WaitForChild("CheckInvRemote")

equipedPickaxe = ""
isMining = false
mineTick = 0.05
animationSpeedIncr = 0.2 -- How fast to play the animation each mining power
pickaxePower = 0 -- hp mined in 1/20th of a second
pickaxeRange = 0 -- Range in blocks
pickaxeDelay = 0 -- Delay after mining 1 block
inventoryMax = 20000

selectionBox = script:WaitForChild("SelectionBox")
selectionBox.Parent = workspace
mineFolder = workspace:WaitForChild("MineFolder")
inventoryCount = 0
inventoryFull = false

miningAnimation = animator:LoadAnimation(animations.MiningAnimation)

rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Whitelist
rayParams.FilterDescendantsInstances = {
	mineFolder,
	workspace.CaveBlockFolder,
	interactiveFolder:WaitForChild("MBF")
}



if true then -- TODO: Pickaxe loaded from save
	loadedPickaxe = "Emerald"
else
	loadedPickaxe = "Iron"
end
loadedPickaxe = "Emerald"



function commaValue(amount)
	local formatted = amount
	local k
	while true do  
		formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
		if (k==0) then
			break
		end
	end
	return formatted
end



function updateInventoryCount()
	inventoryCount = checkInvRemote:InvokeServer()
	if inventoryCount >= inventoryMax then
		inventoryFull = true
	else
		inventoryFull = false
	end
	local inventoryCounter = mainFrame:WaitForChild("InventoryCounter")
	inventoryCounter.Text = "".. commaValue(inventoryCount).." / "..commaValue(inventoryMax)..""
	if inventoryFull then
		inventoryCounter.TextColor3 = Color3.fromRGB(150,0,0)
	else
		inventoryCounter.TextColor3 = Color3.fromRGB(
			255,
			255 - (127 * (inventoryCount / inventoryMax)),
			255 - (255 * (inventoryCount / inventoryMax))
		)
	end
end



function findBlockOnRay()
	local unitRay
	if device == "Mobile" then
		unitRay = camera:ScreenPointToRay(cursorX, cursorY) -- Raycasts from screen to world for touch inputs
	else
		unitRay = camera:ScreenPointToRay(cursorX, cursorY) -- Raycasts from screen to world for touch inputs
	end
	unitRay = camera:ScreenPointToRay(cursorX, cursorY) -- Raycasts from screen to world for touch inputs
	local rayCastResult = workspace:Raycast(unitRay.Origin, unitRay.Direction * pickaxeRange,rayParams)
	return rayCastResult
end



function startMining()
	if isMining and not inventoryFull then
		while isMining and not inventoryFull do -- Repeat while holding down with a pickaxe
			local block = findBlockOnRay() -- Block is the raw raycastresult
			if block then
				if block.Instance then -- Test if its a result
					if block.Instance:IsA("Part") then
						local ore = block.Instance
						if ore.Parent.Name == "MineFolder"  then -- Makes sure its a mineable block
							if ore:WaitForChild("Owner").Value == player.Name or ore:WaitForChild("Owner").Value == "" then
								local depthPenalty = 1
								if ore.Position.Y / oreSize < maxMiningDepth then
									depthPenalty = 4
								end
								local oreIndex = oreLibrary:WaitForChild(ore:WaitForChild("OreType").Value) -- Get ore info		
								local oreHealth = math.round(oreIndex:WaitForChild("OreHealth").Value * hardnessIncr * depthPenalty)
								mineProg.Visible = true
								ProgNameLabel.Text = ore:WaitForChild("OreType").Value
								progBar.BackgroundColor3 = oreIndex:WaitForChild("OreColor").Value
								progBar.Size = UDim2.new(0,0,1,0)
								selectionBox.Adornee = ore
								selectionBox.Color3 = Color3.fromHSV(0.6, 0.4, 1) -- Sets colors
								selectionBox.SurfaceColor3 = Color3.fromHSV(0.6, 0.4, 1)
								selectionBox.SurfaceTransparency = 1
								local miningPercentageStep = pickaxePower / oreHealth -- How to change color
								local miningPercentage = 0
								if miningPercentageStep > 1 then
									miningPercentageStep = 1
								end
								mineRemote:FireServer(ore,"Start",pickaxePower,device)
								miningAnimation:Play()
								miningAnimation:AdjustSpeed(pickaxePower * animationSpeedIncr)
								while isMining and oreHealth > 0 and findBlockOnRay() do -- Make sure keep mining the same block
									if findBlockOnRay().Instance == ore then
										miningPercentage += miningPercentageStep
										oreHealth -= pickaxePower -- Repeat damaging the ore
										if miningPercentage > 1 then
											progBar.Size = UDim2.new(1,0,1,0)
										else
											progBar.Size = UDim2.new(miningPercentage,0,1,0)
										end
										selectionBox.Color3 = Color3.fromHSV((0.6 - (0.3 * miningPercentage)), 0.4, 1) -- Sets colors
										selectionBox.SurfaceColor3 = Color3.fromHSV((0.6 - (0.3 * miningPercentage)), 0.4, 1)
										selectionBox.SurfaceTransparency = 1 - (0.25 * miningPercentage)
									else
										break
									end
									wait(mineTick)
								end
								selectionBox.Color3 = Color3.fromHSV(0.6, 0.4, 1) -- Sets colors
								selectionBox.SurfaceColor3 = Color3.fromHSV(0.6, 0.4, 1)
								selectionBox.SurfaceTransparency = 1
								selectionBox.Adornee = nil
								if oreHealth <= 0 then -- Ore has been mined
									local orePosition = ore.Position -- To keep it after removal
									mineRemote:FireServer(ore,"End",pickaxePower,device)
									miningAnimation:Stop()
									progBar.Size = UDim2.new(0,0,1,0)
									if ore:WaitForChild("OreType").Value ~= "Stone" then
										script:WaitForChild("CollectOreSFX"):Play()
										coroutine.resume(coroutine.create(function()
											local xpFrame = script:WaitForChild("xpFrame"):Clone()
											xpFrame.Parent = screenGui
											local xpPos = camera:WorldToViewportPoint(orePosition)
											xpFrame.Position = UDim2.new(0,xpPos.X,0,xpPos.Y)
											xpFrame.Text = "+"..commaValue(oreIndex:WaitForChild("Xp").Value).." XP"
											xpFrame.TextColor3 = oreIndex:WaitForChild("OreColor").Value
											xpFrame.TextTransparency = 0
											xpFrame.TextStrokeTransparency = 0
											xpFrame.Visible = true
											local tweenTime = 2
											local tween = tweenService:Create(
												xpFrame,
												TweenInfo.new(
													tweenTime,
													Enum.EasingStyle.Circular,
													Enum.EasingDirection.Out
												),
												{
													TextTransparency = 1,
													TextStrokeTransparency = 1,
													Position = UDim2.new(0,xpPos.X,0,xpPos.Y - 50)
												}
											):Play()
											wait(tweenTime)
											xpFrame:Destroy()
										end))
									end
									updateInventoryCount()
									if inventoryFull then
										popUp("Your inventory is full! Empty it at the village")
									end
									wait(pickaxeDelay)
								else
									mineRemote:FireServer(ore,"Cancel",pickaxePower,device)
									miningAnimation:Stop()
									progBar.Size = UDim2.new(0,0,1,0)
								end
							else -- If not the right owner
								progBar.Size = UDim2.new(0,0,1,0)
							end
						end
					end
				end
			end
			wait() -- For the big loop above
		end
	else
		if inventoryFull then
			popUp("Your inventory is full! Empty it at the village")
		end
	end
end



function equipPickaxe()
	local pickaxeButton = nil
	local toolSelection = nil
	local mineButton = nil
	if device == "Mobile" then
		pickaxeButton = mainFrame:WaitForChild("ToolSelection"):WaitForChild("PickaxeButton")
		toolSelection = mainFrame:WaitForChild("ToolSelection")
		mineButton = toolSelection:WaitForChild("MineButton")
	end
	if equipedPickaxe == "" then -- Gives a pickaxe if you don't have one
		equipedPickaxe = loadedPickaxe
		equipRemote:FireServer(loadedPickaxe)
		local pickaxe = pickaxeFolder:WaitForChild(equipedPickaxe)
		pickaxePower = pickaxe:WaitForChild("Power").Value
		pickaxeRange = pickaxe:WaitForChild("Range").Value * oreSize
		pickaxeDelay = pickaxe:WaitForChild("Delay").Value
		if device == "Mobile" then
			pickaxeButton.Image = "rbxassetid://12151504679"
			mineButton.Visible = true
			local cursor = mainFrame:WaitForChild("Cursor")
			cursor.Visible = true
		end
	else -- Removes the pickaxe if you have one in hand
		equipedPickaxe = ""
		equipRemote:FireServer("DEL")
		isMining = false
		if device == "Mobile" then
			local cursor = mainFrame:WaitForChild("Cursor")
			cursor.Visible = false
		end
		if device == "Mobile" then
			pickaxeButton.Image = "rbxassetid://12151504379"
			mineButton.Visible = false
		end
	end
end



if device == "Pc" then
	function determineInputBeganPc(input,gameProcessed)
		if not gameProcessed then
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				if equipedPickaxe ~= "" then
					isMining = true
					startMining()
				end
			end
		end
	end
	UIS.InputBegan:Connect(determineInputBeganPc)
end



if device == "Mobile" then
	function determineInputBeganMobile(input)
		if input.UserInputType == Enum.UserInputType.Touch then
			if equipedPickaxe ~= "" then
				isMining = true
				startMining()
			end
		end
	end
end



function tpUp()
	if not tpOn then
		tpOn = true
		local tpLength = 4
		local tpSound = script:WaitForChild("TpSound")
		local tween1 = tweenService:Create(
			tpFrame,
			TweenInfo.new(tpLength * 0.5),
			{BackgroundTransparency = 0}
		)
		local tween2 = tweenService:Create(
			tpFrame,
			TweenInfo.new(tpLength * 0.5),
			{BackgroundTransparency = 1}
		)
		tpFrame.Visible = true
		tpSound:Play()
		tween1:Play()
		wait(tpLength * 0.5)
		hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
		char:SetPrimaryPartCFrame(interactiveFolder:WaitForChild("SpawnPad").CFrame + Vector3.new(0,3,0))
		hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
		tween2:Play()
		wait(tpLength * 0.5)
		tpFrame.Visible = false
		tpOn = false
	end
end



function determineInputEnded(input)
	if input.UserInputType == Enum.UserInputType.Keyboard then -- Keyboard actions

		if input.KeyCode == Enum.KeyCode.F then -- Pickaxe key
			equipPickaxe()
		end

		if input.KeyCode == Enum.KeyCode.Q then -- Light key
			lampRemote:FireServer() -- This is so short it only needs one line
		end

		if input.KeyCode == Enum.KeyCode.T then --Teleport key
			tpUp()
		end

		if input.KeyCode == Enum.KeyCode.C then -- Construct key?

		end
	end
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		isMining = false -- Stops mining upon releasing the touch or mouse
	end
end
UIS.InputEnded:Connect(determineInputEnded)



function updateInput(input,gameProcessed) -- This updates the position of the touch
	if not gameProcessed then
		if input.UserInputType == Enum.UserInputType.MouseMovement then
			cursorX = input.Position.X
			cursorY = input.Position.Y
			if equipedPickaxe ~= "" then
				local block = findBlockOnRay()
				if block and not isMining then
					if block.Instance then
						if block.Instance.Parent.Name == "MineFolder" then
							local ore = block.Instance
							local oreIndex = oreLibrary:WaitForChild(ore:WaitForChild("OreType").Value)
							if selectionBox.Adornee ~= ore then
								selectionBox.Adornee = ore
								selectionBox.SurfaceTransparency = 1
								mineProg.Visible = true
								progBar.BackgroundColor3 = oreIndex:WaitForChild("OreColor").Value
								if ore:WaitForChild("Owner").Value == player.Name or ore:WaitForChild("Owner").Value == "" then
									ProgNameLabel.Text = ore:WaitForChild("OreType").Value
									selectionBox.Color3 = Color3.fromHSV(0.6, 0.4, 1) -- Sets colors
									selectionBox.SurfaceColor3 = Color3.fromHSV(0.6, 0.4, 1)
								else
									ProgNameLabel.Text = ""..ore:WaitForChild("OreType").Value.." (Taken)"
									selectionBox.Color3 = Color3.fromHSV(0.1, 0.8, 1) -- Sets colors
									selectionBox.SurfaceColor3 = Color3.fromHSV(0.1, 0.8, 1)
								end
							end
						else
							selectionBox.Adornee = nil
							mineProg.Visible = false
						end
					else
						selectionBox.Adornee = nil
						mineProg.Visible = false
					end
				end
			else
				selectionBox.Adornee = nil
				mineProg.Visible = false
			end
		end
	end
end
UIS.InputChanged:Connect(updateInput)



function changeMusic(track)
	local musicFolder = script:WaitForChild("MusicFolder")
	local fadeTime = 0.5
	for index, musicTrack in pairs(musicFolder:GetChildren()) do -- Fade out all music
		if musicTrack.Playing and musicTrack.Name ~= track then
			local oldVolume = musicTrack.Volume
			local fadeOutTween = tweenService:Create(
				musicTrack,
				TweenInfo.new(
					fadeTime,
					Enum.EasingStyle.Circular,
					Enum.EasingDirection.In
				),{
					Volume = 0
				}
			):Play()
			wait(fadeTime)
			musicTrack.Playing = false
			musicTrack.TimePosition = 0
			musicTrack.Volume = oldVolume
		end
	end
	local newTrack = musicFolder:WaitForChild(track) -- Fade in new music
	local newTrackVolume = newTrack.Volume
	newTrack.Volume = 0
	newTrack:Play()
	local fadeInTween = tweenService:Create(
		newTrack,
		TweenInfo.new(
			fadeTime,
			Enum.EasingStyle.Circular,
			Enum.EasingDirection.Out
		),{
			Volume = newTrackVolume
		}
	):Play()
end



function playerDied() -- To reset values and so
	player = game.Players.LocalPlayer
	char = workspace:WaitForChild(player.Name)
	humanoid = char:WaitForChild("Humanoid")
	animator = humanoid:WaitForChild("Animator")
	miningAnimation = animator:LoadAnimation(animations.MiningAnimation)
	equipedPickaxe = ""
	if device == "Mobile" then
		local toolSelection = mainFrame:WaitForChild("ToolSelection")
		local pickaxeButton = toolSelection:WaitForChild("PickaxeButton")
		local lampButton = toolSelection:WaitForChild("LampButton")
		pickaxeButton.Image = "rbxassetid://12151504379"
		lampButton.Image = "rbxassetid://12151504945"
	end
end
humanoid.Died:Connect(playerDied)
hrp.Destroying:Connect(playerDied)
char.Destroying:Connect(playerDied)
player.CharacterAdded:Connect(playerDied)



function popUp(popUpText)
	local popUpFrame = mainFrame:WaitForChild("PopUp")
	popUpFrame.TextTransparency = 1
	popUpFrame.TextStrokeTransparency = 1
	popUpFrame.Visible = true
	popUpFrame.Text = popUpText
	local tweenTime = 0.5
	local inBetweenTime = 4
	local tween = tweenService:Create(
		popUpFrame,
		TweenInfo.new(tweenTime),
		{TextTransparency = 0,TextStrokeTransparency = 0}
	):Play()
	wait(tweenTime + inBetweenTime)
	local tween = tweenService:Create(
		popUpFrame,
		TweenInfo.new(tweenTime),
		{TextTransparency = 1,TextStrokeTransparency = 1}
	):Play()
	wait(tweenTime)
	popUpFrame.Text = ""
	popUpFrame.Visible = false
end



function openMobileMiningInventory()
	if mainFrame:WaitForChild("MiningInventory").Visible then
		script:WaitForChild("ButtonClickOffSFX"):Play()
		mainFrame:WaitForChild("MiningInventory").Visible = false
		mainFrame:WaitForChild("ToolSelection").Visible = true
		mainFrame:WaitForChild("Depthometer").Visible = true
		mainFrame:WaitForChild("ZoneIndicator").Visible = true
	else
		script:WaitForChild("ButtonClickOnSFX"):Play()
		mainFrame:WaitForChild("MiningInventory").Visible = true
		mainFrame:WaitForChild("ToolSelection").Visible = false
		mainFrame:WaitForChild("Depthometer").Visible = false
		mainFrame:WaitForChild("ZoneIndicator").Visible = false
	end
end



function runServiceFunctions()
	-- Update player zone
	if char:FindFirstChild("Humanoid") and char:FindFirstChild("HumanoidRootPart") then
		local humanoid = char.Humanoid -- Get the player
		local hrp = char.HumanoidRootPart
		local charPosY = 
			math.floor(hrp.Position.Y - humanoid.HipHeight + (oreSize / 2) / oreSize) -- Calculate position in blocks
		depthometer.Text = ""..math.floor((charPosY - oreSize * 0.5) / oreSize).." meters"
		if charPosY < maxMiningDepth * oreSize and pastMaxDepth == false then
			pastMaxDepth = true
			depthometer.TextColor3 = Color3.fromRGB(150,0,0)
			popUp("You need to upgrade your [base] to mine optimaly at this depth")
		else
			if charPosY > maxMiningDepth * oreSize and pastMaxDepth then
				pastMaxDepth = false
				depthometer.TextColor3 = Color3.fromRGB(255, 255, 255)
			end
		end
		for index,zone in pairs(zoneFolder:GetChildren()) do -- Get the right folder to fit with that height
			if 
				charPosY > zone.BottomLevel.Value * oreSize
				and charPosY <= zone.TopLevel.Value * oreSize
				and zone.Name ~= currentZone
			then
				-- Change lighting
				local zoneLight = zone:WaitForChild("Lighting")
				lighting:WaitForChild("Bloom")
				lighting:WaitForChild("ColorCorrection")
				lighting.Ambient = zoneLight:WaitForChild("Ambient").Value
				lighting.Bloom.Intensity = zoneLight:WaitForChild("BloomIntensity").Value
				lighting.Bloom.Size = zoneLight:WaitForChild("BloomSize").Value
				lighting.Bloom.Threshold = zoneLight:WaitForChild("BloomTreshold").Value
				lighting.ColorCorrection.Brightness = zoneLight:WaitForChild("CC_Brightness").Value
				lighting.ColorCorrection.TintColor = zoneLight:WaitForChild("CC_Color").Value
				lighting.ColorCorrection.Contrast = zoneLight:WaitForChild("CC_Contrast").Value
				lighting.ColorCorrection.Saturation = zoneLight:WaitForChild("CC_Saturation").Value
				lighting.ClockTime = zoneLight:WaitForChild("ClockTime").Value
				lighting.FogColor = zoneLight:WaitForChild("FogColor").Value
				lighting.FogEnd = zoneLight:WaitForChild("FogEnd").Value
				lighting.FogStart = zoneLight:WaitForChild("FogStart").Value
				lighting.OutdoorAmbient = zoneLight:WaitForChild("OutdoorAmbient").Value

				hardnessIncr = zone:WaitForChild("Hardness").Value
				currentZone = zone.Name
				zoneIndicator.Text = zone.Name
				changeMusic(zone.Name)
			end
		end
	end
	if device == "Mobile" then
		cursorX = camera.ViewportSize.X * 0.5
		cursorY =  (camera.ViewportSize.Y * 0.5) - 36 -- Size of the topbar
		if equipedPickaxe ~= "" then
			local block = findBlockOnRay()
			if block and not isMining then
				if block.Instance then
					if block.Instance.Parent.Name == "MineFolder" then
						local ore = block.Instance
						local oreIndex = oreLibrary:WaitForChild(ore:WaitForChild("OreType").Value)
						if selectionBox.Adornee ~= ore then
							selectionBox.Adornee = ore
							selectionBox.SurfaceTransparency = 1
							mineProg.Visible = true
							progBar.BackgroundColor3 = oreIndex:WaitForChild("OreColor").Value
							if ore:WaitForChild("Owner").Value == player.Name or ore:WaitForChild("Owner").Value == "" then
								ProgNameLabel.Text = ore:WaitForChild("OreType").Value
								selectionBox.Color3 = Color3.fromHSV(0.6, 0.4, 1) -- Sets colors
								selectionBox.SurfaceColor3 = Color3.fromHSV(0.6, 0.4, 1)
							else
								ProgNameLabel.Text = ""..ore:WaitForChild("OreType").Value.." (Taken)"
								selectionBox.Color3 = Color3.fromHSV(0.1, 0.8, 1) -- Sets colors
								selectionBox.SurfaceColor3 = Color3.fromHSV(0.1, 0.8, 1)
							end
						end
					else
						selectionBox.Adornee = nil
						mineProg.Visible = false
					end
				else
					selectionBox.Adornee = nil
					mineProg.Visible = false
				end
			end
		else
			selectionBox.Adornee = nil
			mineProg.Visible = false
		end
	end
end
runService.Heartbeat:Connect(runServiceFunctions)



-- UI Buttons
if device == "Mobile" then -- Links button input
	local toolSelection = mainFrame:WaitForChild("ToolSelection")
	local pickaxeButton = toolSelection:WaitForChild("PickaxeButton")
	pickaxeLink = pickaxeButton.Activated:Connect(equipPickaxe)
	local lampButton = toolSelection:WaitForChild("LampButton")
	lampLink = lampButton.Activated:Connect(function()
		if lampOn then
			lampOn = false
			lampButton.Image = "rbxassetid://12151504945"
		else
			lampOn = true
			lampButton.Image = "rbxassetid://12151505166"
		end
		lampRemote:FireServer()
	end)
	local tpButton = toolSelection:WaitForChild("TpButton")
	tpButton.Activated:Connect(tpUp)
	local mineButton = toolSelection:WaitForChild("MineButton")
	mineButton.InputBegan:Connect(determineInputBeganMobile)
	mineButton.InputEnded:Connect(determineInputEnded)
	local inventoryButton = mainFrame:WaitForChild("InventoryButton")
	inventoryButton.Activated:Connect(openMobileMiningInventory)
end



updateInventoryCount()
