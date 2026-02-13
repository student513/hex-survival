local FloorService = require(script:WaitForChild('FloorService'))
local GameService = require(script:WaitForChild('GameService'))
local MapService = require(script:WaitForChild('MapService'))

print("서버 시스템 초기화 중...")

-- 1. 기초 맵 데이터 및 환경 생성
MapService.generateMap()
MapService.createKillZone()
FloorService.init()

-- 2. 게임 루프 시작
-- 루프의 Phase 0에서 대기실과 랭킹 UI가 자동으로 생성되므로 초기 호출은 필요 없습니다.
task.spawn(function()
	GameService.startLoop()
end)

print("헥사 서바이벌 모든 시스템 준비 완료!")