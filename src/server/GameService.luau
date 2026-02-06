local CollectionService = game:GetService('CollectionService')
local Players = game:GetService('Players')
local ReplicatedStorage = game:GetService('ReplicatedStorage')

local UpdateStatus = ReplicatedStorage:WaitForChild("UpdateStatus")

local GameService = {}

-- 기획 설정값
local MIN_PLAYERS = 1 -- 테스트용 (실제 출시 시 8로 변경)
local MAX_PLAYERS = 8
local COUNTDOWN_TIME = 10

function GameService.startLoop()
	print("게임 루프 가동 중...")

	while true do
		-- 1. 인원 대기 단계
		repeat
			local currentCount = #Players:GetPlayers()
			-- 서버가 모든 클라이언트에게 현재 인원 정보 전송
			UpdateStatus:FireAllClients("Waiting", currentCount, MAX_PLAYERS)
			task.wait(1)
		until #Players:GetPlayers() >= MIN_PLAYERS

		-- 2. 카운트다운 단계
		for i = COUNTDOWN_TIME, 1, -1 do
			UpdateStatus:FireAllClients("Countdown", i)
			task.wait(1)
		end

		-- 3. 게임 시작 (투하!)
		UpdateStatus:FireAllClients("Start")
		GameService.releasePlayers()

		-- 일단 한 판이 시작되면 대기 (나중에 승리 로직 추가 시 루프 재설정)
		break
	end
end

function GameService.releasePlayers()
	local lobbyParts = CollectionService:GetTagged("LobbyTag")
	for _, part in lobbyParts do
		if part:IsA("BasePart") then
			part.CanCollide = false
			part.Transparency = 1
			task.delay(1, function() part:Destroy() end)
		end
	end
end

return GameService