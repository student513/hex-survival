local CollectionService = game:GetService('CollectionService')
local Players = game:GetService('Players')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local UpdateStatus = ReplicatedStorage:WaitForChild("UpdateStatus")

-- [중요] 자동 부활을 끕니다.
Players.CharacterAutoLoads = false

local GameService = {}
local MIN_PLAYERS = 2 -- 테스트 시 2명 권장
local MAX_PLAYERS = 8
local COUNTDOWN_TIME = 10

function GameService.init()
    Players.PlayerAdded:Connect(function(player)
        -- 처음 접속 시 캐릭터 로드
        player:LoadCharacter()
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
    GameService.init() -- 접속 감지 시작

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

        -- 4. Survival Tracking
        local winner = nil
        while true do
            local alivePlayers = {}
            local allPlayers = Players:GetPlayers()

            for _, player in ipairs(allPlayers) do
                local char = player.Character
                if char then
                    local humanoid = char:FindFirstChild("Humanoid")
                    if humanoid and humanoid.Health > 0 then
                        table.insert(alivePlayers, player)
                    end
                end
            end

            UpdateStatus:FireAllClients("UpdateSurvival", #alivePlayers)

            -- 최후의 1인 판정
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

        task.wait(5) -- 결과 감상 시간
        -- [중요] 다음 라운드를 위해 캐릭터 재생성 및 루프 반복
        for _, p in ipairs(Players:GetPlayers()) do
            p:LoadCharacter()
        end
    end
end

return GameService