local Players = game:GetService("Players")
local LeaderManager = {}

function LeaderManager.updateCrown(matchPoints)
	local leaderPlayer = nil
	local maxWins = 0
	local latestTime = 0

	-- [수정] 동점자 발생 시 가장 최근 득점자 선별 로직
	for name, data in pairs(matchPoints) do
		if data.score > maxWins then
			maxWins = data.score
			latestTime = data.lastWinTime
			leaderPlayer = Players:FindFirstChild(name)
		elseif data.score == maxWins and maxWins > 0 then
			if data.lastWinTime > latestTime then
				latestTime = data.lastWinTime
				leaderPlayer = Players:FindFirstChild(name)
			end
		end
	end

	for _, player in ipairs(Players:GetPlayers()) do
		local char = player.Character
		if char then
			local existingCrown = char:FindFirstChild("LeaderCrown")
			if existingCrown then existingCrown:Destroy() end
		end
	end

	if leaderPlayer and leaderPlayer.Character and maxWins > 0 then
		local head = leaderPlayer.Character:FindFirstChild("Head")
		if head then
			local billboard = Instance.new("BillboardGui")
			billboard.Name = "LeaderCrown"
			billboard.Size = UDim2.new(2, 0, 2, 0)
			billboard.StudsOffset = Vector3.new(0, 3, 0)
			billboard.Adornee = head
			billboard.AlwaysOnTop = true
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

function LeaderManager.clearCrown()
	for _, player in ipairs(Players:GetPlayers()) do
		local char = player.Character
		if char then
			local crown = char:FindFirstChild("LeaderCrown")
			if crown then crown:Destroy() end
		end
	end
end

return LeaderManager