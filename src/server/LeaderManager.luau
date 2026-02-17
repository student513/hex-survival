local Players = game:GetService("Players")
local LeaderManager = {}

-- 1등 플레이어 머리 위에 왕관을 씌우는 기능
function LeaderManager.updateCrown(playerStats)
	local leaderPlayer = nil
	local maxWins = 0

	-- 1. 현재 접속자 중 가장 승수가 많은 플레이어 확인
	for name, stats in pairs(playerStats) do
		if stats.wins > maxWins then
			maxWins = stats.wins
			leaderPlayer = Players:FindFirstChild(name)
		end
	end

	-- 2. 모든 플레이어 캐릭터에서 기존 왕관 제거
	for _, player in ipairs(Players:GetPlayers()) do
		local char = player.Character
		if char then
			local existingCrown = char:FindFirstChild("LeaderCrown")
			if existingCrown then existingCrown:Destroy() end
		end
	end

	-- 3. 1등이 존재하고 점수가 1점 이상이면 왕관 생성
	if leaderPlayer and leaderPlayer.Character and maxWins > 0 then
		local head = leaderPlayer.Character:FindFirstChild("Head")
		if head then
			local billboard = Instance.new("BillboardGui")
			billboard.Name = "LeaderCrown"
			billboard.Size = UDim2.new(2, 0, 2, 0)
			billboard.StudsOffset = Vector3.new(0, 3, 0)
			billboard.Adornee = head
			billboard.AlwaysOnTop = true -- 다른 층에 있어도 표적임을 알 수 있게 함
			billboard.Parent = leaderPlayer.Character

			local textLabel = Instance.new("TextLabel")
			textLabel.BackgroundTransparency = 1
			textLabel.Size = UDim2.new(1, 0, 1, 0)
			textLabel.Text = "👑"
			textLabel.TextScaled = true
			textLabel.Parent = billboard
		end
	end
end

return LeaderManager