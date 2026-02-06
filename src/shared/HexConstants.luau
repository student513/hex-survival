local HexConstants = {
	HEX_SIZE = 8.66,
	HEX_HEIGHT = 0.6,

	FLOORS_COUNT = 8,

	-- [수정] 층간 간격을 2배로 (15 -> 30)
	FLOOR_DISTANCE = 30,

	-- [추가] 1층이 지면으로부터 얼마나 떨어져 있을지 설정 (아주 높게 설정)
	START_HEIGHT = 100,

	GRID_SIZE = 8,

	GET_DELAY_TIME = function(floorLevel: number)
		return 0.3 + (floorLevel - 1) * (0.7 / 7)
	end
}

return HexConstants