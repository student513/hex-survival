--
local ServerScriptService = game:GetService("ServerScriptService")

local FloorService = require(script:WaitForChild('FloorService'))
local GameService = require(script:WaitForChild('GameService'))
local MapService = require(script:WaitForChild('MapService'))

print("서버 시스템 초기화 중...")

-- 1. 맵 생성
MapService.generateMap()
MapService.createLobby() -- 대기실 세트(바닥+벽+스폰) 생성
-- 2. 발판 이벤트 연결
FloorService.init()

-- 3. 게임 루프 시작 (대기실 로직 가동)
task.spawn(function()
	GameService.startLoop()
end)

print("헥사 서바이벌 모든 시스템 준비 완료!")