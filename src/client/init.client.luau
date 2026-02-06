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
    survivorLabel.Visible = false
    spectateLabel.Visible = false
    victoryLabel.Visible = false
    defeatLabel.Visible = false
    if Player.Character and Player.Character:FindFirstChild("Humanoid") then
        Camera.CameraSubject = Player.Character.Humanoid
    end
end

UpdateStatus.OnClientEvent:Connect(function(state, val1, val2)
    if state == "Waiting" then
        resetUI()
        statusLabel.Text = string.format("JOINED: %d / %d", val1, 8)
    elseif state == "Countdown" then
        statusLabel.TextSize = 100
        statusLabel.Text = tostring(val1)
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
            -- 관전 모드: 승리자 비추기
            local winner = Players:FindFirstChild(winnerName)
            if winner and winner.Character then
                Camera.CameraSubject = winner.Character:FindFirstChild("Humanoid")
                spectateLabel.Text = "SPECTATING: " .. winnerName
                spectateLabel.Visible = true
            end
        end
    end
end)