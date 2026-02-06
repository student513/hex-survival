local Players = game:GetService('Players')
local ReplicatedStorage = game:GetService('ReplicatedStorage')

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")
local UpdateStatus = ReplicatedStorage:WaitForChild("UpdateStatus")

-- UI 요소 가져오기 (이전에 만든 GameGui/StatusLabel 이름 확인)
local screenGui = PlayerGui:WaitForChild("GameGui")
local statusLabel = screenGui:WaitForChild("StatusLabel")

UpdateStatus.OnClientEvent:Connect(function(state, val1, val2)
	if state == "Waiting" then
		-- "현재 인원 / 최대 인원" 표시
		statusLabel.Text = string.format("Player: %d / %d", val1, val2)
		statusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		statusLabel.TextSize = 30

	elseif state == "Countdown" then
		-- 카운트다운 (화면 중앙 강조)
		statusLabel.Text = tostring(val1)
		statusLabel.TextColor3 = Color3.fromRGB(255, 50, 50) -- 붉은색 강조
		statusLabel.TextSize = 80 -- 글자 크게

	elseif state == "Start" then
		-- 시작 메시지
		statusLabel.Text = "GO!!"
		task.wait(1)
		statusLabel.Visible = false -- 게임 시작 후 UI 숨김
	end
end)