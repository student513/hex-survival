local CollectionService = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")

local FloorService = {}

local function handleTouch(part: BasePart)
	if part:GetAttribute("IsStepped") then return end
	part:SetAttribute("IsStepped", true)

	local delayTime = part:GetAttribute("DelayTime") or 1.0

	-- 붉게 변하는 효과
	local tweenInfo = TweenInfo.new(delayTime)
	local tween = TweenService:Create(part, tweenInfo, {
		Color = Color3.fromRGB(255, 100, 100),
		Transparency = 0.8
	})
	tween:Play()

	task.wait(delayTime)

	part.CanCollide = false
	part.Transparency = 1
	task.delay(1, function() part:Destroy() end)
end

function FloorService.init()
	local function connectPart(part)
		if part:IsA("BasePart") then
			part.Touched:Connect(function(hit)
				if hit.Parent:FindFirstChild("Humanoid") then
					handleTouch(part)
				end
			end)
		end
	end

	for _, part in CollectionService:GetTagged("HexPlatform") do
		connectPart(part)
	end
	CollectionService:GetInstanceAddedSignal("HexPlatform"):Connect(connectPart)
end

return FloorService