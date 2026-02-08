local CollectionService = game:GetService('CollectionService')
local Players = game:GetService('Players')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local UpdateStatus = ReplicatedStorage:WaitForChild("UpdateStatus")

-- 자동 부활 차단
Players.CharacterAutoLoads = false

local GameService = {}
local MIN_PLAYERS = 1 -- 테스트용 (기획: 8명)
local MAX_PLAYERS = 12
local COUNTDOWN_TIME = 10
local INTERMISSION_TIME = 7
local lastWinnerName = "None"

function GameService.init()
	Players.PlayerAdded:Connect(function(player)
		print("[SERVER] New Player Joined: " .. player.Name)
		player:LoadCharacter()
	end)
end

function GameService.releasePlayers()
	print("[SERVER] Game Start: Destroying Lobby")
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
	print("[SERVER] Game System Initialized")
	GameService.init()
	local MapService = require(script.Parent.MapService)

	while true do
		-- [Phase 0] Lobby Setup & Data Prep (사전 준비 단계)
		print("[SERVER] Phase 0: Lobby Setup")

		-- 1. 대기실 생성
		MapService.createLobby(lastWinnerName)

		-- 2. [핵심] 신호 전송 전 인원수 미리 계산
		local currentCount = #Players:GetPlayers()

		-- 3. ResetMatch 신호에 인원수 데이터를 주입하여 전송 (nil 에러 방지)
		UpdateStatus:FireAllClients("ResetMatch", currentCount, MIN_PLAYERS)

		-- 4. 전원 부활 및 대기실 소환
		for _, player in ipairs(Players:GetPlayers()) do
			player:LoadCharacter()
		end

		-- 5. 물리적 안착을 위한 대기
		task.wait(3)

		-- [Phase 1] Waiting (실시간 인원 체크)
		print("[SERVER] Phase 1: Waiting for Players...")
		repeat
			local cCount = #Players:GetPlayers()
			UpdateStatus:FireAllClients("Waiting", cCount, MIN_PLAYERS)
			task.wait(1)
		until #Players:GetPlayers() >= MIN_PLAYERS

		-- [Phase 2] Preparing (카운트다운)
		print("[SERVER] Phase 2: Preparing Match")
		for i = COUNTDOWN_TIME, 1, -1 do
			UpdateStatus:FireAllClients("Preparing", i, #Players:GetPlayers(), MAX_PLAYERS)
			task.wait(1)
		end

		-- [Phase 3] Game Start
		print("[SERVER] Phase 3: Start!")
		UpdateStatus:FireAllClients("Start")
		GameService.releasePlayers()

		-- [Phase 4] Survival & Spectating Loop
		local winner = nil
		while true do
			local alivePlayers = {}
			local allPlayers = Players:GetPlayers()
			for _, player in ipairs(allPlayers) do
				local char = player.Character
				if char and char:FindFirstChild("Humanoid") and char.Humanoid.Health > 0 then
					table.insert(alivePlayers, player.Name)
				end
			end

			UpdateStatus:FireAllClients("UpdateSurvival", #alivePlayers, alivePlayers)

			if #alivePlayers <= 1 and #allPlayers >= 1 then
				local winnerName = alivePlayers[1] or (allPlayers[1] and allPlayers[1].Name)
				winner = Players:FindFirstChild(winnerName)
				lastWinnerName = winnerName

				for _, p in ipairs(allPlayers) do
					local result = (p.Name == winnerName) and "Victory" or "Defeat"
					UpdateStatus:FireClient(p, "Result", result, winnerName)
				end
				break
			end
			task.wait(0.5)
		end

		-- [Phase 5] Intermission
		print("[SERVER] Phase 5: Intermission")
		for i = INTERMISSION_TIME, 1, -1 do
			UpdateStatus:FireAllClients("Intermission", i)
			task.wait(1)
		end

		print("[SERVER] --- Round Cycle End ---")
	end
end

return GameService