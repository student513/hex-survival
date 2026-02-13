local HexConstants = {
	HEX_SIZE = 8.66,
	HEX_HEIGHT = 0.6,
	FLOORS_COUNT = 8,
	FLOOR_DISTANCE = 30,
	START_HEIGHT = 100,
	GRID_SIZE = 8,

	-- [추가] 변종 층 설정
	SPECIAL_FLOOR_CHANCE = 100, -- 변종 층이 생성될 확률 (%)

	-- 타입별 시각 설정 (직관성 극대화)
	FLOOR_SETTINGS = {
		Normal = { Color = Color3.fromRGB(163, 162, 165), Material = Enum.Material.Plastic },
		Magma  = { Color = Color3.fromRGB(255, 80, 0), Material = Enum.Material.Neon },
		Bounce = { Color = Color3.fromRGB(100, 255, 100), Material = Enum.Material.Rubber },
		Turbo  = { Color = Color3.fromRGB(255, 255, 0), Material = Enum.Material.Neon }
	},

	GET_DELAY_TIME = function(floorLevel: number)
		return 0.3 + (floorLevel - 1) * (0.7 / 7)
	end
}

return HexConstants