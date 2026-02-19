local Players = game:GetService('Players')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")
local UpdateStatus = ReplicatedStorage:WaitForChild("UpdateStatus")

local screenGui = PlayerGui:WaitForChild("GameGui")
local statusLabel = screenGui:WaitForChild("StatusLabel")
local survivorLabel = screenGui:WaitForChild("SurvivorLabel")
local spectateLabel = screenGui:WaitForChild("SpectateLabel")
local victoryLabel = screenGui:WaitForChild("VictoryLabel")
local defeatLabel = screenGui:WaitForChild("DefeatLabel")

local aliveList = {}
local spectateIndex = 1
local isSpectating = false

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
		statusLabel.Visible, victoryLabel.Visible, defeatLabel.Visible, spectateLabel.Visible = true, false, false, false
		statusLabel.Text = string.format("MAIN LOBBY\nWAITING FOR PLAYERS (%d / %d)", val1, val2)
		isSpectating = false
		Camera.CameraSubject = Player.Character:FindFirstChild("Humanoid")

	elseif state == "MatchCountdown" then
		statusLabel.Visible = true
		statusLabel.Text = string.format("MATCH STARTING IN %d\n(%d / %d)", val1, val2, val3)

	elseif state == "PreparingRound" then
		statusLabel.Visible = true
		local currentRound = val2
		local activePlayers = val4

		if activePlayers and activePlayers[Player.Name] then
			statusLabel.Text = string.format("ROUND %d STARTING IN %d", currentRound, val1)
		else
			statusLabel.Text = string.format("MATCH IN PROGRESS\nWAITING FOR NEXT MATCH... (%d)", val1)
		end

	elseif state == "StartRound" then
		local activePlayers = val1
		if activePlayers and activePlayers[Player.Name] then
			statusLabel.Text = "GO!"
			task.wait(1)
			statusLabel.Visible, survivorLabel.Visible = false, true
		else
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
				statusLabel.Text = string.format("STUN! : %.1fs", timeLeft)
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