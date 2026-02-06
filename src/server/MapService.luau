--
local CollectionService = game:GetService('CollectionService')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local ServerStorage = game:GetService('ServerStorage')

-- 스크린샷에서 확인된 대문자 Shared 경로 반영
local Shared = ReplicatedStorage:WaitForChild("Shared")
local HexConstants = require(Shared:WaitForChild("HexConstants"))

local MapService = {}

--
function MapService.createLobby()
	local lobbyCenter = Vector3.new(0, 500, 0)
	local lobbySize = 70 -- 가로세로 150의 넉넉한 크기
	local wallHeight = 40

	-- 1. 사각형 바닥 생성
	local floor = Instance.new("Part")
	floor.Name = "LobbyFloor"
	floor.Size = Vector3.new(lobbySize, 1, lobbySize)
	floor.Position = lobbyCenter
	floor.Anchored = true
	floor.Transparency = 0.5
	floor.Material = Enum.Material.SmoothPlastic
	floor.Parent = workspace
	-- 밟아도 안 사라지게 LobbyTag만 추가
	game:GetService("CollectionService"):AddTag(floor, "LobbyTag")

	-- 2. 사각형 벽 생성 (4면)
	local wallData = {
		{pos = Vector3.new(0, wallHeight/2, lobbySize/2), size = Vector3.new(lobbySize, wallHeight, 1)}, -- 앞
		{pos = Vector3.new(0, wallHeight/2, -lobbySize/2), size = Vector3.new(lobbySize, wallHeight, 1)}, -- 뒤
		{pos = Vector3.new(lobbySize/2, wallHeight/2, 0), size = Vector3.new(1, wallHeight, lobbySize)}, -- 우
		{pos = Vector3.new(-lobbySize/2, wallHeight/2, 0), size = Vector3.new(1, wallHeight, lobbySize)} -- 좌
	}

	for _, data in ipairs(wallData) do
		local wall = Instance.new("Part")
		wall.Size = data.size
		wall.Position = lobbyCenter + data.pos
		wall.Anchored = true
		wall.Transparency = 0
		wall.Material = Enum.Material.Glass
		wall.Parent = workspace
		game:GetService("CollectionService"):AddTag(wall, "LobbyTag")
	end

	-- 3. 스폰 지점 생성
	local spawnLoc = Instance.new("SpawnLocation")
	spawnLoc.Position = lobbyCenter + Vector3.new(0, 2, 0)
	spawnLoc.Size = Vector3.new(10, 1, 10)
	spawnLoc.Anchored = true
	spawnLoc.Transparency = 1
	spawnLoc.Parent = workspace
	game:GetService("CollectionService"):AddTag(spawnLoc, "LobbyTag")

	print("✅ 사각형 대기실 생성 완료 (틈새 없음)")
end

-- 2. 게임용 8층 맵 생성 함수
function MapService.generateMap()
	local hexTemplate = ServerStorage:WaitForChild("HexPart", 5)
	if not hexTemplate then return end

	local mapFolder = workspace:FindFirstChild("Map") or Instance.new("Folder", workspace)
	mapFolder.Name = "Map"

	-- HexConstants 수치를 기반으로 정밀 배치
	local HEX_WIDTH = 8.66
	local HEX_TALL = 10
	local GAP = 0.2

	local xOffset = HEX_WIDTH + GAP
	local zOffset = (HEX_TALL * 0.75) + (GAP * 0.866)

	for floor = 1, HexConstants.FLOORS_COUNT do
		local floorFolder = Instance.new("Folder", mapFolder)
		floorFolder.Name = "Floor_" .. floor

		-- 시작 높이와 층간 간격을 반영
		local yPos = HexConstants.START_HEIGHT + (floor * HexConstants.FLOOR_DISTANCE)
		local delayTime = HexConstants.GET_DELAY_TIME(floor)

		for q = -HexConstants.GRID_SIZE, HexConstants.GRID_SIZE do
			for r = math.max(-HexConstants.GRID_SIZE, -q - HexConstants.GRID_SIZE), math.min(HexConstants.GRID_SIZE, -q + HexConstants.GRID_SIZE) do

				local newPart = hexTemplate:Clone()

				-- [핵심] 게임용 발판에만 HexPlatform 태그를 추가하여 FloorService가 감지하게 함
				CollectionService:AddTag(newPart, "HexPlatform")

				local x = xOffset * (q + r/2)
				local z = zOffset * r

				newPart.Position = Vector3.new(x, yPos, z)
				newPart.Parent = floorFolder

				-- 층별 데이터 심기
				newPart:SetAttribute("DelayTime", delayTime)
			end
		end
		print(floor .. "층 생성 완료")
	end
end

function MapService.createKillZone()
	local size = 2048 -- 맵 전체를 덮는 충분한 크기
	local height = 20 -- 1층(130)보다 훨씬 아래인 지점

	local killPart = Instance.new("Part")
	killPart.Name = "KillZone"
	killPart.Size = Vector3.new(size, 2, size)
	killPart.Position = Vector3.new(0, height, 0)
	killPart.Anchored = true
	killPart.CanCollide = false -- 통과할 수 있어야 함
	killPart.Transparency = 1 -- 테스트를 위해 반투명하게 (나중에 1로 변경 가능)
	killPart.Material = Enum.Material.Neon
	killPart.Parent = workspace

	-- 닿으면 죽는 이벤트 연결
	killPart.Touched:Connect(function(hit)
		local character = hit.Parent
		local humanoid = character:FindFirstChild("Humanoid")
		if humanoid then
			humanoid.Health = 0 -- 즉사
		end
	end)

	print("🔥 Kill Zone (Lava) created at height: " .. height)
end

return MapService