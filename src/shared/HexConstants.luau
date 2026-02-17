local HexConstants = {
	HEX_SIZE = 8.66,
	HEX_HEIGHT = 0.6,
	FLOORS_COUNT = 8,
	FLOOR_DISTANCE = 30,
	START_HEIGHT = 100,
	GRID_SIZE = 8,

	MIN_PLAYERS = 1,
	MAX_PLAYERS = 12,
	COUNTDOWN_TIME = 100,
	INTERMISSION_TIME = 7,

	-- [아이템 밸런스 설정]
	ITEM_SPAWN_CHANCE = 5,    -- 아이템 생성 확률 (%)
	STUN_DURATION = 2,         -- 망치 스턴 지속 시간 (2초)
	GLUE_MULTIPLIER = 1.5,     -- 접착제 소멸 시간 배율 (1.5배)
	BAT_KNOCKBACK = 150,       -- 야구배트 밀치기 강도

	SPECIAL_FLOOR_CHANCE = 25,

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