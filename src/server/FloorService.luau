--
local CollectionService = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")

local FloorService = {}

local function handleTouch(part: BasePart)
	if part:GetAttribute("IsStepped") then return end
	part:SetAttribute("IsStepped", true)

	local delayTime = part:GetAttribute("DelayTime") or 1.0

	-- 1. 시각 효과 (붉게 변함)
	local tweenInfo = TweenInfo.new(delayTime)
	local tween = TweenService:Create(part, tweenInfo, {
		Color = Color3.fromRGB(255, 100, 100),
		Transparency = 0.8 -- 완전히 투명해지기 전 예고
	})
	tween:Play()

	-- 2. 대기
	task.wait(delayTime)

	-- 3. 영구 소멸 로직
	part.CanCollide = false
	part.Transparency = 1

	-- 서버 성능을 위해 1초 뒤에 아예 삭제해버립니다.
	task.delay(1, function()
		part:Destroy()
	end)
end

function FloorService.init()
	for _, part in CollectionService:GetTagged("HexPlatform") do
		if part:IsA("BasePart") then
			part.Touched:Connect(function(hit)
				if hit.Parent:FindFirstChild("Humanoid") then
					handleTouch(part)
				end
			end)
		end
	end
end

return FloorService