-- 엄격한 타입 체크 모드 사용
local CollectionService = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")

local FloorService = {}

-- 발판 설정값 (나중에 층별로 다르게 설정할 수 있습니다)
local DELAY_TIME = 1.0

-- 발판 소멸 로직 함수
local function handleTouch(part: BasePart)
	-- 이미 누군가 밟아서 색이 변하기 시작했다면 무시 (중복 실행 방지)
	if part:GetAttribute("IsStepped") then return end
	part:SetAttribute("IsStepped", true)

	-- 1. 시각 효과: 색상을 붉게 변경 (TweenService 활용)
	local tweenInfo = TweenInfo.new(DELAY_TIME)
	local tween = TweenService:Create(part, tweenInfo, {
		Color = Color3.fromRGB(255, 100, 100), -- 붉은색으로
		Transparency = 0.5 -- 약간 투명하게
	})
	tween:Play()

	-- 2. 대기 및 소멸
	task.wait(DELAY_TIME)

	part.CanCollide = false -- 통과 가능하게 (밑으로 떨어짐)
	part.Transparency = 1   -- 투명하게 (사라짐)

	-- 3. 일정 시간 뒤 복구 (테스트용)
	task.wait(3)
	part.CanCollide = true
	part.Transparency = 0
	part.Color = Color3.fromRGB(163, 162, 165) -- 원래 색상으로 (기본 회색)
	part:SetAttribute("IsStepped", false)
end

-- 서비스 시작 함수
function FloorService.init()
	-- 'HexPlatform' 태그가 달린 모든 객체를 찾아서 이벤트를 연결합니다.
	for _, part in CollectionService:GetTagged("HexPlatform") do
		if part:IsA("BasePart") then
			part.Touched:Connect(function(hit)
				-- 밟은 대상이 플레이어 캐릭터인지 확인
				if hit.Parent:FindFirstChild("Humanoid") then
					handleTouch(part)
				end
			end)
		end
	end
end

return FloorService