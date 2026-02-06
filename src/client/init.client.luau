--
local Players = game:GetService('Players')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local TweenService = game:GetService('TweenService')

-- 상수 설정 (서버의 MAX_PLAYERS와 동일하게 맞춤)
local MAX_PLAYERS = 8

-- 통신 및 UI 요소 참조
local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")
local UpdateStatus = ReplicatedStorage:WaitForChild("UpdateStatus")

local screenGui = PlayerGui:WaitForChild("GameGui")
local statusLabel = screenGui:WaitForChild("StatusLabel")
local survivorLabel = screenGui:WaitForChild("SurvivorLabel")

-- 깜빡임 상태 관리 변수
local isBlinking = false

-- 생존자 UI 깜빡임 애니메이션 함수
local function startBlinking(label)
	if isBlinking then return end
	isBlinking = true

	task.spawn(function()
		while isBlinking do
			-- 빨간색으로 변경 및 깜빡임 효과
			label.TextColor3 = Color3.fromRGB(255, 50, 50)
			label.TextTransparency = 0
			task.wait(0.3)
			label.TextTransparency = 0.7 -- 살짝 흐릿하게 (완전 투명보다 시인성 좋음)
			task.wait(0.3)
		end
		-- 깜빡임 중지 시 원래대로 복구
		label.TextTransparency = 0
		label.TextColor3 = Color3.fromRGB(255, 255, 255)
	end)
end

-- 서버로부터 신호를 받았을 때 실행되는 메인 로직
UpdateStatus.OnClientEvent:Connect(function(state, val1, val2)

	if state == "Waiting" then
		-- 대기실 인원 표시
		statusLabel.Visible = true
		survivorLabel.Visible = false
		statusLabel.TextSize = 40
		statusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		statusLabel.Text = string.format("JOINED: %d / %d", val1, val2)

	elseif state == "Countdown" then
		-- 카운트다운 연출 (강조)
		statusLabel.TextSize = 100
		statusLabel.TextColor3 = Color3.fromRGB(255, 50, 50)
		statusLabel.Text = tostring(val1)

	elseif state == "Start" then
		-- 게임 시작 문구 후 UI 교체
		statusLabel.Text = "GO!"
		task.wait(1)
		statusLabel.Visible = false
		survivorLabel.Visible = true

	elseif state == "UpdateSurvival" then
		-- 실시간 생존 인원 갱신
		local aliveCount = val1
		survivorLabel.Text = string.format("SURVIVORS: %d", aliveCount)

		-- 20% 이하 생존 시 긴박한 연출 시작
		-- (예: 8명 기준 1.6명 -> 1명 남았을 때)
		if aliveCount / MAX_PLAYERS <= 0.2 then
			startBlinking(survivorLabel)
		else
			isBlinking = false
		end
	end
end)