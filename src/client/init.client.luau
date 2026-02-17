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

UpdateStatus.OnClientEvent:Connect(function(state, val1, val2, val3)
	if state == "ResetMatch" then
		statusLabel.Visible, victoryLabel.Visible, defeatLabel.Visible, spectateLabel.Visible = true, false, false, false
		statusLabel.Text = string.format("WAITING FOR PLAYERS\n(%d / %d)", val1 or 0, val2 or 0)
		isSpectating = false
		Camera.CameraSubject = Player.Character:FindFirstChild("Humanoid")
	elseif state == "Waiting" then
		statusLabel.Text = string.format("WAITING FOR PLAYERS\n(%d / %d)", val1, val2)
	elseif state == "Preparing" then
		statusLabel.Text = string.format("NEXT MATCH STARTING IN %d\nJOINED: %d / %d", val1, val2, val3)
	elseif state == "Start" then
		statusLabel.Text = "GO!"
		task.wait(1)
		statusLabel.Visible, survivorLabel.Visible = false, true
	elseif state == "UpdateSurvival" then
		aliveList = val2 or {}
		survivorLabel.Text = string.format("SURVIVORS: %d", val1)
		local hum = Player.Character:FindFirstChild("Humanoid")
		if hum and hum.Health <= 0 and not isSpectating then changeSpectate(0) end
	elseif state == "Result" then
		survivorLabel.Visible = false
		if val1 == "Victory" then victoryLabel.Visible = true; victoryLabel.Text = "VICTORY!\nWINNER: " .. val2
		else defeatLabel.Visible = true; defeatLabel.Text = "ELIMINATED\nWINNER: " .. val2; changeSpectate(0) end
	elseif state == "Intermission" then
		statusLabel.Visible = true; statusLabel.Text = "ROUND OVER\nRETURNING TO LOBBY IN " .. tostring(val1)
  elseif state == "Stunned" then
    local duration = val1 or 2
    statusLabel.Visible = true
    statusLabel.TextColor3 = Color3.fromRGB(255, 50, 50) -- 붉은색 강조

    -- 0.1초 단위로 카운트다운 표시 (예: STUN! : 2.0s)
    task.spawn(function()
      local timeLeft = duration
      while timeLeft > 0 do
          statusLabel.Text = string.format("STUN! : %.1fs", timeLeft)
          task.wait(0.1)
          timeLeft -= 0.1
      end
      statusLabel.Visible = false
      statusLabel.TextColor3 = Color3.new(1, 1, 1) -- 색상 복구
    end)
  elseif state == "Swapped" then
		-- [추가] Swapped UI 로직
		statusLabel.Visible = true
		statusLabel.TextColor3 = Color3.fromRGB(255, 255, 255) -- 흰색
		statusLabel.Text = "Swapped!"

		-- 2초 후 UI 숨기기
		task.delay(2, function()
			-- 스턴 등 다른 UI가 덮어씌우지 않았을 때만 닫기
			if statusLabel.Text == "Swapped!" then
				statusLabel.Visible = false
			end
		end)
	end
end)