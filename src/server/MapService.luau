local CollectionService = game:GetService('CollectionService')
local Players = game:GetService('Players')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local ServerStorage = game:GetService('ServerStorage')

local Shared = ReplicatedStorage:WaitForChild("Shared")
local HexConstants = require(Shared:WaitForChild("HexConstants"))

local MapService = {}

-- [Ranking UI 갱신] 참가자 전원 표시 및 Space-between 정렬
function MapService.updateRanking(statsTable)
	local board = workspace:FindFirstChild("Leaderboard", true)
	if not board then return end
	local gui = board:FindFirstChild("SurfaceGui")
	local container = gui and gui:FindFirstChild("ScrollingFrame")
	if not container then return end

	-- 기존 리스트 초기화
	for _, child in ipairs(container:GetChildren()) do
		if child:IsA("Frame") then child:Destroy() end
	end

	-- 1. 현재 접속자 데이터 수집
	local displayList = {}
	for _, player in ipairs(Players:GetPlayers()) do
		local stats = statsTable[player.Name] or {wins = 0, lastWinTime = 0}
		table.insert(displayList, {
			name = player.Name,
			wins = stats.wins,
			lastWinTime = stats.lastWinTime
		})
	end

	-- 2. 정렬: 승점(내림) -> 0점이면 이름(오름) -> 점수있으면 최신순(내림)
	table.sort(displayList, function(a, b)
		if a.wins ~= b.wins then return a.wins > b.wins end
		if a.wins == 0 then return a.name:lower() < b.name:lower()
		else return a.lastWinTime > b.lastWinTime end
	end)

	-- 3. UI 생성 (Space-between 효과)
	for i, data in ipairs(displayList) do
		local row = Instance.new("Frame")
		row.Size = UDim2.new(1, 0, 0, 45)
		row.BackgroundTransparency = 1
		row.Parent = container

		local rank = Instance.new("TextLabel", row)
		rank.Size = UDim2.new(0.1, 0, 1, 0)
		rank.Text = i .. "."
		rank.TextXAlignment = Enum.TextXAlignment.Left

		local nameLabel = Instance.new("TextLabel", row)
		nameLabel.Size = UDim2.new(0.65, 0, 1, 0)
		nameLabel.Position = UDim2.new(0.1, 0, 0, 0)
		nameLabel.Text = data.name
		nameLabel.TextXAlignment = Enum.TextXAlignment.Left

		local score = Instance.new("TextLabel", row)
		score.Size = UDim2.new(0.25, 0, 1, 0)
		score.Position = UDim2.new(0.75, 0, 0, 0)
		score.Text = data.wins .. " pt"
		score.TextXAlignment = Enum.TextXAlignment.Right

		for _, l in ipairs({rank, nameLabel, score}) do
			l.TextColor3 = Color3.new(1,1,1)
			l.BackgroundTransparency = 1
			l.Font = Enum.Font.GothamBold
			l.TextScaled = true
			l.Parent = row
		end
		score.TextColor3 = Color3.fromRGB(255, 215, 0)
	end
end

-- [대기실 생성] 이전 우승자 UI + Ranking UI 포함
function MapService.createLobby(winnerName, statsTable)
	local lobbyCenter = Vector3.new(0, 500, 0)
	local lobbySize = 70
	local wallHeight = 40

	-- 바닥 및 벽 생성
	local floor = Instance.new("Part")
	floor.Size = Vector3.new(lobbySize, 1, lobbySize)
	floor.Position = lobbyCenter
	floor.Anchored = true
	floor.Parent = workspace
	CollectionService:AddTag(floor, "LobbyTag")

	local wallData = {
		{pos = Vector3.new(0, wallHeight/2, lobbySize/2), size = Vector3.new(lobbySize, wallHeight, 1)},
		{pos = Vector3.new(0, wallHeight/2, -lobbySize/2), size = Vector3.new(lobbySize, wallHeight, 1)},
		{pos = Vector3.new(lobbySize/2, wallHeight/2, 0), size = Vector3.new(1, wallHeight, lobbySize)},
		{pos = Vector3.new(-lobbySize/2, wallHeight/2, 0), size = Vector3.new(1, wallHeight, lobbySize)}
	}
	for _, data in ipairs(wallData) do
		local wall = Instance.new("Part")
		wall.Size = data.size
		wall.Position = lobbyCenter + data.pos
		wall.Anchored = true
		wall.Material = Enum.Material.Glass
		wall.Parent = workspace
		CollectionService:AddTag(wall, "LobbyTag")
	end

	-- [복구] 이전 우승자 UI (Hall of Fame)
	local hof = Instance.new("Part")
	hof.Name = "HallOfFame"
	hof.Size = Vector3.new(25, 12, 1)
	hof.Position = lobbyCenter + Vector3.new(0, 15, 34.4)
	hof.Anchored = true
	hof.Color = Color3.fromRGB(30, 30, 30)
	hof.Parent = workspace
	CollectionService:AddTag(hof, "LobbyTag")

	local hofGui = Instance.new("SurfaceGui", hof)
	hofGui.Face = Enum.NormalId.Front
	local hofLabel = Instance.new("TextLabel", hofGui)
	hofLabel.Size = UDim2.new(1, 0, 1, 0)
	hofLabel.Text = "🏆 LAST WINNER: " .. (winnerName or "None")
	hofLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
	hofLabel.TextScaled = true
	hofLabel.BackgroundTransparency = 1
	hofLabel.Font = Enum.Font.GothamBold

	-- [Ranking UI] 맞은편 벽
	local lb = Instance.new("Part")
	lb.Name = "Leaderboard"
	lb.Size = Vector3.new(40, 30, 1)
	lb.Position = lobbyCenter + Vector3.new(0, 15, -34.4)
	lb.Anchored = true
	lb.Color = Color3.fromRGB(20, 20, 20)
	lb.Parent = workspace
	CollectionService:AddTag(lb, "LobbyTag")

	local lbGui = Instance.new("SurfaceGui", lb)
	lbGui.Face = Enum.NormalId.Back
	lbGui.LightInfluence = 0

	local title = Instance.new("TextLabel", lbGui)
	title.Size = UDim2.new(1, 0, 0, 60)
	title.Text = "Ranking"
	title.Font = Enum.Font.GothamBlack
	title.TextColor3 = Color3.new(1,1,1)
	title.TextScaled = true
	title.BackgroundTransparency = 1

	local scroll = Instance.new("ScrollingFrame", lbGui)
	scroll.Name = "ScrollingFrame"
	scroll.Size = UDim2.new(1, -40, 1, -100)
	scroll.Position = UDim2.new(0, 20, 0, 80)
	scroll.BackgroundTransparency = 1
	scroll.CanvasSize = UDim2.new(0,0,0,0)
	scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scroll.ScrollBarThickness = 0
	Instance.new("UIListLayout", scroll).Padding = UDim.new(0, 10)

	MapService.updateRanking(statsTable)
end

-- [맵 생성] 층별 랜덤 빈칸 로직 포함
-- [맵 생성] 변종 층 및 직관적 비주얼 적용
function MapService.generateMap()
	local oldMap = workspace:FindFirstChild("Map")
	if oldMap then oldMap:Destroy() end

	local hexTemplate = ServerStorage:WaitForChild("HexPart")
	local mapFolder = Instance.new("Folder", workspace)
	mapFolder.Name = "Map"

	for floor = 1, HexConstants.FLOORS_COUNT do
		local floorFolder = Instance.new("Folder", mapFolder)
		floorFolder.Name = "Floor_" .. floor

		local typeName = "Normal"
		if floor < HexConstants.FLOORS_COUNT and math.random(1, 100) <= HexConstants.SPECIAL_FLOOR_CHANCE then
			typeName = ({"Magma", "Bounce", "Turbo"})[math.random(1, 4)]
		end
		floorFolder:SetAttribute("FloorType", typeName)

		local delayTime = HexConstants.GET_DELAY_TIME(floor)
		if typeName == "Magma" then delayTime /= 2.5 end

		for q = -HexConstants.GRID_SIZE, HexConstants.GRID_SIZE do
			for r = math.max(-HexConstants.GRID_SIZE, -q - HexConstants.GRID_SIZE), math.min(HexConstants.GRID_SIZE, -q + HexConstants.GRID_SIZE) do
				if math.random(1, 100) <= 15 and floor < HexConstants.FLOORS_COUNT then continue end

				local newPart = hexTemplate:Clone()
				CollectionService:AddTag(newPart, "HexPlatform")

				-- 시각적 설정
				if typeName == "Magma" then
					newPart.Color = Color3.fromRGB(255, 80, 0); newPart.Material = Enum.Material.Neon
				elseif typeName == "Bounce" then
					newPart.Color = Color3.fromRGB(100, 255, 100); newPart.Material = Enum.Material.Rubber
				elseif typeName == "Turbo" then
					newPart.Color = Color3.fromRGB(255, 255, 0); newPart.Material = Enum.Material.Neon
				end

				newPart.Position = Vector3.new(8.66 * 1.02 * (q + r/2), HexConstants.START_HEIGHT + (floor * HexConstants.FLOOR_DISTANCE), 10 * 0.75 * 1.02 * r)
				newPart.Parent = floorFolder
				newPart:SetAttribute("DelayTime", delayTime)
			end
		end
	end
end

function MapService.createKillZone()
	local kill = Instance.new("Part")
	kill.Size = Vector3.new(2048, 2, 2048)
	kill.Position = Vector3.new(0, 20, 0)
	kill.Anchored = true
	kill.CanCollide = false
	kill.Transparency = 1
	kill.Parent = workspace
	kill.Touched:Connect(function(hit)
		local hum = hit.Parent:FindFirstChild("Humanoid")
		if hum then hum.Health = 0 end
	end)
end

return MapService