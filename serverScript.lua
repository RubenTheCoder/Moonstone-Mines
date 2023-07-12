tweenService = game:GetService("TweenService")
statsService = game:GetService("Stats")
runService = game:GetService("RunService")

players = game.Players
serverStorage = game.ServerStorage

playerFolders = serverStorage.PlayerFolders

repStor = game.ReplicatedStorage
oreFolder = repStor.OreFolder
oreLibrary = repStor.OreLibrary
pickaxeFolder = repStor.PickaxeFolder
Sounds = repStor.Sounds

equipRemote = repStor.EquipRemote
lampRemote = repStor.LampRemote
mineRemote = repStor.MineRemote
checkInvRemote = repStor.CheckInvRemote

mineFolder = workspace.MineFolder
interactiveFolder = workspace.InteractiveFolder
mineBorder = interactiveFolder.MBF.MineBorder
AreaFolder = workspace.AreaFolder
caveBlockFolder = workspace.CaveBlockFolder
WSF = workspace.WSF

pickaxeOffset = CFrame.new(0,-0.5,0.075) -- To agline the pickaxe correctly
pickaxeRads = 90

seed = math.random(10000,99999) / 100000 -- Creates a random cave preset
print(seed)
seed = 0.68697
mineSize = 24
oreSize = 6
trotCount = 0
trotMax = 32
stonePerOre = 16

airList = {} -- Stores mined spaces
mineResetting = false
placingAirBorder = false

mineBorderTweenTime = 1 -- Tween for the fade in and out of the mineBorder
mineBorderTweenIn = tweenService:Create(
	mineBorder,
	TweenInfo.new(mineBorderTweenTime, Enum.EasingStyle.Circular,Enum.EasingDirection.In),
	{Transparency = 0}
)
mineBorderTweenOut = tweenService:Create(
	mineBorder,
	TweenInfo.new(mineBorderTweenTime, Enum.EasingStyle.Circular,Enum.EasingDirection.Out),
	{Transparency = 1}
)

placementVectors = { -- Vectors are pretty neet to keep positions stored
	Vector3.new(0,-2,0), -- Security placement
	Vector3.new(1,0,0),
	Vector3.new(-1,0,0),
	Vector3.new(0,1,0),
	Vector3.new(0,-1,0),
	Vector3.new(0,0,1),
	Vector3.new(0,0,-1),
	Vector3.new(1,-1,0),
	Vector3.new(-1,-1,0),
	Vector3.new(0,-1,1),
	Vector3.new(0,-1,-1)
}

placeAir = nil -- Link for placeStone()



function trot()
	if trotCount>= trotMax then
		wait()
		trotCount = 0
		print("Trotted")
	end
	trotCount += 1
end



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



function characterAdded(character)
	local player = players:GetPlayerFromCharacter(character)
	if not player then return end
	while not character:FindFirstChild("Humanoid")
		and not character:FindFirstChild("HumanoidRootPart") do wait() end

	character.HumanoidRootPart.AncestryChanged:Connect(function(_, parent)
		if character.Humanoid.Health == 0 then return end
		if not parent then
			player:LoadCharacter()
		end
	end)
end
players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(characterAdded)
	if player.Character then characterAdded(player.Character) end
end)



function checkMiningInventorySize(player)
	local playerFolder = playerFolders[player.Name]
	local inventory = playerFolder.MiningInventory
	local inventoryCount = 0
	for index, item in pairs(inventory:GetChildren()) do
		inventoryCount += item.Value
	end
	return inventoryCount
end
checkInvRemote.OnServerInvoke = checkMiningInventorySize



function toggleLamp(player)
	local playerName = player.Name
	if workspace:FindFirstChild(playerName) then -- Gets character
		local char = workspace[playerName]
		if char:FindFirstChild("Lamp") then -- Gets lamp
			local lamp = char.Lamp
			local light = lamp.SpotLight
			if light.Enabled then -- Turn off
				lamp.lampOffSfx:Play()
				lamp.Color = Color3.fromRGB(150,150,150)
				lamp.Material = Enum.Material.SmoothPlastic
				light.Enabled = false
			else -- Turn on
				lamp.lampOnSfx:Play()
				lamp.Color = Color3.fromRGB(200, 170, 120)
				lamp.Material = Enum.Material.Neon
				light.Enabled = true
			end
		end
	end
end
lampRemote.OnServerEvent:Connect(toggleLamp)



function equipPickaxe(player,pickaxeType) -- For equiping or unequiping your pickaxe
	local playerName = player.Name
	if workspace:FindFirstChild(playerName) then -- Check for a character
		local char = workspace[playerName]
		if WSF[playerName]:FindFirstChild("Pickaxe") then -- Check for existing pickaxe
			if pickaxeType == "DEL" then -- Player unequips pickaxe
				WSF[playerName].Pickaxe:Destroy()
				if char:FindFirstChild("RightThumb") then -- Locates hand
					local grip = char.RightThumb.Grip
					grip.Part1 = nil
				end
			else
				if pickaxeFolder:FindFirstChild(pickaxeType) then -- Extra security to prevent fake calls ruining the game
					local pickaxe = pickaxeFolder[pickaxeType]:Clone()
					pickaxe.Name = "Pickaxe"
					if char:FindFirstChild("RightThumb") then -- Locates hand
						local grip = char.RightThumb.Grip
						pickaxe.CFrame = 
							char.RightThumb.CFrame:ToWorldSpace(pickaxeOffset) * CFrame.Angles(math.rad(pickaxeRads),0,0)
						grip.Part1 = pickaxe -- Connects pickaxe
						pickaxe.Parent = WSF[playerName]
					end
				end
			end
		else -- Player still needs a pickaxe
			if pickaxeFolder:FindFirstChild(pickaxeType) then -- Extra security to prevent fake calls ruining the game
				local pickaxe = pickaxeFolder[pickaxeType]:Clone()
				pickaxe.Name = "Pickaxe"
				if char:FindFirstChild("RightThumb") then -- Locates hand
					local grip = char.RightThumb.Grip
					pickaxe.CFrame = 
						char.RightThumb.CFrame:ToWorldSpace(pickaxeOffset) * CFrame.Angles(math.rad(pickaxeRads),0,0)
					grip.Part1 = pickaxe -- Connects pickaxe
					pickaxe.Parent = WSF[playerName]
				end
			end
		end
	end
end
equipRemote.OnServerEvent:Connect(equipPickaxe)



function selectOre(cordY,isCave)
	if math.random(1,stonePerOre) == 1 then

		local random = math.random(1,1000000)
		local class -- Determine its class
		if random >= 1 and random <= 900000 then -- 90%
			class = "Common"
		else
			if random >= 900001 and random <= 990000 then -- 9%
				class = "Uncommon"
			else
				if random >= 990001 and random <= 999000 then -- 0.9%
					class = "Rare"
				else
					if random >= 999001 and random <= 999900 then -- 0.09%
						class = "Epic"
					else
						if random >= 999991 and random <= 999999 then -- 0.009%
							class = "Legend"
						else
							if random == 1000000 then -- 0.001%
								class = "Ultra"
							end
						end
					end
				end
			end
		end

		local oreLottery = {}
		for index,ore in pairs(oreLibrary:GetChildren()) do
			-- Adds any ore with the same class and between the top and bottom borders
			if ore.Class.Value == class and cordY / oreSize <= ore.TopDepth.Value and cordY / oreSize >= ore.BottomDepth.Value then
				if ore:FindFirstChild("CaveOnly") then -- Adds it only when its a cave when its cave only
					if isCave then
						table.insert(oreLottery,ore.Name)
					end
				else
					table.insert(oreLottery,ore.Name)
				end
			end
		end
		if #oreLottery > 0 then
			return oreFolder[oreLottery[math.random(1,#oreLottery)]]
		else
			return oreFolder.Stone
		end
	else
		return oreFolder.Stone
	end
end



function placeCaveBlock(cordX,cordY,cordZ)
	local caveBlock = oreFolder.Stone:Clone()
	caveBlock.Color = Color3.fromRGB(80,80,90)
	caveBlock.Material = Enum.Material.Granite
	caveBlock.Size = Vector3.new(oreSize + 0.1,oreSize + 0.1,oreSize + 0.1)
	caveBlock.Position = Vector3.new(cordX,cordY,cordZ)
	caveBlock.Parent = caveBlockFolder
	return caveBlock
end



function checkCave(cordX,cordY,cordZ)
	local noiseFreq = -0.7 -- Decides the percentage of air (-1.5 = 0%, 1.5 = 100%)
	if cordY > -10 * oreSize then -- This prevents cave from opening the surface
		noiseFreq = -1.5
	end
	if cordY > -110 and cordY <= 10 then -- This will gradually blend in caves with the surface
		local zoneReach = 0.01 -- how much blocks in percentage
		local divider = (1.5 - noiseFreq) * zoneReach -- This will calculate the steps to reach
		noiseFreq = -1.5 + ((cordY - 10) * divider)
	end
	local noiseScaleX = 15 -- The bigger this is, the wider caves will be
	local noiseScaleY = 12 -- The bigger this is, the taller caves will be in scale
	local noiseScaleZ = 15 -- The bigger this is, the wider caves will be

	local noiseX = (cordX / oreSize) / noiseScaleX -- Sets the scale of the noise
	local noiseY = (cordY / oreSize) / noiseScaleY
	local noiseZ = (cordZ / oreSize) / noiseScaleZ
	local densityX = math.noise(seed,noiseY,noiseZ) -- Goes along each axis to get its noise and adds it up to get a density
	local densityY = math.noise(noiseX,seed,noiseZ)
	local densityZ = math.noise(noiseX,noiseY,seed)
	local density = (densityX + densityY + densityZ)
	if density > noiseFreq then -- If dense enough it places stone
		return "Block"
	else
		return "Air"
	end
end



function placeStone(cordX,cordY,cordZ) -- Places a stone block at the given coordinates
	if not mineResetting then
		if 
			not airList["x"..cordX.."y"..cordY.."z"..cordZ] and 
			not mineFolder:FindFirstChild("x"..cordX.."y"..cordY.."z"..cordZ) and
			cordY <= 0 then -- aircheck
			local caveCheck = checkCave(cordX,cordY,cordZ)
			if caveCheck == "Block" then
				local oreSelected = selectOre(cordY,false) -- y,cave
				local oreToPlace = oreSelected:Clone() -- Places the selected ore
				oreToPlace.Position = Vector3.new(cordX,cordY,cordZ)
				oreToPlace.Parent = mineFolder
				oreToPlace.Name = "x"..cordX.."y"..cordY.."z"..cordZ.."" -- To index ores later on
			else
				coroutine.resume(coroutine.create(function()
					-- Checks around itself, if its air it gets put in a list for the nest round, else it places stone and border
					print("Cave generating")
					local caveBlocks = {}
					table.insert(caveBlocks,placeCaveBlock(cordX,cordY,cordZ))
					-- First item to be added
					airList["x"..cordX.."y"..cordY.."z"..cordZ] = true
					local checkList = {}
					for index,pVector in pairs(placementVectors) do
						table.insert(checkList,Vector3.new(cordX + (pVector.X * oreSize),cordY + (pVector.Y * oreSize),cordZ + (pVector.Z * oreSize)))
					end
					-- Repeats over the items afterwards
					repeat
						for index,checkItem in pairs(checkList) do
							local cordX = checkItem.X
							local cordY = checkItem.Y
							local cordZ = checkItem.Z
							if not airList["x"..cordX.."y"..cordY.."z"..cordZ] and not mineFolder:FindFirstChild("x"..cordX.."y"..cordY.."z"..cordZ) then
								local caveCheck = checkCave(cordX,cordY,cordZ)
								if caveCheck == "Block" then -- Place a cave wall
									local oreSelected = selectOre(cordY,true) -- y,cave
									local oreToPlace = oreSelected:Clone() -- Places the selected ore
									oreToPlace.Position = Vector3.new(cordX,cordY,cordZ)
									oreToPlace.Parent = mineFolder
									oreToPlace.Name = "x"..cordX.."y"..cordY.."z"..cordZ.."" -- To index ores later on
								else
									airList["x"..cordX.."y"..cordY.."z"..cordZ] = true

									--Enable this for visual cave air
									--local part = Instance.new("Part")
									--part.Anchored = true
									--part.CanCollide = false
									--part.CanTouch = false
									--part.CanQuery = false
									--part.Material = Enum.Material.Neon
									--part.Color = Color3.fromRGB(0,127,0)
									--part.Size = Vector3.new(0.5,0.5,0.5)
									--part.Position = Vector3.new(cordX,cordY,cordZ)
									--part.Name = "Air"
									--part.Parent = workspace.MineFolder

									for index,pVector in pairs(placementVectors) do
										table.insert(checkList,Vector3.new(cordX + (pVector.X * oreSize),cordY + (pVector.Y * oreSize),cordZ + (pVector.Z * oreSize)))
									end
									if  checkCave(cordX,cordY + oreSize,cordZ) == "Block" then
										table.insert(caveBlocks,placeCaveBlock(cordX,cordY,cordZ))
									else
										if checkCave(cordX,cordY - oreSize,cordZ) == "Block" then
											table.insert(caveBlocks,placeCaveBlock(cordX,cordY,cordZ))
										else
											if checkCave(cordX + oreSize,cordY,cordZ) == "Block" then
												table.insert(caveBlocks,placeCaveBlock(cordX,cordY,cordZ))
											else
												if checkCave(cordX - oreSize,cordY,cordZ) == "Block" then
													table.insert(caveBlocks,placeCaveBlock(cordX,cordY,cordZ))
												else
													if checkCave(cordX,cordY,cordZ + oreSize) == "Block" then
														table.insert(caveBlocks,placeCaveBlock(cordX,cordY,cordZ))
													else
														if checkCave(cordX,cordY,cordZ - oreSize) == "Block" then
															table.insert(caveBlocks,placeCaveBlock(cordX,cordY,cordZ))
														end
													end
												end
											end
										end
									end
								end
							end
							local indexNumber = table.find(checkList,checkItem)
							table.remove(checkList,indexNumber)
							trot()
						end
						trot()
					until #checkList == 0
					print("Cave generated")
					for index,caveBlock in pairs(caveBlocks) do
						caveBlock:Destroy()
						trot()
					end
				end))
			end
		end
	end
end



function placeAir(cordX,cordY,cordZ) -- Fills in air, places stone
	if not mineResetting then
		if not airList["x"..cordX.."y"..cordY.."z"..cordZ] and not mineFolder:FindFirstChild("x"..cordX.."y"..cordY.."z"..cordZ) then
			airList["x"..cordX.."y"..cordY.."z"..cordZ] = true

			--Enable this for visual air
			--local part = Instance.new("Part")
			--part.Anchored = true
			--part.CanCollide = false
			--part.CanTouch = false
			--part.CanQuery = false
			--part.Material = Enum.Material.Neon
			--part.Color = Color3.fromRGB(127,0,127)
			--part.Size = Vector3.new(0.5,0.5,0.5)
			--part.Position = Vector3.new(cordX,cordY,cordZ)
			--part.Name = "Air"
			--part.Parent = workspace.MineFolder

			if not placingAirBorder then
				for index,pVector in pairs(placementVectors) do
					placeStone( -- x,y,z in normal size
						cordX + pVector.X * oreSize,
						cordY + pVector.Y * oreSize,
						cordZ + pVector.Z * oreSize)
					trot()
				end
			end
		end
	end
end



function generateNewMine() -- Resets the old mine and creates a new layer of stone
	mineBorderTweenIn:Play() -- Closes the border
	wait(mineBorderTweenTime)
	mineBorder.CanCollide = true
	mineBorder.CanQuery = true

	--TODO: tp players

	mineResetting = true
	airList = {}
	for index, block in pairs(mineFolder:GetChildren()) do -- Clearing whipe
		block:Destroy()
		wait()
	end
	for index, block in pairs(mineFolder:GetChildren()) do -- Second security whipe
		block:Destroy()
		wait()
	end

	mineResetting = false
	placingAirBorder = true
	for orderX = 1,mineSize + 2 do --Uses the for XZ method to create a 2d grid of stone
		for orderZ = 1,mineSize + 2 do -- Top
			local cordX = orderX * oreSize
			local cordZ = orderZ * oreSize
			placeAir(cordX - (oreSize * 2),oreSize,cordZ - (oreSize * 2)) -- x,y,z in normal size
		end
		wait()
	end
	for orderX = 1,mineSize + 2 do --Uses the for XY method to create a 2d grid of stone
		for orderY = 1,10 do -- Wall left
			local cordX = orderX * oreSize
			local cordY = orderY * oreSize * -1
			placeAir(cordX - (oreSize * 2),cordY + (oreSize * 2),oreSize * -1) -- x,y,z in normal size
		end
		wait()
	end
	for orderZ = 1,mineSize + 2 do --Uses the for ZY method to create a 2d grid of stone
		for orderY = 1,10 do -- Wall top
			local cordZ = orderZ * oreSize
			local cordY = orderY * oreSize * -1
			placeAir(oreSize * -1,cordY + (oreSize * 2),cordZ - (oreSize * 2)) -- x,y,z in normal size
		end
		wait()
	end
	for orderX = 1,mineSize + 2 do --Uses the for XY method to create a 2d grid of stone
		for orderY = 1,10 do -- Wall right
			local cordX = orderX * oreSize
			local cordY = orderY * oreSize * -1
			placeAir(cordX - (oreSize * 2),cordY + (oreSize * 2),oreSize * mineSize) -- x,y,z in normal size
		end
		wait()
	end
	for orderZ = 1,mineSize + 2 do --Uses the for ZY method to create a 2d grid of stone
		for orderY = 1,10 do -- Wall top
			local cordZ = orderZ * oreSize
			local cordY = orderY * oreSize * -1
			placeAir(oreSize * mineSize,cordY + (oreSize * 2),cordZ - (oreSize * 2)) -- x,y,z in normal size
		end
		wait()
	end
	placingAirBorder = false
	for orderX = 0,mineSize - 1 do --Uses the for XZ method to create a 2d grid of stone
		for orderZ = 0,mineSize -1 do
			local cordX = orderX * oreSize
			local cordZ = orderZ * oreSize
			placeStone(cordX,0,cordZ) -- x,y,z in normal size
		end
		wait()
	end

	mineBorder.CanCollide = false -- Opens the border
	mineBorder.CanQuery = false
	mineBorderTweenOut:Play()
	wait(mineBorderTweenTime)
	seed = math.random(10000,99999) / 100000 -- Creates a random cave preset
end



function addOre(player,ore,amountAdded,device)
	local oreType = ore:WaitForChild("OreType",60).Value
	local playerFolder = playerFolders[player.Name]
	local miningInventory = playerFolder:WaitForChild("MiningInventory",60)
	local inventoryItem
	if not miningInventory:FindFirstChild(oreType) then
		inventoryItem = Instance.new("IntValue")
		inventoryItem.Name = oreType
		inventoryItem.Value = amountAdded
		inventoryItem.Parent = miningInventory
	else
		inventoryItem = miningInventory[oreType]
		inventoryItem.Value += amountAdded
	end
	local oreIndex = oreLibrary:WaitForChild(oreType,60)

	local inventoryList = player.PlayerGui:
	WaitForChild("ScreenGui",60):
	WaitForChild(device):
	WaitForChild("MiningInventory",60)
	local itemFrame
	if not inventoryList:FindFirstChild(oreType) then
		itemFrame = script.MII:Clone()
		itemFrame.Name = oreType
		itemFrame.ImageLabel.Image = oreIndex:WaitForChild("OreSymbol",60).Texture
		local oreColor = oreIndex:WaitForChild("OreColor",60).Value
		itemFrame.BackgroundColor3 = Color3.new(oreColor.R * 0.5,oreColor.G * 0.5,oreColor.B * 0.5)
		itemFrame.TextLabel.Text = "x"..commaValue(inventoryItem.Value)..""
		if device == "Mobile" then
			itemFrame.Size = UDim2.new(1,0,0,30)
			itemFrame.ImageLabel.Size = UDim2.new(0,30,0,30)
			itemFrame.TextLabel.Size = UDim2.new(1,-30,1,0)
		end
		itemFrame.Parent = inventoryList
	else
		itemFrame = inventoryList[oreType]
		itemFrame.TextLabel.Text = "x"..commaValue(inventoryItem.Value)..""
	end
end



function playerMines(player,ore,state,pickaxePower,device)
	if workspace:FindFirstChild(player.Name) and ore then
		if state == "Start" then
			if ore:FindFirstChild("Owner") then
				ore.Owner.Value = player.Name
			else
				local tagOwner = Instance.new("StringValue")
				tagOwner.Name = "Owner"
				tagOwner.Parent = ore
				tagOwner.Value = player.Name
			end
			local miningSound = Sounds.MiningSound:Clone()
			miningSound.Parent = ore
			local speedIncr = 0.2
			local soundDelay = 0.5 / (pickaxePower / 5)
			miningSound.PlaybackSpeed = (speedIncr * pickaxePower) * miningSound.TimeLength
			wait(soundDelay)
			miningSound:Play()
		end
		if state == "Cancel" then
			if ore:FindFirstChild("Owner") then
				ore.Owner.Value = ""
			else
				local tagOwner = Instance.new("StringValue")
				tagOwner.Name = "Owner"
				tagOwner.Parent = ore
				tagOwner.Value = ""
			end
			if ore:FindFirstChild("MiningSound") then
				ore.MiningSound:Destroy()
			end
		end
		if state == "End" then
			addOre(player,ore,1,device)
			local cordX = ore.Position.X
			local cordY = ore.Position.Y
			local cordZ = ore.Position.Z
			ore:Destroy()
			placeAir(cordX,cordY,cordZ) -- x,y,z in normal size
		end
	end
end
mineRemote.OnServerEvent:Connect(playerMines)



function playerJoins(player)
	local playerFolder = script.PlayerFolder:Clone()
	playerFolder.Name = player.Name
	playerFolder.Parent = playerFolders
	local WSF_Folder = Instance.new("Folder") -- For pickaxes to go into
	WSF_Folder.Name = player.Name
	WSF_Folder.Parent = WSF
end
players.PlayerAdded:Connect(playerJoins)



function testNoise() -- Tests for new cave system
	local testSize = 32
	local testOffsetX = -80
	local testOffsetY = 500
	local testOffsetZ = -80

	local seed = math.random(10000,99999) / 100000 -- Creates a random cave preset
	local noiseFreq = -0.5 -- Decides the percentage of air (-1.5 = 0%, 1.5 = 100%)
	local noiseScale = 15 -- The bigger this is, the bigger caves will be in scale

	for orderX = 1,testSize do -- Uses for xyz for each coordinate
		for orderY = 1,testSize do
			for orderZ = 1,testSize do
				local cordX = orderX * oreSize -- Sets coordinates for the location
				local cordY = orderY * oreSize
				local cordZ = orderZ * oreSize
				local noiseX = orderX / noiseScale -- Sets the scale of the noise
				local noiseY = orderY / noiseScale
				local noiseZ = orderZ / noiseScale
				local densityX = math.noise(seed,noiseY,noiseZ) -- Goes along each axis to get its noise and adds it up to get a density
				local densityY = math.noise(noiseX,seed,noiseZ)
				local densityZ = math.noise(noiseX,noiseY,seed)
				local density = (densityX + densityY + densityZ)
				if density > noiseFreq then -- If dense enough it places stone
					placeStone(cordX + testOffsetX,cordY + testOffsetY,cordZ + testOffsetZ) -- x,y,z in normal size
				end
			end
		end
		wait()
	end
end



function changeSeason(season) -- To change to auttumn or winter
	local treeFolder = AreaFolder.Trees
	local grassFolder = AreaFolder.Grass
	local snowFolder = AreaFolder.Snow
	if season == "Normal" then
		for index, grassPart in pairs(grassFolder:GetChildren()) do
			grassPart.Material = Enum.Material.Grass
			wait()
		end
		for index, tree in pairs(treeFolder:GetChildren()) do
			if tree.Name == "Tree" then
				local random = math.random(1,5)
				if random == 1 then
					tree.Leaves.BrickColor = BrickColor.new("Shamrock")
				end
				if random == 2 then
					tree.Leaves.BrickColor = BrickColor.new("Sea green")
				end
				if random == 3 then
					tree.Leaves.BrickColor = BrickColor.new("Parsley green")
				end
				if random == 4 then
					tree.Leaves.BrickColor = BrickColor.new("Carnation pink")
				end
				if random == 5 then
					tree.Leaves.BrickColor = BrickColor.new("Deep orange")
				end
			end
			if tree.Name == "Pine" then
				local random = math.random(1,3)
				if random == 1 then
					tree.Leaves.BrickColor = BrickColor.new("Parsley green")
				end
				if random == 2 then
					tree.Leaves.BrickColor = BrickColor.new("Earth green")
				end
				if random == 3 then
					tree.Leaves.BrickColor = BrickColor.new("Slime green")
				end
			end
			wait()
		end
	end
	if season == "Auttumn" then
		for index, grassPart in pairs(grassFolder:GetChildren()) do
			grassPart.BrickColor = BrickColor.new("CGA brown")
			grassPart.Material = Enum.Material.LeafyGrass
			wait()
		end
		for index, tree in pairs(treeFolder:GetChildren()) do
			if tree.Name == "Tree" then
				local random = math.random(1,7)
				if random == 1 then
					tree.Leaves.BrickColor = BrickColor.new("Neon orange")
				end
				if random == 2 then
					tree.Leaves.BrickColor = BrickColor.new("CGA brown")
				end
				if random == 3 then
					tree.Leaves.BrickColor = BrickColor.new("Dark orange")
				end
				if random == 4 then
					tree.Leaves.BrickColor = BrickColor.new("Burgundy")
				end
				if random == 5 then
					tree.Leaves.BrickColor = BrickColor.new("Bright red")
				end
				if random == 6 then
					tree.Leaves.BrickColor = BrickColor.new("Br. yellowish orange")
				end
				if random == 7 then
					tree.Leaves.BrickColor = BrickColor.new("Deep orange")
				end
			end
			wait()
		end
	end
	if season == "Winter" then
		for index, grassPart in pairs(grassFolder:GetChildren()) do
			grassPart.BrickColor = BrickColor.new("White")
			grassPart.Material = Enum.Material.Snow
			wait()
		end
		for index, tree in pairs(treeFolder:GetChildren()) do
			if tree.Name == "Tree" then
				local random = math.random(1,5)
				if random < 5 then
					tree.Leaves:Destroy()
				else
					tree.Leaves.BrickColor = BrickColor.new("White")
					tree.Leaves.Material = Enum.Material.Snow
				end
			end
			if tree.Name == "Pine" then
				tree.Leaves.BrickColor = BrickColor.new("White")
				tree.Leaves.Material = Enum.Material.Snow
			end
			wait()
		end
		for index, snowPart in pairs(snowFolder:GetChildren()) do
			snowPart.Transparency = 0
			snowPart.CanCollide = false
		end
	end
end



frames = 0
function runFunction()
	frames += 1
end
runService.Heartbeat:Connect(runFunction)



coroutine.resume(coroutine.create(function() -- Responsive trottle
	while wait(1) do
		if frames > 50 then
			trotMax = 512
			print(trotMax)
		else
			if frames > 40 then
				trotMax = 256
				print(trotMax)
			else
				if frames > 30 then
					trotMax = 128
					print(trotMax)
				else
					if frames > 20 then
						trotMax = 64
						print(trotMax)
					else
						if frames > 10 then
							trotMax = 32
							print(trotMax)
						else
							trotMax = 16
							print(trotMax)
						end
					end
				end
			end
		end
		frames = 0
	end
end))



--month = os.date("%b") -- %b: month avbr
--season = "Normal"
--if month == "Sep" or month == "Okt"  or month == "Nov" then -- Auttumn: Sep-Okt
--	changeSeason("Auttumn")
--	season = "Auttumn"
--else if month == "Dec" or month == "Jan" or month == "Feb" then
--		changeSeason("Winter")
--		season = "Winter"
--	else
--		changeSeason("Normal")
--		season = "Normal"
--	end
--end

changeSeason("Normal")
season = "Normal"

generateNewMine() -- Generate the first mine
