--
local ServerScriptService = game:GetService("ServerScriptService")

local FloorService = require(script:WaitForChild("FloorService"))
local MapService = require(script:WaitForChild("MapService"))

print("서버 시스템 초기화 중...")

-- 1. 먼저 맵을 생성합니다.
MapService.generateMap()

-- 2. 생성된 맵의 발판들에 터치 이벤트를 연결합니다.
FloorService.init()

print("헥사 서바이벌 준비 완료!")