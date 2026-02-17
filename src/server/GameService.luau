local CollectionService = game:GetService('CollectionService')
local Players = game:GetService('Players')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local UpdateStatus = ReplicatedStorage:WaitForChild("UpdateStatus")

local LeaderManager = require(script.Parent.LeaderManager)

Players.CharacterAutoLoads = false

local GameService = {}
local MIN_PLAYERS = 1
local MAX_PLAYERS = 12
local COUNTDOWN_TIME = 3
local INTERMISSION_TIME = 7
local lastWinnerName = "None"
local playerStats = {}

function GameService.init()
	local MapService = require(script.Parent.MapService)
	Players.PlayerAdded:Connect(function(player)
		if not playerStats[player.Name] then
			playerStats[player.Name] = {wins = 0, lastWinTime = 0}
		end

		player.CharacterAdded:Connect(function()
			task.wait(0.1)
			LeaderManager.updateCrown(playerStats)
		end)

		player:LoadCharacter()
		MapService.updateRanking(playerStats)
	end)

	Players.PlayerRemoving:Connect(function(player)
		playerStats[player.Name] = nil -- 퇴장 시 정보 삭제
		MapService.updateRanking(playerStats)
		LeaderManager.updateCrown(playerStats)
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
	local MapService = require(script.Parent.MapService)

	while true do
		-- [Phase 0]
		MapService.generateMap()
		MapService.createLobby(lastWinnerName, playerStats)
		UpdateStatus:FireAllClients("ResetMatch", #Players:GetPlayers(), MIN_PLAYERS)

		for _, player in ipairs(Players:GetPlayers()) do
			player:LoadCharacter()
			local char = player.Character or player.CharacterAdded:Wait()
			char:PivotTo(CFrame.new(0, 505, 0)) -- 강제 텔레포트
		end
		task.wait(3)

		-- [Phase 1] 대기
		repeat
			MapService.updateRanking(playerStats)
			UpdateStatus:FireAllClients("Waiting", #Players:GetPlayers(), MIN_PLAYERS)
			task.wait(1)
		until #Players:GetPlayers() >= MIN_PLAYERS

		-- [Phase 2, 3] 카운트다운 및 시작
		for i = COUNTDOWN_TIME, 1, -1 do
			UpdateStatus:FireAllClients("Preparing", i, #Players:GetPlayers(), MAX_PLAYERS)
			task.wait(1)
		end
		UpdateStatus:FireAllClients("Start")
		GameService.releasePlayers()

		-- [Phase 4] 서바이벌 루프
		local winner = nil
		while true do
			local alive = {}
			local all = Players:GetPlayers()
			for _, p in ipairs(all) do
				if p.Character and p.Character:FindFirstChild("Humanoid") and p.Character.Humanoid.Health > 0 then
					table.insert(alive, p.Name)
				end
			end
			UpdateStatus:FireAllClients("UpdateSurvival", #alive, alive)

			if #alive <= 1 and #all >= 1 then
				local wName = alive[1] or (all[1] and all[1].Name)
				winner = Players:FindFirstChild(wName)
				lastWinnerName = wName

				if playerStats[wName] then
					playerStats[wName].wins += 1 -- 1pt 획득
					playerStats[wName].lastWinTime = os.time()
				end
				MapService.updateRanking(playerStats)

        -- 점수 갱신 후 랭킹 UI와 왕관 업데이트
				MapService.updateRanking(playerStats)
				LeaderManager.updateCrown(playerStats)

				for _, p in ipairs(all) do
					local res = (p.Name == wName) and "Victory" or "Defeat"
					UpdateStatus:FireClient(p, "Result", res, wName)
				end
				break
			end
			task.wait(0.5)
		end

		-- [Phase 5]
		for i = INTERMISSION_TIME, 1, -1 do
			UpdateStatus:FireAllClients("Intermission", i)
			task.wait(1)
		end
	end
end

return GameService