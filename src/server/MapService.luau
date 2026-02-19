local CollectionService = game:GetService('CollectionService')
local Players = game:GetService('Players')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local ServerStorage = game:GetService('ServerStorage')

local Shared = ReplicatedStorage:WaitForChild("Shared")
local HexConstants = require(Shared:WaitForChild("HexConstants"))
local ItemManager = require(script.Parent.ItemManager)

local MapService = {}

function MapService.updateMatchBoards(matchPoints, lastWinnerName, isMatchRunning)
	local boards = {
		workspace:FindFirstChild("MainMatchBoard"),
		workspace:FindFirstChild("GameMatchBoard")
	}

	for _, board in ipairs(boards) do
		if not board then continue end
		local gui = board:FindFirstChild("SurfaceGui")
		if not gui then continue end

		gui.Enabled = true

		local title = gui:FindFirstChild("TitleLabel")
		if title then title.Text = "🏆 Last Winner: " .. (lastWinnerName or "None") end

		local container = gui:FindFirstChild("ScrollingFrame")
		if container then
			for _, child in ipairs(container:GetChildren()) do
				if child:IsA("Frame") then child:Destroy() end
			end

			local displayList = {}
			for name, data in pairs(matchPoints) do
				table.insert(displayList, {name = name, score = data.score, time = data.lastWinTime})
			end

			if #displayList == 0 then
				local row = Instance.new("Frame", container)
				row.Size = UDim2.new(1, 0, 0, 45)
				row.BackgroundTransparency = 1

				local placeholder = Instance.new("TextLabel", row)
				placeholder.Size = UDim2.new(1, 0, 1, 0)
				placeholder.Text = isMatchRunning and "- WAITING FOR RECORDS -" or "- WAITING FOR PLAYERS -"
				placeholder.TextColor3 = Color3.fromRGB(150, 150, 150)
				placeholder.BackgroundTransparency = 1
				placeholder.Font = Enum.Font.GothamBold
				placeholder.TextScaled = true
				continue
			end

			table.sort(displayList, function(a, b)
				if a.score ~= b.score then return a.score > b.score end
				return a.time > b.time
			end)

			for i, data in ipairs(displayList) do
				local row = Instance.new("Frame", container)
				row.Size = UDim2.new(1, 0, 0, 45)
				row.BackgroundTransparency = 1

				local rank = Instance.new("TextLabel", row)
				rank.Size = UDim2.new(0.1, 0, 1, 0)
				rank.Text = i .. "."
				rank.TextColor3 = Color3.new(1,1,1)
				rank.BackgroundTransparency = 1
				rank.Font = Enum.Font.GothamBold
				rank.TextScaled = true
				rank.TextXAlignment = Enum.TextXAlignment.Left

				local nameLabel = rank:Clone()
				nameLabel.Size = UDim2.new(0.65, 0, 1, 0)
				nameLabel.Position = UDim2.new(0.1, 0, 0, 0)
				nameLabel.Text = data.name
				nameLabel.TextXAlignment = Enum.TextXAlignment.Left
				nameLabel.Parent = row

				local scoreLabel = rank:Clone()
				scoreLabel.Size = UDim2.new(0.25, 0, 1, 0)
				scoreLabel.Position = UDim2.new(0.75, 0, 0, 0)
				scoreLabel.Text = data.score .. " pt"
				scoreLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
				scoreLabel.TextXAlignment = Enum.TextXAlignment.Right
				scoreLabel.Parent = row
			end
		end
	end
end

function MapService.createMainLobby()
	local lobbyCenter = HexConstants.MAIN_LOBBY_POS
	local lobbySize = 100
	local wallHeight = 300
	local parkourMaxHeight = lobbyCenter.Y + 200

	local floor = Instance.new("Part")
	floor.Name = "MainLobbyFloor"
	floor.Size = Vector3.new(lobbySize, 2, lobbySize)
	floor.Position = lobbyCenter - Vector3.new(0, 1, 0)
	floor.Anchored = true
	floor.Color = Color3.fromRGB(30, 30, 30)
	floor.Material = Enum.Material.Concrete
	floor.Parent = workspace

	-- 1. 매치 전광판 (남쪽 벽)
	local board = Instance.new("Part")
	board.Name = "MainMatchBoard"
	board.Size = Vector3.new(40, 30, 1)
	board.Position = lobbyCenter + Vector3.new(0, 15, 49)
	board.Anchored = true
	board.Color = Color3.fromRGB(15, 15, 15)
	board.Parent = workspace

	local gui = Instance.new("SurfaceGui", board)
	gui.Name = "SurfaceGui"
	gui.Face = Enum.NormalId.Front
	gui.LightInfluence = 0
	gui.Enabled = true

	local title = Instance.new("TextLabel", gui)
	title.Name = "TitleLabel"
	title.Size = UDim2.new(1, 0, 0, 50)
	title.BackgroundTransparency = 1
	title.TextColor3 = Color3.fromRGB(150, 255, 150)
	title.TextScaled = true
	title.Font = Enum.Font.GothamBlack

	local scroll = Instance.new("ScrollingFrame", gui)
	scroll.Name = "ScrollingFrame"
	scroll.Size = UDim2.new(1, -40, 1, -80)
	scroll.Position = UDim2.new(0, 20, 0, 60)
	scroll.BackgroundTransparency = 1
	scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	Instance.new("UIListLayout", scroll).Padding = UDim.new(0, 10)

	-- 2. 아이템 가이드 전광판 (서쪽 벽)
	local guideBoard = Instance.new("Part")
	guideBoard.Name = "ItemGuideBoard"
	guideBoard.Size = Vector3.new(1, 30, 40)
	guideBoard.Position = lobbyCenter + Vector3.new(-49, 15, 0)
	guideBoard.Anchored = true
	guideBoard.Color = Color3.fromRGB(15, 15, 15)
	guideBoard.Parent = workspace

	local guideGui = Instance.new("SurfaceGui", guideBoard)
	guideGui.Name = "SurfaceGui"
	guideGui.Face = Enum.NormalId.Right
	guideGui.LightInfluence = 0

	local guideTitle = Instance.new("TextLabel", guideGui)
	guideTitle.Size = UDim2.new(1, 0, 0, 60)
	guideTitle.BackgroundTransparency = 1
	guideTitle.TextColor3 = Color3.fromRGB(100, 200, 255)
	guideTitle.Text = "💡 ITEM GUIDE"
	guideTitle.TextScaled = true
	guideTitle.Font = Enum.Font.GothamBlack

	local itemDescriptions = {
		{ name = "Glue", desc = "Extends the disappearance time of the stepped platform by 1.5x." },
		{ name = "Swapper", desc = "Instantly swaps positions with a random surviving player." },
		{ name = "Hammer", desc = "Stun other players for 2 seconds by hitting them after equipping." }
	}

	local listFrame = Instance.new("Frame", guideGui)
	listFrame.Size = UDim2.new(1, -40, 1, -80)
	listFrame.Position = UDim2.new(0, 20, 0, 80)
	listFrame.BackgroundTransparency = 1

	local layout = Instance.new("UIListLayout", listFrame)
	layout.Padding = UDim.new(0, 25)
	layout.SortOrder = Enum.SortOrder.LayoutOrder

	for i, info in ipairs(itemDescriptions) do
		local row = Instance.new("Frame", listFrame)
		row.Size = UDim2.new(1, 0, 0, 80)
		row.BackgroundTransparency = 1
		row.LayoutOrder = i

		local icon = Instance.new("ImageLabel", row)
		icon.Size = UDim2.new(0, 80, 0, 80)
		icon.BackgroundTransparency = 1
		icon.Image = HexConstants.ITEM_ICONS[info.name]

		local text = Instance.new("TextLabel", row)
		text.Size = UDim2.new(1, -100, 1, 0)
		text.Position = UDim2.new(0, 100, 0, 0)
		text.BackgroundTransparency = 1
		text.Text = info.desc
		text.TextColor3 = Color3.new(1, 1, 1)
		text.TextScaled = true
		text.TextXAlignment = Enum.TextXAlignment.Left
		text.Font = Enum.Font.GothamBold
	end

	-- ==========================================
	-- 3. [추가] 규칙 전광판 (동쪽 벽)
	-- ==========================================
	local ruleBoard = Instance.new("Part")
	ruleBoard.Name = "RuleBoard"
	ruleBoard.Size = Vector3.new(1, 30, 40)
	ruleBoard.Position = lobbyCenter + Vector3.new(49, 15, 0)
	ruleBoard.Anchored = true
	ruleBoard.Color = Color3.fromRGB(15, 15, 15)
	ruleBoard.Parent = workspace

	local ruleGui = Instance.new("SurfaceGui", ruleBoard)
	ruleGui.Name = "SurfaceGui"
	ruleGui.Face = Enum.NormalId.Left -- 동쪽 벽에서 로비 중앙을 바라보도록 설정
	ruleGui.LightInfluence = 0

	local ruleTitle = Instance.new("TextLabel", ruleGui)
	ruleTitle.Size = UDim2.new(1, 0, 0, 60)
	ruleTitle.BackgroundTransparency = 1
	ruleTitle.TextColor3 = Color3.fromRGB(255, 170, 0)
	ruleTitle.Text = "📜 GAME RULES"
	ruleTitle.TextScaled = true
	ruleTitle.Font = Enum.Font.GothamBlack

	local rulesList = {
		"1. SURVIVE OR FALL\nHexagons disappear shortly after you step on them. Don't fall into the Kill Zone!",
		"2. WIN CONDITION\nBe the last person standing to win the round. Reach 3 Wins to become the Match Champion.",
		"3. SPECIAL TILES & ITEMS\nWatch out for Magma, Bounce, or Turbo floors. Collect Items to gain an advantage.",
    "4. LOBBY PARKOUR\nEnjoy Parkour while waiting! Reach the top to earn a special reward title."
	}

	local ruleListFrame = Instance.new("Frame", ruleGui)
	ruleListFrame.Size = UDim2.new(1, -40, 1, -80)
	ruleListFrame.Position = UDim2.new(0, 20, 0, 80)
	ruleListFrame.BackgroundTransparency = 1

	local ruleLayout = Instance.new("UIListLayout", ruleListFrame)
	ruleLayout.Padding = UDim.new(0, 25)
	ruleLayout.SortOrder = Enum.SortOrder.LayoutOrder

	for i, ruleText in ipairs(rulesList) do
		local textLabel = Instance.new("TextLabel", ruleListFrame)
		textLabel.Size = UDim2.new(1, 0, 0, 80)
		textLabel.BackgroundTransparency = 1
		textLabel.Text = ruleText
		textLabel.TextColor3 = Color3.new(1, 1, 1)
		textLabel.TextWrapped = true
		textLabel.TextScaled = true
		textLabel.TextXAlignment = Enum.TextXAlignment.Left
		textLabel.TextYAlignment = Enum.TextYAlignment.Top
		textLabel.Font = Enum.Font.GothamBold
		textLabel.LayoutOrder = i
	end
	-- ==========================================

	local parkourFolder = Instance.new("Folder", workspace)
	parkourFolder.Name = "ParkourCourse"

	local hexTemplate = ServerStorage:WaitForChild("HexPart")
	local floor8Delay = HexConstants.GET_DELAY_TIME(8)

	local currentPos = lobbyCenter + Vector3.new(math.random(-40, 40), 2, math.random(-40, 40))

	while currentPos.Y < parkourMaxHeight do
		local part = hexTemplate:Clone()
		CollectionService:AddTag(part, "HexPlatform")

		part.Position = currentPos
		part.Anchored = true
		part:SetAttribute("IsParkour", true)
		part:SetAttribute("DelayTime", floor8Delay)
		part.Color = Color3.fromRGB(0, 170, 255)
		part:SetAttribute("OriginalColor", part.Color)
		part.Parent = parkourFolder

		local maxJumpHeight = 6
		local minJumpHeight = 4
		local maxHorizontalDist = 12
		local minHorizontalDist = 8

		local nextY = currentPos.Y + math.random(minJumpHeight, maxJumpHeight)
		local nextX, nextZ
		local validPosition = false

		while not validPosition do
			local angle = math.random() * math.pi * 2
			local dist = math.random(minHorizontalDist, maxHorizontalDist)

			nextX = currentPos.X + math.cos(angle) * dist
			nextZ = currentPos.Z + math.sin(angle) * dist

			if math.abs(nextX - lobbyCenter.X) <= 45 and math.abs(nextZ - lobbyCenter.Z) <= 45 then
				validPosition = true
			end
		end

		currentPos = Vector3.new(nextX, nextY, nextZ)

		if currentPos.Y >= parkourMaxHeight then
			local goalPart = hexTemplate:Clone()
			CollectionService:AddTag(goalPart, "HexPlatform")
			goalPart.Position = currentPos
			goalPart.Anchored = true
			goalPart:SetAttribute("IsParkour", true)
			goalPart:SetAttribute("IsParkourGoal", true)
			goalPart:SetAttribute("DelayTime", floor8Delay)
			goalPart.Color = Color3.fromRGB(255, 215, 0)
			goalPart:SetAttribute("OriginalColor", goalPart.Color)
			goalPart.Parent = parkourFolder
			break
		end
	end

	local half = lobbySize / 2
	local wallData = {
		{pos = Vector3.new(0, wallHeight/2, half), size = Vector3.new(lobbySize, wallHeight, 1)},
		{pos = Vector3.new(0, wallHeight/2, -half), size = Vector3.new(lobbySize, wallHeight, 1)},
		{pos = Vector3.new(half, wallHeight/2, 0), size = Vector3.new(1, wallHeight, lobbySize)},
		{pos = Vector3.new(-half, wallHeight/2, 0), size = Vector3.new(1, wallHeight, lobbySize)}
	}
	for _, data in ipairs(wallData) do
		local wall = Instance.new("Part")
		wall.Size = data.size
		wall.Position = floor.Position + data.pos
		wall.Anchored = true
		wall.Transparency = 0.8
		wall.Material = Enum.Material.Glass
		wall.Parent = workspace
	end
	print("🏠 메인 로비 생성 완료 (위치: 남쪽 300, 높이 300, 크기 100)")
end

function MapService.createLobby()
	local lobbyCenter = HexConstants.GAME_LOBBY_POS - Vector3.new(0, 5, 0)
	local floor = Instance.new("Part")
	floor.Size = Vector3.new(70, 1, 70)
	floor.Position = lobbyCenter
	floor.Anchored = true
	floor.Parent = workspace
	CollectionService:AddTag(floor, "LobbyTag")

	local wallData = {
		{pos = Vector3.new(0, 20, 35), size = Vector3.new(70, 40, 1)},
		{pos = Vector3.new(0, 20, -35), size = Vector3.new(70, 40, 1)},
		{pos = Vector3.new(35, 20, 0), size = Vector3.new(1, 40, 70)},
		{pos = Vector3.new(-35, 20, 0), size = Vector3.new(1, 40, 70)}
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

	local board = Instance.new("Part")
	board.Name = "GameMatchBoard"
	board.Size = Vector3.new(40, 30, 1)
	board.Position = lobbyCenter + Vector3.new(0, 15, -34)
	board.Anchored = true
	board.Color = Color3.fromRGB(15, 15, 15)
	board.Parent = workspace
	CollectionService:AddTag(board, "LobbyTag")

	local gui = Instance.new("SurfaceGui", board)
	gui.Name = "SurfaceGui"
	gui.Face = Enum.NormalId.Back
	gui.LightInfluence = 0

	local title = Instance.new("TextLabel", gui)
	title.Name = "TitleLabel"
	title.Size = UDim2.new(1, 0, 0, 50)
	title.BackgroundTransparency = 1
	title.TextColor3 = Color3.fromRGB(150, 255, 150)
	title.TextScaled = true
	title.Font = Enum.Font.GothamBlack

	local scroll = Instance.new("ScrollingFrame", gui)
	scroll.Name = "ScrollingFrame"
	scroll.Size = UDim2.new(1, -40, 1, -80)
	scroll.Position = UDim2.new(0, 20, 0, 60)
	scroll.BackgroundTransparency = 1
	scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	Instance.new("UIListLayout", scroll).Padding = UDim.new(0, 10)
end

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
			typeName = ({"Magma", "Bounce", "Turbo"})[math.random(1, 3)]
		end
		floorFolder:SetAttribute("FloorType", typeName)

		local delayTime = HexConstants.GET_DELAY_TIME(floor)
		if typeName == "Magma" then delayTime /= 2.5 end

		for q = -HexConstants.GRID_SIZE, HexConstants.GRID_SIZE do
			for r = math.max(-HexConstants.GRID_SIZE, -q - HexConstants.GRID_SIZE), math.min(HexConstants.GRID_SIZE, -q + HexConstants.GRID_SIZE) do
				if math.random(1, 100) <= 15 and floor < HexConstants.FLOORS_COUNT then continue end

				local newPart = hexTemplate:Clone()
				CollectionService:AddTag(newPart, "HexPlatform")

				if typeName == "Magma" then
					newPart.Color = Color3.fromRGB(255, 80, 0)
					newPart.Material = Enum.Material.Neon
				elseif typeName == "Bounce" then
					newPart.Color = Color3.fromRGB(100, 255, 100)
					newPart.Material = Enum.Material.Rubber
				elseif typeName == "Turbo" then
					newPart.Color = Color3.fromRGB(255, 255, 0)
					newPart.Material = Enum.Material.Neon
				end

				if math.random(1, 100) <= HexConstants.ITEM_SPAWN_CHANCE then
					local itemTypes = {"Glue", "Swapper", "Hammer"}
					local selected = itemTypes[math.random(1, #itemTypes)]
					local visual = ItemManager.createItemModel(selected, true)
					visual.Position = Vector3.new(8.66 * 1.02 * (q + r/2), (HexConstants.START_HEIGHT + (floor * HexConstants.FLOOR_DISTANCE)) + 2.5, 10 * 0.75 * 1.02 * r)
					visual.Parent = newPart
					CollectionService:AddTag(visual, "ItemObject")
					visual:SetAttribute("ItemType", selected)
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
	kill.Position = Vector3.new(0, HexConstants.KILL_ZONE_Y, 0)
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