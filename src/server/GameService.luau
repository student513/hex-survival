local CollectionService = game:GetService('CollectionService')
local Players = game:GetService('Players')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local UpdateStatus = ReplicatedStorage:WaitForChild("UpdateStatus")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local HexConstants = require(Shared:WaitForChild("HexConstants"))
local LeaderManager = require(script.Parent.LeaderManager)
local MapService = require(script.Parent.MapService)

Players.CharacterAutoLoads = false

local GameService = {}
local isMatchRunning = false
local activeMatchPlayers = {} -- 현재 매치에 참여 중인 플레이어 목록
local matchPoints = {} -- {score = 0, lastWinTime = 0}

function GameService.init()
	Players.PlayerAdded:Connect(function(player)
		player.CharacterAdded:Connect(function(char)
			task.wait(0.1)
			-- 매치가 진행 중이고, 참여자 명단에 있다면 매치 로비로, 아니면 무조건 메인 로비로 전송
			if isMatchRunning and activeMatchPlayers[player.Name] then
				char:PivotTo(CFrame.new(HexConstants.GAME_LOBBY_POS + Vector3.new(0, 5, 0)))
				LeaderManager.updateCrown(matchPoints)
			else
				char:PivotTo(CFrame.new(HexConstants.MAIN_LOBBY_POS + Vector3.new(0, 5, 0)))
			end
		end)
		player:LoadCharacter()
	end)

	Players.PlayerRemoving:Connect(function(player)
		if activeMatchPlayers[player.Name] then
			activeMatchPlayers[player.Name] = nil
		end
	end)
end

function GameService.releasePlayers()
	local lobbyParts = CollectionService:GetTagged("LobbyTag")
	for _, part in lobbyParts do
		if part:IsA("BasePart") then
			part.CanCollide = false
			part.Transparency = 1
			task.delay(1, function() if part then part:Destroy() end end)
		end
	end
end

function GameService.startLoop()
	GameService.init()
	MapService.createMainLobby()

	while true do
		isMatchRunning = false
		activeMatchPlayers = {}
		LeaderManager.clearCrown()
		MapService.updateMatchBoards({}, "None", false)

		-- 1. [핵심 수정] 매치 대기 전에 미리 맵과 게임 로비를 생성하여 구경할 수 있게 함
		MapService.createLobby()
		MapService.generateMap()

		-- [PHASE 1] 대기 및 취소 가능한 매치 카운트다운
		local matchReady = false
		while not matchReady do

			-- 2. [핵심 수정] 매초마다 현재 인원을 체크하여 클라이언트에 갱신 전송
			while #Players:GetPlayers() < HexConstants.MIN_PLAYERS do
				UpdateStatus:FireAllClients("WaitingMainLobby", #Players:GetPlayers(), HexConstants.MIN_PLAYERS)
				task.wait(1)
			end

			-- 인원이 충족되면 카운트다운 시작
			local aborted = false
			for i = HexConstants.COUNTDOWN_TIME, 1, -1 do
				if #Players:GetPlayers() < HexConstants.MIN_PLAYERS then
					aborted = true
					break
				end
				UpdateStatus:FireAllClients("MatchCountdown", i, #Players:GetPlayers(), HexConstants.MIN_PLAYERS)
				task.wait(1)
			end

			if not aborted then matchReady = true end
		end

		-- [PHASE 2] 매치 시작 설정
		isMatchRunning = true
		matchPoints = {}

		local currentPlayers = Players:GetPlayers()
		for i = 1, math.min(#currentPlayers, HexConstants.MAX_PLAYERS) do
			local p = currentPlayers[i]
			activeMatchPlayers[p.Name] = true
			matchPoints[p.Name] = {score = 0, lastWinTime = 0}
		end

		local matchWinnerFound = false
		local matchWinnerName = ""
		local roundWinnerName = "None"
		local currentRound = 1

		while not matchWinnerFound do
			-- 라운드 시작 전 맵 재생성 (라운드 간 파괴된 맵 복구)
			MapService.createLobby()
			MapService.generateMap()
			MapService.updateMatchBoards(matchPoints, roundWinnerName, true)

			-- 활성 플레이어 게임 로비로 텔레포트
			for name in pairs(activeMatchPlayers) do
				local p = Players:FindFirstChild(name)
				if p then p:LoadCharacter() end
			end

			-- 라운드 인터미션 카운트다운
			for i = HexConstants.INTERMISSION_TIME, 1, -1 do
				UpdateStatus:FireAllClients("PreparingRound", i, currentRound, matchPoints, activeMatchPlayers)
				task.wait(1)
			end

			UpdateStatus:FireAllClients("StartRound", activeMatchPlayers)
			GameService.releasePlayers()

			-- [라운드 생존 경쟁 루프]
			local currentRoundSurvivor = ""
			while true do
				local alive = {}
				local activeCount = 0

				for name in pairs(activeMatchPlayers) do
					local p = Players:FindFirstChild(name)
					if p then
						activeCount += 1
						if p.Character and p.Character:FindFirstChild("Humanoid") and p.Character.Humanoid.Health > 0 then
							table.insert(alive, p.Name)
						end
					else
						activeMatchPlayers[name] = nil
					end
				end

				UpdateStatus:FireAllClients("UpdateSurvival", #alive, alive)

				if #alive <= 1 and activeCount >= 1 then
					currentRoundSurvivor = alive[1] or ""
					break
				end
				if activeCount == 0 then break end

				task.wait(0.5)
			end

			-- [라운드 결과 정산]
			roundWinnerName = currentRoundSurvivor
			if roundWinnerName ~= "" and matchPoints[roundWinnerName] then
				matchPoints[roundWinnerName].score += 1
				matchPoints[roundWinnerName].lastWinTime = os.time()
				LeaderManager.updateCrown(matchPoints)

				if matchPoints[roundWinnerName].score >= HexConstants.MATCH_WIN_TARGET then
					matchWinnerFound = true
					matchWinnerName = roundWinnerName
				end
			end

			UpdateStatus:FireAllClients("RoundResult", roundWinnerName, matchWinnerFound, matchPoints)
			task.wait(3)
			currentRound += 1
		end

		-- [PHASE 3] 매치 종료
		isMatchRunning = false
		MapService.updateMatchBoards({}, "None", false)
		UpdateStatus:FireAllClients("MatchWinner", matchWinnerName)
		task.wait(HexConstants.MATCH_END_TIME)

		-- 모든 유저 메인 로비로 귀환
		for _, p in ipairs(Players:GetPlayers()) do
			p:LoadCharacter()
		end
	end
end

return GameService