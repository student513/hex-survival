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

-- 관전 대상 물리적 전환
local function changeSpectate(direction)
	if #aliveList == 0 then return end

	isSpectating = true
	spectateIndex = spectateIndex + direction
	if spectateIndex > #aliveList then spectateIndex = 1 end
	if spectateIndex < 1 then spectateIndex = #aliveList end

	local targetName = aliveList[spectateIndex]
	local targetPlayer = Players:FindFirstChild(targetName)

	if targetPlayer and targetPlayer.Character then
		local hum = targetPlayer.Character:FindFirstChild("Humanoid")
		if hum then
			Camera.CameraType = Enum.CameraType.Custom
			Camera.CameraSubject = hum
			spectateLabel.Text = "SPECTATING: " .. string.upper(targetName)
			spectateLabel.Visible = true
		end
	end
end

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	if input.KeyCode == Enum.KeyCode.Left then changeSpectate(-1)
	elseif input.KeyCode == Enum.KeyCode.Right then changeSpectate(1) end
end)

-- UI 및 카메라 초기화 (데이터가 있을 때만 텍스트 갱신)
local function resetMatchUI(val1, val2)
	-- 기본 UI 가시성 설정
	statusLabel.Visible = true
	survivorLabel.Visible = false
	spectateLabel.Visible = false
	victoryLabel.Visible = false
	defeatLabel.Visible = false
	isSpectating = false

	-- [방어 로직] 데이터가 유효할 때만 텍스트 업데이트
	if val1 ~= nil and val2 ~= nil then
		statusLabel.Text = string.format("WAITING FOR PLAYERS\n(%d / %d)", val1, val2)
	else
		statusLabel.Text = "PREPARING NEXT ROUND..."
	end

	statusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)

	-- 카메라 복구
	Camera.CameraType = Enum.CameraType.Custom
	if Player.Character and Player.Character:FindFirstChild("Humanoid") then
		Camera.CameraSubject = Player.Character.Humanoid
	end
end

UpdateStatus.OnClientEvent:Connect(function(state, val1, val2, val3)
	-- [ResetMatch] 단계에서 서버가 보낸 인원수를 주입받음
	if state == "ResetMatch" then
		print("[CLIENT] ResetMatch Signal:", val1, val2)
		resetMatchUI(val1, val2)
		return
	end

	if state == "Waiting" then
		if val1 ~= nil and val2 ~= nil then
			statusLabel.TextSize = 40
			statusLabel.Text = string.format("WAITING FOR PLAYERS\n(%d / %d)", val1, val2)
		end

	elseif state == "Preparing" then
		statusLabel.Visible = true
		statusLabel.Text = string.format("NEXT MATCH STARTING IN %d\nJOINED: %d / %d", val1, val2, val3)

	elseif state == "Start" then
		statusLabel.Text = "GO!"
		task.wait(1)
		statusLabel.Visible = false
		survivorLabel.Visible = true

	elseif state == "UpdateSurvival" then
		aliveList = val2 or {}
		survivorLabel.Text = string.format("SURVIVORS: %d", val1)

		local char = Player.Character
		if char and char:FindFirstChild("Humanoid") and char.Humanoid.Health <= 0 then
			if not isSpectating then changeSpectate(0) end
		end

	elseif state == "Result" then
		survivorLabel.Visible = false
		if val1 == "Victory" then
			isSpectating = false
			victoryLabel.Text = "VICTORY!\nWINNER: " .. string.upper(val2)
			victoryLabel.Visible = true
		else
			defeatLabel.Text = "ELIMINATED\nWINNER: " .. string.upper(val2)
			defeatLabel.Visible = true
			changeSpectate(0)
		end

	elseif state == "Intermission" then
		statusLabel.Visible = true
		statusLabel.Text = "ROUND OVER\nRETURNING TO LOBBY IN " .. tostring(val1)
	end
end)