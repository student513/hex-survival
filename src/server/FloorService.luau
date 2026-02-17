local CollectionService = game:GetService('CollectionService')
local Players = game:GetService('Players')
local TweenService = game:GetService('TweenService')
local ItemManager = require(script.Parent.ItemManager)
local SpecialTileLogic = require(script.Parent.SpecialTileLogic)

local FloorService = {}

local function handleFloorTouch(part: BasePart, character: Model)
	if part:GetAttribute("IsStepped") then return end
	part:SetAttribute("IsStepped", true)

	local humanoid = character:FindFirstChild("Humanoid")
	local floorFolder = part.Parent
	if not floorFolder then return end

	local floorType = floorFolder:GetAttribute("FloorType") or "Normal"
	if humanoid and humanoid:IsA("Humanoid") then
		SpecialTileLogic.applyEffect(humanoid, floorType)
	end

	local delayTime = part:GetAttribute("DelayTime") or 1.0
	local tween = TweenService:Create(part, TweenInfo.new(delayTime), {
		Color = Color3.fromRGB(255, 100, 100), Transparency = 0.8
	})
	tween:Play()

	task.wait(delayTime)
	part.CanCollide = false
	part.Transparency = 1
	task.delay(1, function() if part then part:Destroy() end end)
end

local function handleItemTouch(item: BasePart)
	local connection
	connection = item.Touched:Connect(function(hit)
		local character = hit.Parent
		local player = Players:GetPlayerFromCharacter(character)

		if player then
			local itemType = item:GetAttribute("ItemType")
			if itemType then
				-- [에러 수정] item.Parent를 BasePart로 타입 체크 후 전달
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