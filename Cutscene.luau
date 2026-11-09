local module = {}

local Camera = workspace.CurrentCamera

local ReplicatedFirst = game:GetService("ReplicatedFirst")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ContentProvider = game:GetService("ContentProvider")

type StateCam = "Cutscene" | "Free"

local Player = Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()

local Cutscene = workspace:WaitForChild("Cutscene")
local CameraRig = Cutscene:WaitForChild("Camera")
local Cam = CameraRig:WaitForChild("Cam")
local Rig = Cutscene:WaitForChild("SlingshotterCutscene")

local PlayerGui = Player:WaitForChild("PlayerGui")
local CutsceneGui = PlayerGui:WaitForChild("Cutscene")
local CutsceneFrame = CutsceneGui:WaitForChild("Frame")

local sfx = require("@game/ReplicatedStorage/Module/Sounds")

local RigHumanoid = Rig:WaitForChild("Humanoid")
local RigAnimator = RigHumanoid:WaitForChild("Animator")

local CameraController = CameraRig:WaitForChild("AnimationController")
local CameraAnimator = CameraController:WaitForChild("Animator")

local Assets = ReplicatedFirst:WaitForChild("Assets")
local CutsceneAssets = Assets:WaitForChild("Cutscene")
local AnimationAssets = Assets:WaitForChild("Animations")

local Animations = {}

local Clipboard
local ClassicSlingshot

local AssetsPreloaded = false
local Preloading = false

local function SetObjectVisible(Object, Visible)
	if not Object then
		return
	end

	for _, Descendant in Object:GetDescendants() do
		if Descendant:IsA("BasePart") then
			if Descendant.Name == "Handle" then
				continue		
			end
			Descendant.Transparency = if Visible then 0 else 1
			Descendant.LocalTransparencyModifier = if Visible then 0 else 1
			


		elseif Descendant:IsA("Decal") or Descendant:IsA("Texture") then
			Descendant.Transparency = if Visible then 0 else 1

		elseif Descendant:IsA("SurfaceGui") then
			Descendant.Enabled = Visible

		elseif Descendant:IsA("BillboardGui") then
			Descendant.Enabled = Visible

		elseif Descendant:IsA("ParticleEmitter") then
			Descendant.Enabled = Visible

		elseif Descendant:IsA("Beam") then
			Descendant.Enabled = Visible

		elseif Descendant:IsA("Trail") then
			Descendant.Enabled = Visible
		end
	end
end


local function PrepareCutsceneAssets()

	if AssetsPreloaded or Preloading then
		return
	end

	Preloading = true

	print("[Cutscene] Preparing assets...")

	local ClipboardTemplate = CutsceneAssets:WaitForChild("Clipboard")
	local SlingshotTemplate = CutsceneAssets:WaitForChild("ClassicSlingshot")

	-- Remove old copies if they somehow exist
	local OldClipboard = Rig:FindFirstChild("Clipboard")
	if OldClipboard then
		OldClipboard:Destroy()
	end

	local OldSlingshot = Rig:FindFirstChild("ClassicSlingshot")
	if OldSlingshot then
		OldSlingshot:Destroy()
	end

	-- Create both objects before the animation starts
	Clipboard = ClipboardTemplate:Clone()
	Clipboard.Name = "Clipboard"
	Clipboard.Parent = Rig

	ClassicSlingshot = SlingshotTemplate:Clone()
	ClassicSlingshot.Name = "ClassicSlingshot"
	ClassicSlingshot.Parent = Rig

	-- Hide them while preparing
	SetObjectVisible(Clipboard, false)
	SetObjectVisible(ClassicSlingshot, false)

	-- Collect everything that may contain renderable/content assets
	local PreloadObjects = {
		Clipboard,
		ClassicSlingshot,
		AnimationAssets:WaitForChild("RigAnimationCutscene"),
		AnimationAssets:WaitForChild("CameraCutscene"),
	}

	-- Also preload anything inside the SurfaceGuis
	for _, Object in Clipboard:GetDescendants() do
		table.insert(PreloadObjects, Object)
	end

	for _, Object in ClassicSlingshot:GetDescendants() do
		table.insert(PreloadObjects, Object)
	end

	print("[Cutscene] Preloading cutscene assets...")

	local Success, ErrorMessage = pcall(function()
		ContentProvider:PreloadAsync(PreloadObjects)
	end)

	if not Success then
		warn("[Cutscene] Preload failed:", ErrorMessage)
	else
		print("[Cutscene] Cutscene assets preloaded")
	end

	AssetsPreloaded = true
	Preloading = false
end


Animations.SlingshotterCutscene = {

	["Event"] = {

		["ShowClipboard"] = function()

			print("[Cutscene] SHOW CLIPBOARD")

			if not Clipboard or not Clipboard.Parent then
				warn("[Cutscene] Clipboard was not prepared")
				return
			end

			if ClassicSlingshot then
				SetObjectVisible(ClassicSlingshot, false)
			end

			SetObjectVisible(Clipboard, true)

			sfx.PlayCloneSFX("Thinking")
		end,


		["PlayScrachSound"] = function()

			print("[Cutscene] PLAY SCRATCH SOUND")

			sfx.PlayCloneSFX("HeadScratch")
		end,


		["ShowSlingshot"] = function()

			print("[Cutscene] SHOW SLINGSHOT")

			if Clipboard then
				SetObjectVisible(Clipboard, false)
			end

			if not ClassicSlingshot or not ClassicSlingshot.Parent then
				warn("[Cutscene] ClassicSlingshot was not prepared")
				return
			end

			SetObjectVisible(ClassicSlingshot, true)
		end,
	},


	["Animation"] = RigAnimator:LoadAnimation(
		AnimationAssets:WaitForChild("RigAnimationCutscene")
	),
}


Animations.Camera = {

	["Event"] = {

		["StartAnimation"] = function()

			print("[Cutscene] START SLINGSHOTTER ANIMATION")

			local Animation = Animations.SlingshotterCutscene.Animation

			if Animation.IsPlaying then
				return
			end

			Animation.Priority = Enum.AnimationPriority.Action
			Animation:Play(0)
		end,


		["ShiverSFX"] = function()

			print("[Cutscene] SHIVER SFX")

			local Tent = Cutscene:FindFirstChild("Tent")

			if Tent then

				local Center = Tent:FindFirstChild("Center")

				if Center then

					local Sweat = Center:FindFirstChild("Sweat")

					if Sweat then

						Sweat.Enabled = true

						task.delay(10, function()

							if Sweat.Parent then
								Sweat.Enabled = false
							end
						end)
					end
				end
			end

			sfx.PlayCloneSFX("ShiverSfx")
		end,


		["StartWalking"] = function()

			print("[Cutscene] START WALKING")

			local Distance = 5
			local Speed = 1.5

			local StartCFrame = Rig:GetPivot()
			local StartPosition = StartCFrame.Position

			local Direction = StartCFrame.LookVector
			local TargetPosition = StartPosition + Direction * Distance

			local Connection

			Connection = RunService.Heartbeat:Connect(function(DeltaTime)

				if not Rig.Parent then
					Connection:Disconnect()
					return
				end

				local CurrentCFrame = Rig:GetPivot()
				local CurrentPosition = CurrentCFrame.Position

				local Remaining = TargetPosition - CurrentPosition
				local RemainingDistance = Remaining.Magnitude

				if RemainingDistance <= 0.01 then

					Rig:PivotTo(
						CFrame.new(TargetPosition) * CurrentCFrame.Rotation
					)

					Connection:Disconnect()

					return
				end

				local MoveDistance = math.min(
					Speed * DeltaTime,
					RemainingDistance
				)

				local NewPosition = CurrentPosition + Direction * MoveDistance

				Rig:PivotTo(
					CFrame.new(NewPosition) * CurrentCFrame.Rotation
				)
			end)
		end,
	},


	["Animation"] = CameraAnimator:LoadAnimation(
		AnimationAssets:WaitForChild("CameraCutscene")
	),
}


local CameraConnection
local Playing = false

local FadeTweenInfo = TweenInfo.new(
	0.5,
	Enum.EasingStyle.Linear,
	Enum.EasingDirection.Out
)


local function ConnectAnimationEvents(AnimationData)

	local Animation = AnimationData.Animation
	local Events = AnimationData.Event

	for EventName, EventFunction in Events do

		print("[Cutscene] Connecting marker:", EventName)

		Animation:GetMarkerReachedSignal(EventName):Connect(function()

			print("[Cutscene] Marker reached:", EventName)

			EventFunction()
		end)
	end
end


local function SwitchCamera(State: StateCam)

	if State == "Cutscene" then

		Camera.CameraType = Enum.CameraType.Scriptable

		RunService:UnbindFromRenderStep("CutsceneCamera")

		RunService:BindToRenderStep(
			"CutsceneCamera",
			Enum.RenderPriority.Camera.Value + 1,
			function()
				Camera.CFrame = Cam.CFrame
			end
		)

		local CameraAnimation = Animations.Camera.Animation

		CameraAnimation.Priority = Enum.AnimationPriority.Action
		CameraAnimation:Play(0)

	elseif State == "Free" then

		RunService:UnbindFromRenderStep("CutsceneCamera")

		CameraConnection = nil

		Camera.CameraType = Enum.CameraType.Custom

		local Humanoid = Character:FindFirstChildOfClass("Humanoid")

		if Humanoid then
			Camera.CameraSubject = Humanoid
		end
	end
end


local function FadeIn()

	CutsceneFrame.Visible = true
	CutsceneFrame.BackgroundTransparency = 1

	local Tween = TweenService:Create(
		CutsceneFrame,
		FadeTweenInfo,
		{
			BackgroundTransparency = 0
		}
	)

	Tween:Play()
	Tween.Completed:Wait()
end


local function FadeOut()

	local Tween = TweenService:Create(
		CutsceneFrame,
		FadeTweenInfo,
		{
			BackgroundTransparency = 1
		}
	)

	Tween:Play()
	Tween.Completed:Wait()

	CutsceneFrame.Visible = false
end


for _, AnimationData in Animations do
	ConnectAnimationEvents(AnimationData)
end


function module.Start()

	if Playing then
		return
	end

	Playing = true

	Player:SetAttribute("InTutorial", true)

	CutsceneFrame.Visible = false
	CutsceneFrame.BackgroundTransparency = 1

	-- Prepare everything BEFORE starting the camera animation
	PrepareCutsceneAssets()

	-- Make sure both are hidden when the cutscene begins
	SetObjectVisible(Clipboard, false)
	SetObjectVisible(ClassicSlingshot, false)

	SwitchCamera("Cutscene")

	Animations.Camera.Animation.Stopped:Wait()

	FadeIn()

	task.wait(3)

	SwitchCamera("Free")

	FadeOut()

	Playing = false

	return "Finished"
end


function module.IsPlaying()

	return Playing
end


return module