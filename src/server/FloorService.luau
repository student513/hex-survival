local CollectionService = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")
local SpecialTileLogic = require(script.Parent.SpecialTileLogic)

local FloorService = {}

local function handleTouch(part: BasePart, character: Model)
	if part:GetAttribute("IsStepped") then return end
	part:SetAttribute("IsStepped", true)

	local humanoid = character:FindFirstChild("Humanoid")
	local floorFolder = part.Parent
	if not floorFolder then return end

	-- [수정] 모든 발판 터치 시 효과 적용 (Normal이면 초기화됨)
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

function FloorService.init()
	local function connectPart(part)
		part.Touched:Connect(function(hit)
			local character = hit.Parent
			if character and character:FindFirstChild("Humanoid") then
				handleTouch(part, character)
			end
		end)
	end

	for _, part in CollectionService:GetTagged("HexPlatform") do connectPart(part) end
	CollectionService:GetInstanceAddedSignal("HexPlatform"):Connect(connectPart)
end

return FloorService