local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage") -- [추가] 모델 참조를 위해 필요
local HexConstants = require(ReplicatedStorage.Shared.HexConstants)
local UpdateStatus = ReplicatedStorage:WaitForChild("UpdateStatus")

local ItemManager = {}

-- 아이템 외형 생성 로직
function ItemManager.createItemModel(itemName: string, isField: boolean)
	if isField then
		-- 필드 아이템: 투명 구체 + 데칼 로직 (기존 유지)
		local part = Instance.new("Part")
		part.Shape = Enum.PartType.Ball
		part.Size = Vector3.new(3.5, 3.5, 3.5)
		part.Transparency = 1
		part.Anchored = true
		part.CanCollide = false

		local iconId = HexConstants.ITEM_ICONS[itemName]
		if iconId then
			for _, face in ipairs(Enum.NormalId:GetEnumItems()) do
				local decal = Instance.new("Decal")
				decal.Texture = iconId
				decal.Face = face
				decal.Parent = part
			end
		end
		return part
	else
		-- [수정] 플레이어가 획득 시 손에 들릴 모델
		if itemName == "Hammer" then
			-- ServerStorage에 저장된 "HammerModel"을 찾습니다.
			local originalModel = ServerStorage:FindFirstChild("HammerModel")
			if originalModel then
				local clone = originalModel:Clone()
				-- 모델 내부에 타격 판정을 위한 파트가 필요합니다 (보통 'Head' 혹은 'Handle')
				local handle = clone:FindFirstChild("Handle") or clone:FindFirstChildWhichIsA("BasePart")
				return clone, handle
			else
				warn("⚠️ ServerStorage에서 'HammerModel'을 찾을 수 없습니다!")
			end
		end

		-- 기타 아이템 처리 (기존 유지)
		local part = Instance.new("Part")
		part.Shape = Enum.PartType.Ball
		part.Size = Vector3.new(1.5, 1.5, 1.5)
		part.Material = Enum.Material.Neon
		part.Color = (itemName == "Glue") and Color3.fromRGB(255, 170, 0) or Color3.fromRGB(170, 0, 255)
		return part, part
	end
end

function ItemManager.giveItem(player: Player, itemName: string, floorPart: BasePart?)
	local char = player.Character
	if not char then return end
	local root = char:FindFirstChild("HumanoidRootPart")
	local hum = char:FindFirstChild("Humanoid")
	local hand = char:FindFirstChild("RightHand") or char:FindFirstChild("Right Arm")
	if not root or not hum or not hand then return end

	if itemName == "Glue" and floorPart then
		-- 발판 소멸 시간 1.5배 연장
		local currentDelay = floorPart:GetAttribute("DelayTime") or 1.0
		floorPart:SetAttribute("DelayTime", currentDelay * HexConstants.GLUE_MULTIPLIER)
		floorPart.Color = Color3.fromRGB(150, 150, 255)
	elseif itemName == "Swapper" then
		-- 위치 교환 로직 및 UI 신호 발송
		local others = {}
		for _, p in ipairs(Players:GetPlayers()) do
			if p ~= player and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
				table.insert(others, p)
			end
		end
		if #others > 0 then
			local target = others[math.random(1, #others)]
			local targetRoot = target.Character.HumanoidRootPart
			local myPos = root.CFrame
			root.CFrame = targetRoot.CFrame
			targetRoot.CFrame = myPos
			UpdateStatus:FireClient(player, "Swapped")
			UpdateStatus:FireClient(target, "Swapped")
		end
	elseif itemName == "Hammer" then
		-- [수정] 툴박스 모델 장착 로직
		local hammerModel, handlePart = ItemManager.createItemModel(itemName, false)
		if not hammerModel or not handlePart then return end

		hammerModel.Parent = char

		-- 캐릭터 손에 모델 고정
		local weld = Instance.new("Weld", handlePart)
		weld.Part0 = hand
		weld.Part1 = handlePart
		-- 툴박스 모델의 방향에 따라 C0 좌표(위치/회전) 조정이 필요할 수 있습니다.
		weld.C0 = CFrame.new(0, -1, 0) * CFrame.Angles(math.rad(-90), 0, 0)

		-- 모델 내의 모든 파트에 대해 타격 판정 연결
		for _, part in ipairs(hammerModel:GetDescendants()) do
			if part:IsA("BasePart") then
				part.Touched:Connect(function(hit)
					local tChar = hit:FindFirstAncestorOfClass("Model")
					local tHum = tChar and tChar:FindFirstChildOfClass("Humanoid")
					if tHum and tChar ~= char then
						-- 2초 스턴 및 UI 알림
						tHum.PlatformStand = true
						local targetPlayer = Players:GetPlayerFromCharacter(tChar)
						if targetPlayer then
							UpdateStatus:FireClient(targetPlayer, "Stunned", HexConstants.STUN_DURATION)
						end
						task.delay(HexConstants.STUN_DURATION, function()
							if tHum then tHum.PlatformStand = false end
						end)
						hammerModel:Destroy()
					end
				end)
			end
		end

		task.delay(10, function() if hammerModel then hammerModel:Destroy() end end)
	end
end

return ItemManager