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
    while true do
        -- 1. Waiting for players
        repeat
            local currentCount = #Players:GetPlayers()
            UpdateStatus:FireAllClients("Waiting", currentCount, MAX_PLAYERS)
            task.wait(1)
        until #Players:GetPlayers() >= MIN_PLAYERS

        -- 2. Countdown
        for i = COUNTDOWN_TIME, 1, -1 do
            UpdateStatus:FireAllClients("Countdown", i)
            task.wait(1)
        end

        -- 3. Game Start
        UpdateStatus:FireAllClients("Start")
        GameService.releasePlayers()

        -- 4. Survival Tracking (생존 인원 체크 루프)
        -- 실제로는 캐릭터가 죽거나 맵 밖으로 나갈 때 체크해야 하지만,
        -- 우선은 실시간으로 인원수를 보내주는 로직을 가동합니다.
        while #Players:GetPlayers() > 0 do
            local aliveCount = #Players:GetPlayers()
            UpdateStatus:FireAllClients("UpdateSurvival", aliveCount)
            task.wait(0.5)

            -- 최후의 1인이 남으면 루프 종료 (나중에 승리 로직 추가)
            if aliveCount <= 1 and MIN_PLAYERS > 1 then break end
        end

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