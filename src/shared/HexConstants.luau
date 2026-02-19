local HexConstants = {
	HEX_SIZE = 8.66,
	HEX_HEIGHT = 0.6,
	FLOORS_COUNT = 8,
	FLOOR_DISTANCE = 30,
	START_HEIGHT = 100,
	GRID_SIZE = 8,

	MIN_PLAYERS = 8, -- [수정] 기획에 맞춘 최소 인원 (테스트 시 2로 변경하세요)
	MAX_PLAYERS = 12,
	COUNTDOWN_TIME = 10, -- 매치 시작 전 대기 카운트다운
	INTERMISSION_TIME = 7, -- 라운드 사이 인터미션
	MATCH_END_TIME = 10,

	MATCH_WIN_TARGET = 3, -- [수정] 3선승제

	-- [위치 설정]
	MAIN_LOBBY_POS = Vector3.new(0, 100, 200), -- 맵과 분리된 메인 로비
	GAME_LOBBY_POS = Vector3.new(0, 500, 0),   -- 맵 최상단 매치 로비
	KILL_ZONE_Y = 20,

	ITEM_SPAWN_CHANCE = 2,
	STUN_DURATION = 2,
	GLUE_MULTIPLIER = 1.5,
	SPECIAL_FLOOR_CHANCE = 10,

	GET_DELAY_TIME = function(floorLevel: number)
		return 0.3 + (floorLevel - 1) * (0.7 / 7)
	end,

	ITEM_ICONS = {
		Glue = "rbxassetid://121297864270651",
		Swapper = "rbxassetid://89827382289584",
		Hammer = "rbxassetid://109958366988278"
	},

	BGM_IDS = {
		Lobby = "rbxassetid://97746192820599", -- 예: "rbxassetid://1837854359"
		Match = "rbxassetid://137827158863747"
	},
	BGM_VOLUME = 0.5,
}
return HexConstants