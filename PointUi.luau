local module = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")

local Spring = require(ReplicatedStorage.Module.Libraries.Spring)

local PlayerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
local PointUi = PlayerGui:WaitForChild("Point")
local ImageLabel = PointUi:WaitForChild("ImageLabel")

local self = module

type PointUiModule = typeof(self)

local MAX_SIZE = UDim2.fromScale(
	0.05,
	0.101
)

local CENTER = Vector2.new(0.5, 0.5)

local function isGamepadInput(InputType: Enum.UserInputType): boolean
	return InputType == Enum.UserInputType.Gamepad1
		or InputType == Enum.UserInputType.Gamepad2
		or InputType == Enum.UserInputType.Gamepad3
		or InputType == Enum.UserInputType.Gamepad4
end

local function isGamepadActive(): boolean
	return isGamepadInput(
		UserInputService:GetLastInputType()
	)
end

local function getPointScale(): UIScale
	local scale = ImageLabel:FindFirstChildOfClass("UIScale")

	if not scale then
		scale = Instance.new("UIScale")
		scale.Scale = 1
		scale.Parent = ImageLabel
	end

	return scale
end

local function getGuiSize(): Vector2
	local size = PointUi.AbsoluteSize

	if size.X <= 0 or size.Y <= 0 then
		local camera = workspace.CurrentCamera

		if camera then
			size = camera.ViewportSize
		end
	end

	return size
end

local function getPointSize(): Vector2
	local guiSize = getGuiSize()

	return Vector2.new(
		guiSize.X * MAX_SIZE.X.Scale,
		guiSize.Y * MAX_SIZE.Y.Scale
	)
end

local function getTargetPosition(Frame: GuiObject): Vector2
	return Frame.AbsolutePosition - PointUi.AbsolutePosition
end

local function getBestPosition(Frame: GuiObject): Vector2?
	local screenSize = getGuiSize()

	if screenSize.X <= 0 or screenSize.Y <= 0 then
		return
	end

	local targetPosition = getTargetPosition(Frame)
	local targetSize = Frame.AbsoluteSize

	local pointSize = getPointSize()
	local halfPointSize = pointSize * 0.5

	local minX = targetPosition.X + halfPointSize.X
	local maxX = targetPosition.X + targetSize.X - halfPointSize.X

	local minY = targetPosition.Y + halfPointSize.Y
	local maxY = targetPosition.Y + targetSize.Y - halfPointSize.Y

	local x
	local y

	if minX > maxX then
		x = targetPosition.X + targetSize.X * 0.5
	else
		x = math.clamp(
			targetPosition.X
				+ targetSize.X
			- halfPointSize.X
			- 4,
			minX,
			maxX
		)
	end

	if minY > maxY then
		y = targetPosition.Y + targetSize.Y * 0.5
	else
		y = math.clamp(
			targetPosition.Y + targetSize.Y * 0.5,
			minY,
			maxY
		)
	end

	return Vector2.new(x, y)
end

local function getRelativePosition(
	screenPosition: Vector2
): Vector2?

	local guiSize = getGuiSize()

	if guiSize.X <= 0 or guiSize.Y <= 0 then
		return
	end

	return Vector2.new(
		screenPosition.X / guiSize.X,
		screenPosition.Y / guiSize.Y
	)
end

local clickCon

local function selectButton(Button: GuiButton)
	if not Button or not Button.Parent then
		return
	end

	if not isGamepadActive() then
		return
	end

	Button.Selectable = true
	GuiService.SelectedObject = Button

	if clickCon then
		clickCon:Disconnect()
		clickCon = nil
	end

	-- End the selection when the button is clicked.
	clickCon = Button.Activated:Once(function()
		Button.Selectable = false

		if GuiService.SelectedObject == Button then
			GuiService.SelectedObject = nil
		end

		-- Stop lockSelection() from selecting it again.
		if self.selectedButton == Button then
			self.selectedButton = nil
		end

		self.selectionLocked = false

		clickCon = nil
	end)
end

local function clearSelectedButton(Button: GuiButton?)
	if not Button then
		return
	end

	if GuiService.SelectedObject == Button then
		GuiService.SelectedObject = nil
	end
end

local function lockSelection(self: PointUiModule)
	if not self.selectionLocked then
		return
	end

	-- Gamepad is no longer the active input.
	if not isGamepadActive() then
		self.selectionLocked = false

		clearSelectedButton(self.selectedButton)
		self.selectedButton = nil

		return
	end

	local Button = self.selectedButton

	if not Button then
		self.selectionLocked = false
		return
	end

	if not Button.Parent then
		self.selectionLocked = false
		self.selectedButton = nil
		return
	end

	-- Force the selection back to the tutorial target.
	if GuiService.SelectedObject ~= Button then
		GuiService.SelectedObject = Button
	end
end

function self.init()
	self.scale = getPointScale()

	self.positionSpring = Spring.new(
		CENTER,
		0.85,
		12
	)

	self.popSpring = Spring.new(
		0.05,
		0.75,
		14
	)

	self.rotationSpring = Spring.new(
		-120,
		0.8,
		10
	)

	self.pulseSpring = Spring.new(
		1,
		0.45,
		18
	)

	self.targetFrame = nil
	self.selectedButton = nil

	self.selectionLocked = false

	self.updateConnection = nil
	self.hideConnection = nil
	self.inputConnection = nil

	self.pulseTimer = 0

	self.initialized = true

	-- Watch for the player changing input type.
	self.inputConnection = UserInputService.LastInputTypeChanged:Connect(
		function(InputType)
			if isGamepadInput(InputType) then
				-- Controller became the active input.

				if self.targetFrame
					and self.targetFrame:IsA("GuiButton")
					and self.targetFrame.Parent
					and self.frame
					and self.frame.Visible
				then
					self.targetFrame.Selectable = true

					self.selectedButton = self.targetFrame
					self.selectionLocked = true

					GuiService.SelectedObject =
						self.targetFrame
				end

				return
			end

			-- Mouse / keyboard / touch became active.
			-- Release tutorial GUI focus immediately.

			self.selectionLocked = false

			clearSelectedButton(
				self.selectedButton
			)

			self.selectedButton = nil
		end
	)
end

function self.setUp()
	if not self.initialized then
		self.init()
	end

	self.frame = ImageLabel

	self.frame.AnchorPoint = Vector2.new(
		0.5,
		0.5
	)

	self.frame.Size = MAX_SIZE
	self.frame.Visible = false

	self.scale.Scale = 1

	self.positionSpring.Position = CENTER
	self.positionSpring.Target = CENTER

	self.popSpring.Position = 0.05
	self.popSpring.Target = 0.05

	self.rotationSpring.Position = -120
	self.rotationSpring.Target = -120

	self.pulseSpring.Position = 1
	self.pulseSpring.Target = 1
end

local function update(
	self: PointUiModule,
	dt: number
)
	if not self.frame then
		return
	end

	if self.targetFrame
		and self.targetFrame.Parent
	then
		local bestPosition = getBestPosition(
			self.targetFrame
		)

		if bestPosition then
			local targetPosition =
				getRelativePosition(bestPosition)

			if targetPosition then
				self.positionSpring.Target =
					targetPosition
			end
		end
	end

	-- Only lock GUI focus while Gamepad is
	-- the currently active input type.
	lockSelection(self)

	self.frame.Position = UDim2.fromScale(
		self.positionSpring.Position.X,
		self.positionSpring.Position.Y
	)

	self.frame.Rotation =
		self.rotationSpring.Position

	self.pulseTimer += dt

	if self.pulseTimer >= 1.1 then
		self.pulseTimer = 0

		self.pulseSpring.Position = 0.78
		self.pulseSpring.Target = 1
	end

	self.scale.Scale =
		self.popSpring.Position
		* self.pulseSpring.Position
end

function self.show()
	if not self.initialized then
		self.init()
	end

	if not self.frame then
		self.setUp()
	end

	if self.updateConnection then
		self.updateConnection:Disconnect()
		self.updateConnection = nil
	end

	if self.hideConnection then
		self.hideConnection:Disconnect()
		self.hideConnection = nil
	end

	self.targetFrame = nil

	self.positionSpring.Position = CENTER
	self.positionSpring.Target = CENTER

	self.popSpring.Position = 0.05
	self.popSpring.Target = 1

	self.rotationSpring.Position = -120
	self.rotationSpring.Target = 0

	self.pulseSpring.Position = 0.75
	self.pulseSpring.Target = 1

	self.pulseTimer = 0

	self.frame.Size = MAX_SIZE
	self.frame.AnchorPoint = Vector2.new(
		0.5,
		0.5
	)

	self.frame.Visible = true

	self.updateConnection = RunService.Heartbeat:Connect(
		function(dt)
			update(self, dt)
		end
	)
end

function self.MoveTo(Frame: GuiObject)
	if not Frame or not Frame:IsA("GuiObject") then
		return
	end

	if not self.initialized then
		self.init()
	end

	if not self.frame then
		self.setUp()
	end

	if not self.frame.Visible then
		self.show()
	end

	-- Remove the previous tutorial selection.
	if self.selectedButton
		and self.selectedButton ~= Frame
	then
		clearSelectedButton(
			self.selectedButton
		)

		self.selectedButton = nil
	end

	self.targetFrame = Frame

	-- Only take GUI focus if Gamepad is
	-- currently being used.
	if Frame:IsA("GuiButton")
		and isGamepadActive()
	then
		Frame.Selectable = true

		self.selectedButton = Frame
		self.selectionLocked = true

		selectButton(Frame)
	else
		self.selectedButton = nil
		self.selectionLocked = false
	end

	local bestPosition = getBestPosition(Frame)

	if bestPosition then
		local targetPosition =
			getRelativePosition(bestPosition)

		if targetPosition then
			self.positionSpring.Target =
				targetPosition
		end
	end

	self.rotationSpring:Impulse(
		math.random(-6, 6)
	)

	self.pulseSpring.Position = 0.78
	self.pulseSpring.Target = 1

	self.pulseTimer = 0
end

function self.Hide()
	if not self.frame then
		return
	end

	if not self.frame.Visible then
		return
	end

	if self.hideConnection then
		self.hideConnection:Disconnect()
		self.hideConnection = nil
	end

	self.targetFrame = nil

	-- Completely release controller focus.
	self.selectionLocked = false

	clearSelectedButton(
		self.selectedButton
	)

	self.selectedButton = nil

	self.popSpring.Target = 0.05

	self.rotationSpring.Target =
		self.rotationSpring.Position + 90

	self.hideConnection = RunService.Heartbeat:Connect(
		function()
			if not self.frame then
				return
			end

			if self.popSpring.Position <= 0.08 then
				self.hideConnection:Disconnect()
				self.hideConnection = nil

				self.frame.Visible = false

				self.popSpring.Position = 0.05
				self.popSpring.Target = 0.05

				self.rotationSpring.Position = -120
				self.rotationSpring.Target = -120

				self.positionSpring.Position = CENTER
				self.positionSpring.Target = CENTER

				self.pulseSpring.Position = 1
				self.pulseSpring.Target = 1

				self.pulseTimer = 0
			end
		end
	)
end

return module
