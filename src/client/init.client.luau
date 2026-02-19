local Players = game:GetService('Players')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local SoundService = game:GetService('SoundService')
local UserInputService = game:GetService('UserInputService')
local Camera = workspace.CurrentCamera

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")
local UpdateStatus = ReplicatedStorage:WaitForChild("UpdateStatus")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local HexConstants = require(Shared:WaitForChild("HexConstants"))

local screenGui = PlayerGui:WaitForChild("GameGui")
local statusLabel = screenGui:WaitForChild("StatusLabel")
local survivorLabel = screenGui:WaitForChild("SurvivorLabel")
local spectateLabel = screenGui:WaitForChild("SpectateLabel")
local victoryLabel = screenGui:WaitForChild("VictoryLabel")
local defeatLabel = screenGui:WaitForChild("DefeatLabel")

local aliveList = {}
local spectateIndex = 1
local isSpectating = false

-- BGM 오디오 객체 생성 및 관리 로직
local lobbyBGM = Instance.new("Sound")
lobbyBGM.Name = "LobbyBGM"
lobbyBGM.SoundId = HexConstants.BGM_IDS.Lobby
lobbyBGM.Looped = true
lobbyBGM.Volume = HexConstants.BGM_VOLUME
lobbyBGM.Parent = SoundService

local matchBGM = Instance.new("Sound")
matchBGM.Name = "MatchBGM"
matchBGM.SoundId = HexConstants.BGM_IDS.Match
matchBGM.Looped = true
matchBGM.Volume = HexConstants.BGM_VOLUME
matchBGM.Parent = SoundService

local function playBGM(targetBGM)
	if targetBGM == lobbyBGM then
		if not lobbyBGM.IsPlaying then lobbyBGM:Play() end
		matchBGM:Stop()
	elseif targetBGM == matchBGM then
		if not matchBGM.IsPlaying then matchBGM:Play() end
		lobbyBGM:Stop()
	else
		lobbyBGM:Stop()
		matchBGM:Stop()
	end
end

local function changeSpectate(direction)
	if #aliveList == 0 then return end
	isSpectating = true
	spectateIndex = (spectateIndex + direction - 1) % #aliveList + 1
	local targetPlayer = Players:FindFirstChild(aliveList[spectateIndex])

	if targetPlayer and targetPlayer.Character then
		local hum = targetPlayer.Character:FindFirstChild("Humanoid")
		if hum then
			Camera.CameraType = Enum.CameraType.Custom
			Camera.CameraSubject = hum
			spectateLabel.Text = "SPECTATING: " .. string.upper(targetPlayer.Name) .. " (Q, E to switch)"
			spectateLabel.Visible = true
		end
	end
end

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	if input.KeyCode == Enum.KeyCode.Q then changeSpectate(-1)
	elseif input.KeyCode == Enum.KeyCode.E then changeSpectate(1) end
end)

UpdateStatus.OnClientEvent:Connect(function(state, val1, val2, val3, val4)
	if state == "WaitingMainLobby" then
		playBGM(lobbyBGM)

		statusLabel.Visible, victoryLabel.Visible, defeatLabel.Visible, spectateLabel.Visible = true, false, false, false
		statusLabel.Text = string.format("MAIN LOBBY\nWAITING FOR PLAYERS (%d / %d)", val1, val2)
		isSpectating = false
		if Player.Character then
			Camera.CameraSubject = Player.Character:FindFirstChild("Humanoid")
		end

	elseif state == "MatchCountdown" then
		playBGM(lobbyBGM) -- 카운트다운 중에도 로비 음악 유지
		statusLabel.Visible = true
		statusLabel.Text = string.format("MATCH STARTING IN %d\n(%d / %d)", val1, val2, val3)

	elseif state == "PreparingRound" then
		local currentRound = val2
		local activePlayers = val4

		-- [핵심 수정] 참여자와 대기자를 구분하여 로직 적용
		if activePlayers and activePlayers[Player.Name] then
			playBGM(matchBGM) -- 참여자는 매치 음악 재생

			isSpectating = false
			spectateLabel.Visible = false
			if Player.Character then
				local myHum = Player.Character:FindFirstChild("Humanoid")
				if myHum then
					Camera.CameraType = Enum.CameraType.Custom
					Camera.CameraSubject = myHum
				end
			end
			statusLabel.Text = string.format("ROUND %d STARTING IN %d", currentRound, val1)
		else
			playBGM(lobbyBGM) -- 대기자는 로비 음악 유지
			statusLabel.Text = string.format("MATCH IN PROGRESS\nWAITING FOR NEXT MATCH... (%d)", val1)
		end
		statusLabel.Visible = true

	elseif state == "StartRound" then
		local activePlayers = val1
		if activePlayers and activePlayers[Player.Name] then
			playBGM(matchBGM) -- 참여자는 매치 음악 유지
			statusLabel.Text = "GO!"
			task.wait(1)
			statusLabel.Visible, survivorLabel.Visible = false, true
		else
			playBGM(lobbyBGM) -- 대기자는 로비 음악 유지
			statusLabel.Text = "MATCH IN PROGRESS\nPLEASE WAIT"
			statusLabel.Visible = true
		end

	elseif state == "UpdateSurvival" then
		aliveList = val2 or {}
		survivorLabel.Text = string.format("SURVIVORS: %d", val1)
		local hum = Player.Character:FindFirstChild("Humanoid")
		if hum and hum.Health <= 0 and not isSpectating then changeSpectate(0) end

	elseif state == "RoundResult" then
		survivorLabel.Visible = false
		statusLabel.Visible = true
		if val2 then
			statusLabel.Text = "MATCH OVER!"
		else
			statusLabel.Text = string.format("ROUND WINNER: %s\nNEXT ROUND SOON...", val1)
		end

	elseif state == "MatchWinner" then
		playBGM(lobbyBGM) -- 매치가 끝나면 참여자들도 로비 음악으로 복귀

		statusLabel.Visible = true
		statusLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
		statusLabel.Text = string.format("🏆 MATCH CHAMPION 🏆\n%s", val1)
		task.delay(5, function() statusLabel.TextColor3 = Color3.new(1, 1, 1) end)

	elseif state == "Stunned" then
		local duration = val1 or 2
		statusLabel.Visible = true
		statusLabel.TextColor3 = Color3.fromRGB(255, 50, 50)
		task.spawn(function()
			local timeLeft = duration
			while timeLeft > 0 do
				statusLabel.Text = string.format("STUN!: %.1fs", timeLeft)
				task.wait(0.1)
				timeLeft -= 0.1
			end
			statusLabel.Visible = false
			statusLabel.TextColor3 = Color3.new(1, 1, 1)
		end)

	elseif state == "Swapped" then
		statusLabel.Visible = true
		statusLabel.Text = "Swapped!"
		task.delay(2, function()
			if statusLabel.Text == "Swapped!" then statusLabel.Visible = false end
		end)
	end
end)