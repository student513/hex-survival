local HexConstants = {
	HEX_SIZE = 8.66,
	HEX_HEIGHT = 0.6,

	FLOORS_COUNT = 8,
	FLOOR_DISTANCE = 30, -- 층간 간격
	START_HEIGHT = 100,  -- 1층 시작 높이

	GRID_SIZE = 8,

	GET_DELAY_TIME = function(floorLevel: number)
		return 0.3 + (floorLevel - 1) * (0.7 / 7)
	end
}

return HexConstants