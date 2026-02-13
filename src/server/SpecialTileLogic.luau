local SpecialTileLogic = {}

-- 로블록스 기본 능력치
local DEFAULT_SPEED = 16
local DEFAULT_JUMP = 50
local BOUNCE_MULTIPLIER = 1.5

function SpecialTileLogic.applyEffect(humanoid: Humanoid, floorType: string)
	if not humanoid then return end

	-- [수정] 모든 타일의 공통 사항: 다른 타일을 밟으면 즉시 상태 초기화
	humanoid.WalkSpeed = DEFAULT_SPEED
	humanoid.UseJumpPower = true
	humanoid.JumpPower = DEFAULT_JUMP

	-- [수정] 타입별 특수 효과 적용
	if floorType == "Turbo" then
		humanoid.WalkSpeed = 45 -- 과도하게 빠른 속도
	elseif floorType == "Bounce" then
		-- [수정] 요청대로 점프력만 1.5배 상승 (다음 타일 밟으면 초기화됨)
		humanoid.JumpPower = DEFAULT_JUMP * BOUNCE_MULTIPLIER
	end
end

return SpecialTileLogic