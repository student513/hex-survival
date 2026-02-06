--
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local ServerStorage = game:GetService('ServerStorage')
local Shared = ReplicatedStorage:WaitForChild("Shared")
local HexConstants = require(Shared:WaitForChild("HexConstants"))

local MapService = {}

function MapService.generateMap()
	local hexTemplate = ServerStorage:WaitForChild("HexPart", 5)
	if not hexTemplate then return end

	local mapFolder = workspace:FindFirstChild("Map") or Instance.new("Folder", workspace)
	mapFolder.Name = "Map"

	-- [수정] 주신 사이즈를 기반으로 한 정밀 간격 계산
	local HEX_WIDTH = 8.66  -- 타일의 X 사이즈
	local HEX_TALL = 10     -- 타일의 Z 사이즈 (가장 긴 대각선)
	local GAP = 0.2         -- 타일 사이의 미세한 간격 (원하는 만큼 조절하세요)

	-- 육각형 배치를 위한 최종 오프셋
	local xOffset = HEX_WIDTH + GAP
	local zOffset = (HEX_TALL * 0.75) + (GAP * 0.866)

	for floor = 1, HexConstants.FLOORS_COUNT do
		local floorFolder = Instance.new("Folder", mapFolder)
		floorFolder.Name = "Floor_" .. floor

	  local yPos = HexConstants.START_HEIGHT + (floor * HexConstants.FLOOR_DISTANCE)
		local delayTime = HexConstants.GET_DELAY_TIME(floor)

		for q = -HexConstants.GRID_SIZE, HexConstants.GRID_SIZE do
			for r = math.max(-HexConstants.GRID_SIZE, -q - HexConstants.GRID_SIZE), math.min(HexConstants.GRID_SIZE, -q + HexConstants.GRID_SIZE) do

				local newPart = hexTemplate:Clone()

				-- 어긋나게 배치하여 벌집 모양을 만드는 공식
				local x = xOffset * (q + r/2)
				local z = zOffset * r

				newPart.Position = Vector3.new(x, yPos, z)

				-- 만약 타일 방향이 90도 돌아가 있다면 아래 주석을 해제하세요.
				-- newPart.Orientation = Vector3.new(0, 90, 0)

				newPart.Parent = floorFolder
				newPart:SetAttribute("DelayTime", delayTime)
			end
		end
		print(floor .. "층 생성 완료 (간격 반영)")
	end
end

return MapService