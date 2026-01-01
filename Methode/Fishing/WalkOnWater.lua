-- ULTRA STABLE WALK ON WATER V3.2 (MODULE EDITION)
-- AUTO SURFACE LIFT
-- NO CHAT COMMAND
-- GUI / TOGGLE FRIENDLY
-- CLIENT SAFE | RAYCAST ONLY

repeat task.wait() until game:IsLoaded()

----------------------------------------------------------
-- SERVICES
----------------------------------------------------------
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer

----------------------------------------------------------
-- STATE
----------------------------------------------------------
local WalkOnWater = {
	Enabled = false,
	Platform = nil,
	AlignPos = nil,
	Connection = nil
}

local PLATFORM_SIZE = 14
local OFFSET = 3
local LAST_WATER_Y = nil

----------------------------------------------------------
-- CHARACTER
----------------------------------------------------------
local function GetCharacterReferences()
	local char = LocalPlayer.Character
	if not char then return end

	local humanoid = char:FindFirstChildOfClass("Humanoid")
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not humanoid or not hrp then return end

	return char, humanoid, hrp
end

----------------------------------------------------------
-- FORCE SURFACE LIFT (ANTI STUCK)
----------------------------------------------------------
local function ForceSurfaceLift()
	local _, humanoid, hrp = GetCharacterReferences()
	if not humanoid or not hrp then return end

	if humanoid:GetState() ~= Enum.HumanoidStateType.Swimming then
		return
	end

	for _ = 1, 60 do
		hrp.Velocity = Vector3.new(0, 80, 0)
		task.wait(0.03)

		if humanoid:GetState() ~= Enum.HumanoidStateType.Swimming then
			break
		end
	end

	hrp.CFrame = hrp.CFrame + Vector3.new(0, 3, 0)
end

----------------------------------------------------------
-- WATER DETECTION (RAYCAST ONLY)
----------------------------------------------------------
local function GetWaterHeight()
	local _, _, hrp = GetCharacterReferences()
	if not hrp then return LAST_WATER_Y end

	local origin = hrp.Position + Vector3.new(0, 5, 0)

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Blacklist
	params.FilterDescendantsInstances = { LocalPlayer.Character }
	params.IgnoreWater = false

	local result = Workspace:Raycast(
		origin,
		Vector3.new(0, -600, 0),
		params
	)

	if result then
		LAST_WATER_Y = result.Position.Y
		return LAST_WATER_Y
	end

	return LAST_WATER_Y
end

----------------------------------------------------------
-- PLATFORM
----------------------------------------------------------
local function CreatePlatform()
	if WalkOnWater.Platform then
		WalkOnWater.Platform:Destroy()
	end

	local p = Instance.new("Part")
	p.Size = Vector3.new(PLATFORM_SIZE, 1, PLATFORM_SIZE)
	p.Anchored = true
	p.CanCollide = true
	p.Transparency = 1
	p.CanQuery = false
	p.CanTouch = false
	p.Name = "WaterLockPlatform"
	p.Parent = Workspace

	WalkOnWater.Platform = p
end

----------------------------------------------------------
-- ALIGN POSITION
----------------------------------------------------------
local function SetupAlign()
	local _, _, hrp = GetCharacterReferences()
	if not hrp then return false end

	if WalkOnWater.AlignPos then
		WalkOnWater.AlignPos:Destroy()
	end

	local att = hrp:FindFirstChild("RootAttachment")
	if not att then
		att = Instance.new("Attachment")
		att.Name = "RootAttachment"
		att.Parent = hrp
	end

	local ap = Instance.new("AlignPosition")
	ap.Attachment0 = att
	ap.MaxForce = math.huge
	ap.MaxVelocity = math.huge
	ap.Responsiveness = 200
	ap.RigidityEnabled = true
	ap.Parent = hrp

	WalkOnWater.AlignPos = ap
	return true
end

----------------------------------------------------------
-- CLEANUP
----------------------------------------------------------
local function Cleanup()
	if WalkOnWater.Connection then
		WalkOnWater.Connection:Disconnect()
		WalkOnWater.Connection = nil
	end

	if WalkOnWater.AlignPos then
		WalkOnWater.AlignPos:Destroy()
		WalkOnWater.AlignPos = nil
	end

	if WalkOnWater.Platform then
		WalkOnWater.Platform:Destroy()
		WalkOnWater.Platform = nil
	end
end

----------------------------------------------------------
-- START
----------------------------------------------------------
function WalkOnWater.Start()
	if WalkOnWater.Enabled then return end

	local char, humanoid, hrp = GetCharacterReferences()
	if not char or not humanoid or not hrp then return end

	ForceSurfaceLift()

	WalkOnWater.Enabled = true
	LAST_WATER_Y = nil

	CreatePlatform()
	if not SetupAlign() then
		WalkOnWater.Enabled = false
		Cleanup()
		return
	end

	WalkOnWater.Connection = RunService.Heartbeat:Connect(function()
		if not WalkOnWater.Enabled then return end

		local _, _, currentHRP = GetCharacterReferences()
		if not currentHRP then return end

		local waterY = GetWaterHeight()
		if not waterY then return end

		if WalkOnWater.Platform then
			WalkOnWater.Platform.CFrame = CFrame.new(
				currentHRP.Position.X,
				waterY - 0.5,
				currentHRP.Position.Z
			)
		end

		if WalkOnWater.AlignPos then
			WalkOnWater.AlignPos.Position = Vector3.new(
				currentHRP.Position.X,
				waterY + OFFSET,
				currentHRP.Position.Z
			)
		end
	end)
end

----------------------------------------------------------
-- STOP
----------------------------------------------------------
function WalkOnWater.Stop()
	WalkOnWater.Enabled = false
	Cleanup()
end

----------------------------------------------------------
-- RESPAWN SAFE
----------------------------------------------------------
LocalPlayer.CharacterAdded:Connect(function()
	if WalkOnWater.Enabled then
		task.wait(0.5)
		Cleanup()
		WalkOnWater.Enabled = false
		WalkOnWater.Start()
	end
end)

----------------------------------------------------------
return WalkOnWater
