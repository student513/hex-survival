local CollectionService = game:GetService('CollectionService')
local Players = game:GetService('Players')
local TweenService = game:GetService('TweenService')
local ItemManager = require(script.Parent.ItemManager)
local LeaderManager = require(script.Parent.LeaderManager)
local SpecialTileLogic = require(script.Parent.SpecialTileLogic)

local FloorService = {}

local function handleFloorTouch(part: BasePart, character: Model)
	if part:GetAttribute("IsStepped") then return end
	part:SetAttribute("IsStepped", true)

	local delayTime = part:GetAttribute("DelayTime") or 1.0
	local isParkour = part:GetAttribute("IsParkour")
	local isParkourGoal = part:GetAttribute("IsParkourGoal")

	if isParkourGoal then
		local player = Players:GetPlayerFromCharacter(character)
		if player then
			LeaderManager.grantTitle(player, "⚡ JUMP MASTER", Color3.fromRGB(255, 200, 50))
		end
	end

	local humanoid = character:FindFirstChild("Humanoid")
	local floorFolder = part.Parent
	if floorFolder and humanoid and humanoid:IsA("Humanoid") then
		local floorType = floorFolder:GetAttribute("FloorType") or "Normal"
		SpecialTileLogic.applyEffect(humanoid, floorType)
	end

	local tween = TweenService:Create(part, TweenInfo.new(delayTime), {
		Color = Color3.fromRGB(255, 100, 100), Transparency = 0.8
	})
	tween:Play()

	task.wait(delayTime)
	part.CanCollide = false
	part.Transparency = 1

	if isParkour then
		task.wait(1)
		part.CanCollide = true
		part.Transparency = 0
		part.Color = Color3.fromRGB(0, 170, 255)
		part:SetAttribute("IsStepped", false)
	else
		task.delay(1, function() if part then part:Destroy() end end)
	end
end

local function handleItemTouch(item: BasePart)
	local connection
	connection = item.Touched:Connect(function(hit)
		local character = hit.Parent
		local player = Players:GetPlayerFromCharacter(character)

		if player then
			local itemType = item:GetAttribute("ItemType")
			if itemType then
				local parentInstance = item.Parent
				local floorPart = nil
				if parentInstance and parentInstance:IsA("BasePart") then
					floorPart = parentInstance
				end

				ItemManager.giveItem(player, itemType, floorPart)
				connection:Disconnect()
				item:Destroy()
			end
		end
	end)
end

function FloorService.init()
	local function connectPlatform(part)
		part.Touched:Connect(function(hit)
			local character = hit.Parent
			if character and character:FindFirstChild("Humanoid") then
				handleFloorTouch(part, character)
			end
		end)
	end

	local function connectItem(item)
		if item:IsA("BasePart") then handleItemTouch(item) end
	end

	for _, part in CollectionService:GetTagged("HexPlatform") do connectPlatform(part) end
	CollectionService:GetInstanceAddedSignal("HexPlatform"):Connect(connectPlatform)

	for _, item in CollectionService:GetTagged("ItemObject") do connectItem(item) end
	CollectionService:GetInstanceAddedSignal("ItemObject"):Connect(connectItem)
end

return FloorService