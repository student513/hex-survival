local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HexConstants = require(ReplicatedStorage.Shared.HexConstants)
local UpdateStatus = ReplicatedStorage:WaitForChild("UpdateStatus")

local ItemManager = {}

-- 아이템 외형 생성 (필드용은 무조건 구체)
function ItemManager.createItemModel(itemName: string, isField: boolean)
	local part = Instance.new("Part")
	part.Material = Enum.Material.Neon
	part.CanCollide = false
	part.Anchored = isField

	if isField then
		part.Shape = Enum.PartType.Ball
		part.Size = Vector3.new(2.5, 2.5, 2.5)
		part.Color = Color3.fromRGB(255, 215, 0) -- 황금색 구체
	else
		-- 장착 시 고유 모델
		if itemName == "Hammer" then
			part.Size = Vector3.new(2, 3, 2)
			part.Color = Color3.fromRGB(150, 150, 150)
		else
			-- 구 모양 아이템(Glue, Swapper)은 손에서도 구 모양
			part.Shape = Enum.PartType.Ball
			part.Size = Vector3.new(1.5, 1.5, 1.5)
			part.Color = (itemName == "Glue") and Color3.fromRGB(100, 200, 255) or Color3.fromRGB(255, 100, 255)
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