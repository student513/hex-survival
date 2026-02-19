local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HexConstants = require(ReplicatedStorage.Shared.HexConstants)
local UpdateStatus = ReplicatedStorage:WaitForChild("UpdateStatus")

local ItemManager = {}

-- 모든 면에 데칼을 입히는 함수
local function applyDecals(part: BasePart, itemName: string)
	local iconId = HexConstants.ITEM_ICONS[itemName]
	if not iconId or iconId == "" then return end

	local faces = Enum.NormalId:GetEnumItems()
	for _, face in ipairs(faces) do
		local decal = Instance.new("Decal")
		decal.Texture = iconId
		decal.Face = face
		decal.Parent = part
	end
end

function ItemManager.createItemModel(itemName: string, isField: boolean)
	local part = Instance.new("Part")
	part.CanCollide = false
	part.Anchored = isField

	if isField then
		-- 필드 아이템: 완전히 투명한 구체에 이미지만 입힘
		part.Shape = Enum.PartType.Ball
		part.Size = Vector3.new(3.5, 3.5, 3.5) -- 이미지가 잘 보이게 크기 상향
		part.Transparency = 1 -- 구체 자체를 투명하게
		part.Material = Enum.Material.Plastic -- Neon의 빛 번짐 방지

		applyDecals(part, itemName)
	else
		-- 장착 시 (플레이어 손에 들릴 때)
		part.Transparency = 0
		part.Material = Enum.Material.Neon
		if itemName == "Hammer" then
			part.Size = Vector3.new(2, 3, 2)
			part.Color = Color3.fromRGB(150, 150, 150)
		else
			part.Shape = Enum.PartType.Ball
			part.Size = Vector3.new(1.5, 1.5, 1.5)
			-- 손에 들렸을 때만 색상 부여
			part.Color = (itemName == "Glue") and Color3.fromRGB(255, 170, 0) or Color3.fromRGB(170, 0, 255)
		end
	end

	return part
end

function ItemManager.giveItem(player: Player, itemName: string, floorPart: BasePart?)
	local char = player.Character
	if not char then return end
	local root = char:FindFirstChild("HumanoidRootPart")
	local hum = char:FindFirstChild("Humanoid")
	if not root or not hum then return end

	if itemName == "Glue" and floorPart then
		local currentDelay = floorPart:GetAttribute("DelayTime") or 1.0
		floorPart:SetAttribute("DelayTime", currentDelay * 1.5)
		floorPart.Color = Color3.fromRGB(150, 150, 255)
	elseif itemName == "Swapper" then
		-- 위치 교환기: 무작위 생존자와 위치 교체
		local others = {}
		for _, p in ipairs(Players:GetPlayers()) do
			if p ~= player and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
				table.insert(others, p)
			end
		end
		if #others > 0 then
			local target = others[math.random(1, #others)] -- target은 Player 객체
			local targetRoot = target.Character.HumanoidRootPart
			local myPos = root.CFrame

			-- 위치 교체
			root.CFrame = targetRoot.CFrame
			targetRoot.CFrame = myPos

			-- [추가] 본인과 상대방 모두에게 UI 신호 발송
			UpdateStatus:FireClient(player, "Swapped")
			UpdateStatus:FireClient(target, "Swapped")
		end
	elseif itemName == "Hammer" then
		local tool = ItemManager.createItemModel(itemName, false)
		tool.Parent = char
		local weld = Instance.new("Weld", tool)
		weld.Part0 = char:FindFirstChild("RightHand") or char:FindFirstChild("Right Arm")
		weld.Part1 = tool
		weld.C0 = CFrame.new(0, -1, 0) * CFrame.Angles(math.rad(90), 0, 0)

		tool.Touched:Connect(function(hit)
			local tChar = hit:FindFirstAncestorOfClass("Model")
			local tHum = tChar and tChar:FindFirstChildOfClass("Humanoid")
			local tRoot = tChar and tChar:FindFirstChild("HumanoidRootPart")

			if tHum and tRoot and tChar ~= char then
				if itemName == "Hammer" then
					tHum.PlatformStand = true
					local targetPlayer = Players:GetPlayerFromCharacter(tChar)
					if targetPlayer then
						UpdateStatus:FireClient(targetPlayer, "Stunned", 2)
					end
					task.delay(2, function() if tHum then tHum.PlatformStand = false end end)
				end
				tool:Destroy()
			end
		end)
		task.delay(10, function() if tool then tool:Destroy() end end)
	end
end

return ItemManager