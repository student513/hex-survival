local CollectionService = game:GetService('CollectionService')
local Players = game:GetService('Players')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local UpdateStatus = ReplicatedStorage:WaitForChild("UpdateStatus")

-- [중요] 자동 부활 방지 및 시스템 설정
Players.CharacterAutoLoads = false

local GameService = {}
local MIN_PLAYERS = 8  -- Phase 1 기준 인원
local MAX_PLAYERS = 12 -- Phase 3 최대 인원
local COUNTDOWN_TIME = 15

local isGameStarted = false

function GameService.init()
    Players.PlayerAdded:Connect(function(player)
        local currentCount = #Players:GetPlayers()
        -- 정원 및 게임 진행 상태 체크
        if not isGameStarted and currentCount <= MAX_PLAYERS then
            player:LoadCharacter()
        else
            warn(player.Name .. " joined but match is full or in progress.")
        end
    end)
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

function GameService.startLoop()
    GameService.init()

    while true do
        isGameStarted = false

        -- 1. Phase 1: Idle (인원 대기)
        repeat
            local currentCount = #Players:GetPlayers()
            UpdateStatus:FireAllClients("Waiting", currentCount, MIN_PLAYERS)
            task.wait(1)
        until #Players:GetPlayers() >= MIN_PLAYERS

        -- 2. Phase 2: Pre-Start (시작 예고)
        UpdateStatus:FireAllClients("PreStart")
        task.wait(2)

        -- 3. Phase 3: Late Entry (메인 카운트다운)
        for i = COUNTDOWN_TIME, 1, -1 do
            local currentCount = #Players:GetPlayers()
            -- [MAX_PLAYERS 활용] 12명 꽉 차면 즉시 시작
            if currentCount >= MAX_PLAYERS then
                UpdateStatus:FireAllClients("Countdown", "FULL!", currentCount)
                task.wait(1)
                break
            end
            UpdateStatus:FireAllClients("Countdown", i, currentCount)
            task.wait(1)
        end

        -- 4. Game Start
        isGameStarted = true
        UpdateStatus:FireAllClients("Start")
        GameService.releasePlayers()

        -- 5. Survival Tracking (최후의 1인 판정)
        local winner = nil
        while true do
            local alivePlayers = {}
            local allPlayers = Players:GetPlayers()

            for _, player in ipairs(allPlayers) do
                local char = player.Character
                if char and char:FindFirstChild("Humanoid") and char.Humanoid.Health > 0 then
                    table.insert(alivePlayers, player)
                end
            end

            UpdateStatus:FireAllClients("UpdateSurvival", #alivePlayers)

            if #alivePlayers <= 1 and #allPlayers >= 1 then
                winner = alivePlayers[1] or allPlayers[1]
                for _, p in ipairs(allPlayers) do
                    local result = (p == winner) and "Victory" or "Defeat"
                    UpdateStatus:FireClient(p, "Result", result, winner.Name)
                end
                break
            end
            task.wait(0.5)
        end

        -- 6. [신규] 명예의 전당 (Intermission) - 7초간 승리자 클로즈업
        for i = 7, 1, -1 do
            UpdateStatus:FireAllClients("IntermissionCountdown", i)
            task.wait(1)
        end

        -- 7. [신규] 로비 복귀 (Round Over) - 3초간 시퀀스
        UpdateStatus:FireAllClients("RoundOver")
        task.wait(3)

        -- 다음 라운드 준비 (캐릭터 재생성)
        for _, p in ipairs(Players:GetPlayers()) do
            p:LoadCharacter()
        end
    end
end

return GameService