local FloorService = require(script:WaitForChild('FloorService'))
local GameService = require(script:WaitForChild('GameService'))
local MapService = require(script:WaitForChild('MapService'))

print("서버 시스템 초기화 중...")

-- 1. 기초 환경 구축
MapService.createKillZone()
FloorService.init()

-- 2. 게임 루프 시작
task.spawn(function()
	GameService.startLoop()
end)

print("헥사 서바이벌 모든 시스템 준비 완료!")