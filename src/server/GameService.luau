local CollectionService = game:GetService('CollectionService')
local Players = game:GetService('Players')
local ReplicatedStorage = game:GetService('ReplicatedStorage')

local UpdateStatus = ReplicatedStorage:WaitForChild("UpdateStatus")

local GameService = {}

-- 기획 설정값
local MIN_PLAYERS = 1 -- 테스트용 (실제 출시 시 8로 변경)
local MAX_PLAYERS = 8
local COUNTDOWN_TIME = 10

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

--
function GameService.setupSurvivalTracking()
    -- 플레이어가 죽거나 나갈 때마다 생존 인원을 체크하여 UI 전송
    local function updateCount()
        local aliveCount = 0
        for _, player in ipairs(game.Players:GetPlayers()) do
            -- 캐릭터가 존재하고 체력이 0보다 큰 경우만 생존자로 간주
            local char = player.Character
            if char and char:FindFirstChild("Humanoid") and char.Humanoid.Health > 0 then
                aliveCount += 1
            end
        end
        game.ReplicatedStorage.UpdateStatus:FireAllClients("UpdateSurvival", aliveCount)
    end

    -- 새로운 플레이어가 접속했을 때 죽음 감지 이벤트 연결
    game.Players.PlayerAdded:Connect(function(player)
        player.CharacterAppearanceLoaded:Connect(function(character)
            local humanoid = character:WaitForChild("Humanoid")
            humanoid.Died:Connect(updateCount) -- 죽으면 갱신
        end)
    end)

    -- 플레이어가 서버를 나갈 때도 갱신
    game.Players.PlayerRemoving:Connect(updateCount)
end
--
function GameService.startLoop()
    while true do
        -- 1. Waiting for players (동일)
        repeat
            local currentCount = #Players:GetPlayers()
            UpdateStatus:FireAllClients("Waiting", currentCount, MAX_PLAYERS)
            task.wait(1)
        until #Players:GetPlayers() >= MIN_PLAYERS

        -- 2. Countdown (동일)
        for i = COUNTDOWN_TIME, 1, -1 do
            UpdateStatus:FireAllClients("Countdown", i)
            task.wait(1)
        end

        -- 3. Game Start
        UpdateStatus:FireAllClients("Start")
        GameService.releasePlayers()

        -- 4. Survival Tracking (수정된 루프)
        -- 캐릭터의 체력을 직접 체크하여 실제 살아있는 인원만 카운트합니다.
        while true do
            local aliveCount = 0
            local allPlayers = Players:GetPlayers()

            for _, player in ipairs(allPlayers) do
                local char = player.Character
                if char then
                    local humanoid = char:FindFirstChild("Humanoid")
                    -- 캐릭터가 있고 체력이 0보다 큰 경우만 생존자로 인정
                    if humanoid and humanoid.Health > 0 then
                        aliveCount += 1
                    end
                end
            end

            -- UI 업데이트
            UpdateStatus:FireAllClients("UpdateSurvival", aliveCount)

            -- 승리 조건: 1명 이하로 남았을 때 (테스트 인원이 1명 이상일 때만 작동)
            if aliveCount <= 1 and #allPlayers > 1 then
                print("Game Over! Winner found.")
                break
            end

            task.wait(0.5)
        end

        -- 게임 종료 후 처리 (승리 UI 등)를 위해 루프 탈출
        break
    end
end

return GameService