--
local HexConstants = {
	-- 발판 크기 설정
	HEX_SIZE = 6, -- 발판의 가로/세로 크기
	HEX_HEIGHT = 1, -- 발판의 두께

	-- 맵 구조 설정
	FLOORS_COUNT = 8, -- 총 층수
	FLOOR_DISTANCE = 15, -- 층과 층 사이의 높이 간격
	GRID_SIZE = 10, -- 한 층의 가로/세로 발판 개수 (반지름 개념)

	-- 층별 소멸 대기 시간 (8층은 1초, 1층은 0.3초)
	GET_DELAY_TIME = function(floorLevel: number)
		-- 8층에서 1층으로 갈수록 시간이 줄어드는 공식
		return 0.3 + (floorLevel - 1) * (0.7 / 7)
	end
}

return HexConstants