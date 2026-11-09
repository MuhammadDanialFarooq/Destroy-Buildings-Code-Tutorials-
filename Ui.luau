local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local Spring = require(ReplicatedStorage.Module.Libraries.Spring)

local ShowInfo = TweenInfo.new(.8, Enum.EasingStyle.Sine)

local self = {}
type TutorialService = typeof(self)

local function offsetToScale(frame: Frame, offset: UDim2 | Vector2): Vector2?
	if not frame.Parent then
		warn(`Unable to get {frame} offset to scale. Parent is missing.`)
		return
	end

	if typeof(offset) == UDim2 then
		offset = Vector2.new(offset.X.Offset, offset.Y.Offset)
	end

	return offset / frame.Parent.AbsoluteSize
end

function self.init()
	self.positionSpring = Spring.new(Vector2.new(.5, .5), .85, 12)
	self.sizeSpring = Spring.new(Vector2.new(1, 1), .95, 12)
	self.pulseSpring = Spring.new(.1, .4, 13)
end

function self.setUp(self: TutorialService, cutoutFrame: Frame, text: TextLabel)
	self.screenGui = cutoutFrame:FindFirstAncestorWhichIsA("LayerCollector")
	self.frame = cutoutFrame :: Frame
	self.infoText = text :: TextLabel
	self.pulseTime = 0
	
	self.frame.Visible = false
	for _, stroke: UIStroke in self.frame:QueryDescendants("UIStroke") do
		stroke:SetAttribute("Transparency", stroke.Transparency)
		stroke.Transparency = 1
	end
end

function self.show(self: TutorialService)
	self.sizeSpring.Position = Vector2.new(1, 1)
	self.sizeSpring.Target = self.sizeSpring.Position
	
	self.positionSpring.Position = Vector2.new(.5, .5)
	self.positionSpring.Target = self.positionSpring.Position
	
	self.frame.Visible = true
	for _, stroke: UIStroke in self.frame:QueryDescendants("UIStroke") do
		TweenService:Create(stroke, ShowInfo, {Transparency = stroke:GetAttribute("Transparency")}):Play()
	end
	
	self.updateConnection = RunService.Heartbeat:Connect(update)
end

function self.hide(self: TutorialService)
	self.sizeSpring.Target = Vector2.new(1, 1)
	self.positionSpring.Target = Vector2.new(.5, .5)
	for _, stroke: UIStroke in self.frame:QueryDescendants("UIStroke") do
		TweenService:Create(stroke, ShowInfo, {Transparency = 1}):Play()
	end
	
	if self.framePropertyChanged then
		self.framePropertyChanged:Disconnect()
		self.framePropertyChanged = nil
	end

	self.infoText.Visible = false
	task.delay(ShowInfo.Time, function()
		self.frame.Visible = false
		if self.updateConnection then
			self.updateConnection:Disconnect()
			self.updateConnection = nil
		end
	end)
end

function self.moveToFrame(self: TutorialService, frame: GuiBase2d)
	local function updateSpring()
		local framePosition = frame.AbsolutePosition
		local frameSize = frame.AbsoluteSize

		self.positionSpring.Target = offsetToScale(self.frame, framePosition + (frameSize * .5) - self.screenGui.AbsolutePosition)
		self.sizeSpring.Target = offsetToScale(self.frame, frameSize + Vector2.new(5, 5))
	end
	
	if self.framePropertyChanged then
		self.framePropertyChanged:Disconnect()
		self.framePropertyChanged = nil
	end
	
	updateSpring()
	self.framePropertyChanged = frame.Changed:Connect(function(property: string)
		if (property == "AbsolutePosition") or (property == "AbsoluteSize") then
			updateSpring()
		end
	end)
end

function self.displayText(self: TutorialService, text: string)
	self.infoText.MaxVisibleGraphemes = 0
	self.infoText.Text = text
	self.infoText.Visible = true
	
	text = text:gsub("<br%s*/>", "\n")
	text = text:gsub("<[^<>]->", "")
	
	task.spawn(function()
		local index = 0
		for first, last in utf8.graphemes(text) do
			index += 1
			self.infoText.MaxVisibleGraphemes = index
			task.wait(.01)
		end
	end)
end

function update(dt: number)
	if not self.frame then return end

	self.frame.Position = UDim2.fromScale(self.positionSpring.Position.X, self.positionSpring.Position.Y)
	self.frame.Size = UDim2.fromScale(self.sizeSpring.Position.X, self.sizeSpring.Position.Y)
	self.frame.Inner.BorderOffset = UDim.new(self.pulseSpring.Position, 0)
	
	self.pulseTime += dt
	if self.pulseTime < 1.5 then return end
	self.pulseTime = 0
	self.pulseSpring:Impulse(-1.5)
end

return self
