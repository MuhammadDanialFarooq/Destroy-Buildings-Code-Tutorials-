local module = {}

local RunService = game:GetService("RunService")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local Players = game:GetService("Players")

local PointTemplate: BasePart = ReplicatedFirst.Assets.Point

local Player = Players.LocalPlayer

local Point: BasePart? = nil
local Connection: RBXScriptConnection? = nil

local CurrentTarget: BasePart? = nil

local Position = Vector3.zero
local Velocity = Vector3.zero

local Scale = 0
local ScaleVelocity = 0

local Visible = false

--------------------------------------------------
-- MOVEMENT
--------------------------------------------------

local SPRING_SPEED = 8
local SPRING_DAMPING = 0.82

--------------------------------------------------
-- SHOW / HIDE
--------------------------------------------------

local SCALE_SPEED = 10
local SCALE_DAMPING = 0.78

local SHOW_SCALE = 1
local HIDE_SCALE = 0

--------------------------------------------------
-- SHOW POSITION
--------------------------------------------------

local POP_HEIGHT = 1.5
local HIDE_DISTANCE = 1.5

--------------------------------------------------
-- IMAGE PULSE
--------------------------------------------------

local PULSE_SPEED = 3
local PULSE_AMOUNT = 0.06

--------------------------------------------------
-- ORIGINAL BILLBOARD SIZE
--------------------------------------------------

local OriginalBillboardSize: UDim2? = nil
local OriginalImageSize: UDim2? = nil

--------------------------------------------------
-- SPRING
--------------------------------------------------

local function Spring(
	current: number,
	velocity: number,
	target: number,
	speed: number,
	damping: number,
	deltaTime: number
)
	local acceleration =
		(target - current) * (speed * speed)

	velocity += acceleration * deltaTime

	velocity *= math.pow(
		damping,
		deltaTime * 60
	)

	current += velocity * deltaTime

	return current, velocity
end

--------------------------------------------------
-- PLAYER
--------------------------------------------------

local function GetRoot(): BasePart?
	local Character = Player.Character

	if not Character then
		return nil
	end

	return Character:FindFirstChild(
		"HumanoidRootPart"
	) :: BasePart?
end

--------------------------------------------------
-- BILLBOARD
--------------------------------------------------

local function GetBillboard(): BillboardGui?
	if not Point then
		return nil
	end

	return Point:FindFirstChildOfClass(
		"BillboardGui"
	)
end

--------------------------------------------------
-- IMAGE
--------------------------------------------------

local function GetImage(): ImageLabel?
	local Billboard = GetBillboard()

	if not Billboard then
		return nil
	end

	return Billboard:FindFirstChildWhichIsA(
		"ImageLabel",
		true
	)
end

--------------------------------------------------
-- STORE ORIGINAL SIZES
--------------------------------------------------

local function CacheSizes()
	local Billboard = GetBillboard()

	if Billboard and not OriginalBillboardSize then
		OriginalBillboardSize = Billboard.Size
	end

	local ImageLabel = GetImage()

	if ImageLabel and not OriginalImageSize then
		OriginalImageSize = ImageLabel.Size
	end
end

--------------------------------------------------
-- SCALE BILLBOARD
--------------------------------------------------

local function SetPointScale(scale: number)
	local Billboard = GetBillboard()

	if not Billboard then
		return
	end

	if not OriginalBillboardSize then
		CacheSizes()
	end

	if not OriginalBillboardSize then
		return
	end

	Billboard.Size = UDim2.new(
		OriginalBillboardSize.X.Scale * scale,
		OriginalBillboardSize.X.Offset * scale,

		OriginalBillboardSize.Y.Scale * scale,
		OriginalBillboardSize.Y.Offset * scale
	)
end

--------------------------------------------------
-- VISIBILITY
--------------------------------------------------

local function SetVisible(visible: boolean)
	if not Point then
		return
	end

	-- Physical Part is ALWAYS invisible.
	Point.Transparency = 1

	local Billboard = GetBillboard()

	if Billboard then
		Billboard.Enabled = visible
	end

	local ImageLabel = GetImage()

	if ImageLabel then
		ImageLabel.Visible = visible
	end
end

--------------------------------------------------
-- CREATE
--------------------------------------------------

local function CreatePoint()
	if Point then
		return
	end

	Point = PointTemplate:Clone()

	Point.Name = "TutorialPoint"

	-- The BasePart itself is never visible.
	Point.Transparency = 1

	Point.Parent = workspace

	CacheSizes()

	SetVisible(false)

	-- Start at original size.
	SetPointScale(1)
end

--------------------------------------------------
-- RENDER LOOP
--------------------------------------------------

local function StartRender()
	if Connection then
		return
	end

	Connection = RunService.RenderStepped:Connect(function(deltaTime)

		if not Point then
			return
		end

		local Root = GetRoot()

		if not Root then
			return
		end

		--------------------------------------------------
		-- TARGET POSITION
		--------------------------------------------------

		local TargetPosition: Vector3

		if CurrentTarget
			and CurrentTarget.Parent then

			TargetPosition =
				CurrentTarget.Position

		else

			TargetPosition =
				Root.Position
				+ Vector3.new(0, POP_HEIGHT, 0)
		end

		--------------------------------------------------
		-- POSITION SPRING
		--------------------------------------------------

		Position, Velocity = Spring(
			Position,
			Velocity,
			TargetPosition,
			SPRING_SPEED,
			SPRING_DAMPING,
			deltaTime
		)

		Point.Position = Position

		--------------------------------------------------
		-- SCALE SPRING
		--------------------------------------------------

		local TargetScale =
			if Visible
			then SHOW_SCALE
			else HIDE_SCALE

		Scale, ScaleVelocity = Spring(
			Scale,
			ScaleVelocity,
			TargetScale,
			SCALE_SPEED,
			SCALE_DAMPING,
			deltaTime
		)

		SetPointScale(
			math.clamp(Scale, 0, 1)
		)

		--------------------------------------------------
		-- HIDDEN
		--------------------------------------------------

		if not Visible
			and Scale <= 0.01 then

			SetVisible(false)
		end

		--------------------------------------------------
		-- IMAGE PULSE
		--------------------------------------------------

		if Visible then

			local ImageLabel = GetImage()

			if ImageLabel
				and OriginalImageSize then

				local Time = os.clock()

				local Pulse =
					1
					+ math.sin(
						Time * PULSE_SPEED
					) * PULSE_AMOUNT

				ImageLabel.Size = UDim2.new(
					OriginalImageSize.X.Scale * Pulse,
					OriginalImageSize.X.Offset * Pulse,

					OriginalImageSize.Y.Scale * Pulse,
					OriginalImageSize.Y.Offset * Pulse
				)

				ImageLabel.Rotation =
					math.sin(Time * 4) * 2
			end
		end
	end)
end

--------------------------------------------------
-- SHOW
--------------------------------------------------

function module:Show()

	local Root = GetRoot()

	if not Root then
		return
	end

	CreatePoint()

	if not Point then
		return
	end

	CurrentTarget = nil

	Visible = true

	SetVisible(true)

	--------------------------------------------------
	-- START INSIDE PLAYER
	--------------------------------------------------

	Position =
		Root.Position
	- Root.CFrame.LookVector * HIDE_DISTANCE

	Position += Vector3.new(
		0,
		0.5,
		0
	)

	Velocity = Vector3.zero

	--------------------------------------------------
	-- POP OUT
	--------------------------------------------------

	Scale = 0
	ScaleVelocity = 0

	SetPointScale(0)

	StartRender()
end

--------------------------------------------------
-- MOVE TO
--------------------------------------------------

function module:MoveTo(Part: BasePart)

	if not Part
		or not Part:IsA("BasePart") then

		return
	end

	CreatePoint()

	if not Point then
		return
	end

	CurrentTarget = Part

	Visible = true

	SetVisible(true)

	StartRender()
end

--------------------------------------------------
-- HIDE
--------------------------------------------------

function module:Hide()

	if not Point then
		return
	end

	local Root = GetRoot()

	Visible = false

	CurrentTarget = nil

	--------------------------------------------------
	-- FLY BACK TOWARD PLAYER
	--------------------------------------------------

	if Root then

		local Direction =
			Root.Position
		- Point.Position

		if Direction.Magnitude > 0.01 then

			Velocity =
				Direction.Unit * 4

		else

			Velocity = Vector3.zero
		end
	end

	StartRender()
end

--------------------------------------------------
-- DESTROY
--------------------------------------------------

function module:Destroy()

	Visible = false
	CurrentTarget = nil

	if Connection then
		Connection:Disconnect()
		Connection = nil
	end

	if Point then
		Point:Destroy()
		Point = nil
	end

	OriginalBillboardSize = nil
	OriginalImageSize = nil
end

return module
