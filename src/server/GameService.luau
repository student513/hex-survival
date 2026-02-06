--
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")

local GameService = {}

-- 설정값
local MIN_PLAYERS = 1 -- 테스트를 위해 1명으로 설정 (나중에 8로 변경)
local COUNTDOWN_TIME = 10

function GameService.startLoop()
	print("게임 루프 시작 대기 중...")

	while true do
		-- 1. 인원 충족 대기
		repeat
			task.wait(1)
		until #Players:GetPlayers() >= MIN_PLAYERS

		print("인원이 충족되었습니다. 카운트다운 시작!")

		-- 2. 카운트다운 (나중에 화면 UI에 표시할 예정)
		for i = COUNTDOWN_TIME, 1, -1 do
			print("게임 시작까지: " .. i)
			task.wait(1)
		end

		-- 3. 대기실 바닥 제거 (투하!)
		print("투하!!!")
		GameService.releasePlayers()

		-- 일단 한 판이 시작되면 루프를 잠시 멈추거나
		-- 나중에 승리자 판정 로직이 들어갈 곳입니다.
		break
	end
end

function GameService.releasePlayers()
	local lobbyParts = CollectionService:GetTagged("LobbyTag")
	for _, part in lobbyParts do
		if part:IsA("BasePart") then
			part.CanCollide = false
			part.Transparency = 1
		end
	end
end

return GameService