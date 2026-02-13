local CollectionService = game:GetService('CollectionService')
local Players = game:GetService('Players')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local ServerStorage = game:GetService('ServerStorage')

local Shared = ReplicatedStorage:WaitForChild("Shared")
local HexConstants = require(Shared:WaitForChild("HexConstants"))

local MapService = {}

-- [새 구현] 랭킹 UI 갱신 함수: 실시간 인원 표시 및 정렬 규칙 적용
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

	-- 1. 현재 서버 접속자 기반 데이터 구성 (0점 플레이어 포함)
	local displayList = {}
	for _, player in ipairs(Players:GetPlayers()) do
		local stats = statsTable[player.Name] or {wins = 0, lastWinTime = 0}
		table.insert(displayList, {
			name = player.Name,
			wins = stats.wins,
			lastWinTime = stats.lastWinTime
		})
	end

	-- 2. 정렬 규칙 적용
	-- 승점(내림차순) -> 0점이면 이름(오름차순) -> 점수 있으면 최신 승리순(내림차순)
	table.sort(displayList, function(a, b)
		if a.wins ~= b.wins then
			return a.wins > b.wins
		end
		if a.wins == 0 then
			return a.name:lower() < b.name:lower()
		else
			return a.lastWinTime > b.lastWinTime
		end
	end)

	-- 3. UI 생성 (Space-between 효과 구현)
	for i, data in ipairs(displayList) do
		local row = Instance.new("Frame")
		row.Name = "Row_" .. i
		row.Size = UDim2.new(1, 0, 0, 45)
		row.BackgroundTransparency = 1
		row.Parent = container

		-- [왼쪽] 순위
		local rankLabel = Instance.new("TextLabel", row)
		rankLabel.Size = UDim2.new(0.1, 0, 1, 0)
		rankLabel.Text = tostring(i) .. "."
		rankLabel.TextColor3 = Color3.new(1, 1, 1)
		rankLabel.BackgroundTransparency = 1
		rankLabel.TextXAlignment = Enum.TextXAlignment.Left

		-- [가운데] 유저명
		local nameLabel = Instance.new("TextLabel", row)
		nameLabel.Size = UDim2.new(0.65, 0, 1, 0)
		nameLabel.Position = UDim2.new(0.1, 0, 0, 0)
		nameLabel.Text = data.name
		nameLabel.TextColor3 = Color3.new(1, 1, 1)
		nameLabel.BackgroundTransparency = 1
		nameLabel.TextXAlignment = Enum.TextXAlignment.Left

		-- [오른쪽] 점수 (pt 표시)
		local scoreLabel = Instance.new("TextLabel", row)
		scoreLabel.Size = UDim2.new(0.25, 0, 1, 0)
		scoreLabel.Position = UDim2.new(0.75, 0, 0, 0)
		scoreLabel.Text = tostring(data.wins) .. " pt"
		scoreLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
		scoreLabel.BackgroundTransparency = 1
		scoreLabel.TextXAlignment = Enum.TextXAlignment.Right

		for _, label in ipairs({rankLabel, nameLabel, scoreLabel}) do
			label.Font = Enum.Font.GothamBold
			label.TextScaled = true
		end
	end
end

function MapService.createLobby(winnerName, statsTable)
	local lobbyCenter = Vector3.new(0, 500, 0)
	local lobbySize = 70
	local wallHeight = 40

	-- 바닥 생성
	local floor = Instance.new("Part")
	floor.Name = "LobbyFloor"
	floor.Size = Vector3.new(lobbySize, 1, lobbySize)
	floor.Position = lobbyCenter
	floor.Anchored = true
	floor.Transparency = 0.5
	floor.Parent = workspace
	CollectionService:AddTag(floor, "LobbyTag")

	-- 벽 생성 (4면)
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

	-- 명예의 전당 (Hall of Fame)
	local hofBoard = Instance.new("Part")
	hofBoard.Name = "HallOfFame"
	hofBoard.Size = Vector3.new(25, 12, 1)
	hofBoard.Position = lobbyCenter + Vector3.new(0, 15, 34.4)
	hofBoard.Anchored = true
	hofBoard.Color = Color3.fromRGB(30, 30, 30)
	hofBoard.Parent = workspace
	CollectionService:AddTag(hofBoard, "LobbyTag")

	local hofGui = Instance.new("SurfaceGui", hofBoard)
	hofGui.Face = Enum.NormalId.Front
	local hofLabel = Instance.new("TextLabel", hofGui)
	hofLabel.Size = UDim2.new(1, 0, 1, 0)
	hofLabel.BackgroundTransparency = 1
	hofLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
	hofLabel.TextScaled = true
	hofLabel.Text = "🏆 LAST WINNER: " .. (winnerName or "None")

	-- [요청] Ranking 리더보드 (Hof 맞은편 벽)
	local lbBoard = Instance.new("Part")
	lbBoard.Name = "Leaderboard"
	lbBoard.Size = Vector3.new(40, 30, 1)
	lbBoard.Position = lobbyCenter + Vector3.new(0, 15, -34.4)
	lbBoard.Anchored = true
	lbBoard.Color = Color3.fromRGB(20, 20, 20)
	lbBoard.Parent = workspace
	CollectionService:AddTag(lbBoard, "LobbyTag")

	local lbGui = Instance.new("SurfaceGui", lbBoard)
	lbGui.Face = Enum.NormalId.Back -- 안쪽 벽면
	lbGui.LightInfluence = 0

	local title = Instance.new("TextLabel", lbGui)
	title.Size = UDim2.new(1, 0, 0, 60)
	title.Text = "Ranking"
	title.TextColor3 = Color3.new(1, 1, 1)
	title.Font = Enum.Font.GothamBlack
	title.TextScaled = true
	title.BackgroundTransparency = 1

	local scroll = Instance.new("ScrollingFrame", lbGui)
	scroll.Name = "ScrollingFrame"
	scroll.Size = UDim2.new(1, -40, 1, -100)
	scroll.Position = UDim2.new(0, 20, 0, 80)
	scroll.BackgroundTransparency = 1
	scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scroll.ScrollBarThickness = 0

	local layout = Instance.new("UIListLayout", scroll)
	layout.Padding = UDim.new(0, 10)

	MapService.updateRanking(statsTable)
end

function MapService.generateMap()
	local hexTemplate = ServerStorage:WaitForChild("HexPart", 5)
	if not hexTemplate then return end
	local mapFolder = workspace:FindFirstChild("Map") or Instance.new("Folder", workspace)
	mapFolder.Name = "Map"

	for floor = 1, HexConstants.FLOORS_COUNT do
		local floorFolder = Instance.new("Folder", mapFolder)
		floorFolder.Name = "Floor_" .. floor
		local yPos = HexConstants.START_HEIGHT + (floor * HexConstants.FLOOR_DISTANCE)
		local delayTime = HexConstants.GET_DELAY_TIME(floor)

		for q = -HexConstants.GRID_SIZE, HexConstants.GRID_SIZE do
			for r = math.max(-HexConstants.GRID_SIZE, -q - HexConstants.GRID_SIZE), math.min(HexConstants.GRID_SIZE, -q + HexConstants.GRID_SIZE) do
				local newPart = hexTemplate:Clone()
				CollectionService:AddTag(newPart, "HexPlatform")
				local x = 8.66 * 1.02 * (q + r/2)
				local z = 10 * 0.75 * 1.02 * r
				newPart.Position = Vector3.new(x, yPos, z)
				newPart.Parent = floorFolder
				newPart:SetAttribute("DelayTime", delayTime)
			end
		end
	end
end

function MapService.createKillZone()
	local killPart = Instance.new("Part")
	killPart.Size = Vector3.new(2048, 2, 2048)
	killPart.Position = Vector3.new(0, 20, 0)
	killPart.Anchored = true
	killPart.CanCollide = false
	killPart.Transparency = 1
	killPart.Parent = workspace
	killPart.Touched:Connect(function(hit)
		local hum = hit.Parent:FindFirstChild("Humanoid")
		if hum then hum.Health = 0 end
	end)
end

return MapService