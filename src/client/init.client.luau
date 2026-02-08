local Players = game:GetService('Players')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
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

local function resetUI()
    statusLabel.Visible = true
    statusLabel.TextSize = 40
    statusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    survivorLabel.Visible = false
    spectateLabel.Visible = false
    victoryLabel.Visible = false
    defeatLabel.Visible = false
    -- 카메라를 자신의 캐릭터로 복구
    if Player.Character and Player.Character:FindFirstChild("Humanoid") then
        Camera.CameraSubject = Player.Character.Humanoid
    end
end

UpdateStatus.OnClientEvent:Connect(function(state, val1, val2)
    if state == "Waiting" then
        resetUI()
        statusLabel.Text = string.format("WAITING FOR PLAYERS (%d/%d)", val1, val2)

    elseif state == "PreStart" then
        statusLabel.TextSize = 50
        statusLabel.TextColor3 = Color3.fromRGB(255, 255, 0)
        statusLabel.Text = "NEXT MATCH STARTING SOON!"

    elseif state == "Countdown" then
        statusLabel.TextSize = 100
        if val1 == "FULL!" then
            statusLabel.Text = "MATCH FULL!"
        else
            statusLabel.Text = tostring(val1)
            -- 하단에 현재 입장 인원 표시
            survivorLabel.Visible = true
            survivorLabel.Text = string.format("JOINED: %d / 12", val2)
        end

    elseif state == "Start" then
        statusLabel.Text = "GO!"
        task.wait(1)
        statusLabel.Visible = false
        survivorLabel.Visible = true

    elseif state == "UpdateSurvival" then
        survivorLabel.Text = string.format("SURVIVORS: %d", val1)

    elseif state == "Result" then
        local resultType = val1 -- "Victory" or "Defeat"
        local winnerName = val2
        survivorLabel.Visible = false

        if resultType == "Victory" then
            victoryLabel.Text = "VICTORY!\nWINNER: " .. winnerName
            victoryLabel.Visible = true
        else
            defeatLabel.Text = "ELIMINATED\nWINNER: " .. winnerName
            defeatLabel.Visible = true
        end

        -- [명예의 전당] 승리자 클로즈업 관전
        local winner = Players:FindFirstChild(winnerName)
        if winner and winner.Character then
            Camera.CameraSubject = winner.Character:FindFirstChild("Humanoid")
            spectateLabel.Text = "WINNER FOCUS: " .. winnerName
            spectateLabel.Visible = true
        end

    elseif state == "IntermissionCountdown" then
        -- 상단에 복귀 예고 표시
        statusLabel.Visible = true
        statusLabel.TextSize = 30
        statusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
        statusLabel.Text = string.format("RETURNING TO LOBBY IN %d...", val1)

    elseif state == "RoundOver" then
        -- 라운드 종료 브릿지 UI
        resetUI()
        statusLabel.TextSize = 60
        statusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
        statusLabel.Text = "ROUND OVER\nGET READY!"
    end
end)