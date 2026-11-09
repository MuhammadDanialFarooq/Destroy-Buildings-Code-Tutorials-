local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local UiTutorial = require(script.Parent.Ui)
local TrailCreator = require(script.Parent.Trail)

local Player = game.Players.LocalPlayer
local PlayerGui = Player.PlayerGui

local HUD = PlayerGui.HUD
local ItemShop = HUD.Frames.ItemShop
local Top = HUD.HUD.Top

local playerPlot = workspace.Tycoons:WaitForChild(`{Player.Name}'s Plot`)

local pointUi = require(script.Parent.PointUi)

local SFX = require("@game/ReplicatedStorage/Module/Sounds")
local Point = require(script.Parent.Point)

local TutorialUi = require(script.Parent.TutorialPopup)
local Confetti = require("@game/ReplicatedStorage/Module/Ui/Effects/Confetti")

local module = {}

local function MoveToWithText(Frame, Text)
	UiTutorial:moveToFrame(Frame)
	UiTutorial:displayText(Text)
end

local function WaitForCharacterChild(Name)
	local Character = Player.Character or Player.CharacterAdded:Wait()

	return Character:WaitForChild(Name)
end

local function LogFunnelStep(step)
	ReplicatedStorage.Remotes.TutorialFunnel:FireServer(step)
end

local function WaitForPlacement(Name, CustomDir, RequiredCount)
	local Container = if CustomDir
		then playerPlot.PlotTest.Placed:FindFirstChild(CustomDir)
		else nil

	if not Container then
		warn("Not a valid Container = ", CustomDir)
		return
	end

	RequiredCount = (if RequiredCount then RequiredCount else 1)

	local function GetPlacedCount()
		local Count = 0

		for _, Child in Container:GetChildren() do
			if Child.Name == Name and not Child:HasTag("Placing") then
				Count += 1
			end
		end

		return Count
	end

	if GetPlacedCount() >= RequiredCount then
		return
	end

	while task.wait() do
		if GetPlacedCount() >= RequiredCount then
			return
		end
	end
end
local function pulseTheModel(Model: string, show)
	if playerPlot
		and playerPlot:FindFirstChild("TutorialModel")
		and playerPlot.TutorialModel:FindFirstChild(Model)
		and playerPlot.TutorialModel[Model]:FindFirstChild("Visual")
	then


		for _,ModelGot in playerPlot.TutorialModel:GetChildren() do
			if ModelGot:IsA("Model") and ModelGot.Name == Model then
				if show then
					for _, v in ModelGot:GetDescendants() do
						if v:IsA("BasePart")
							and (v ~= ModelGot.Visual.PrimaryPart and v ~= ModelGot.PrimaryPart)
						then
							v.Transparency = 0.5

						elseif v:IsA("SelectionBox") then
							v.Visible = true
						end
					end
					Point:Show()
					Point:MoveTo(ModelGot.Visual.PrimaryPart)
				else
					Point:Hide()
					for _, v in ModelGot.Visual:GetDescendants() do
						if v:IsA("BasePart")
							and (v ~= ModelGot.Visual.PrimaryPart and v ~= ModelGot.PrimaryPart)
						then
							v.Material = Enum.Material.SmoothPlastic
							v.Transparency = 1

						elseif v:IsA("SelectionBox") then
							v.Visible = false
						end
					end
				end
			end
		end
	end
end

local function GetPlotBase()
	-- If PlotTest itself is a BasePart, use it.
	if playerPlot.PlotTest:IsA("BasePart") then
		return playerPlot.PlotTest
	end

	-- Otherwise try common plot floor/base names.
	local PlotBase =
		playerPlot.PlotTest:FindFirstChild("Base")
		or playerPlot.PlotTest:FindFirstChild("PlotBase")
		or playerPlot.PlotTest:FindFirstChild("Floor")
		or playerPlot.PlotTest:FindFirstChild("Ground")
		or playerPlot:FindFirstChild("Base")
		or playerPlot:FindFirstChild("PlotBase")
		or playerPlot:FindFirstChild("Floor")
		or playerPlot:FindFirstChild("Ground")

	if PlotBase and PlotBase:IsA("BasePart") then
		return PlotBase
	end

	-- Last fallback: use PrimaryPart if the plot is a Model.
	if playerPlot:IsA("Model") and playerPlot.PrimaryPart then
		return playerPlot.PrimaryPart
	end

	return nil
end

local function IsPlayerInsidePlot(HumanoidRootPart)
	local PlotBase = GetPlotBase()

	if not PlotBase then
		return false
	end

	local LocalPosition = PlotBase.CFrame:PointToObjectSpace(
		HumanoidRootPart.Position
	)

	local HalfSize = PlotBase.Size * 0.5

	-- Slight Y tolerance so small height differences don't matter.
	local InsideX = math.abs(LocalPosition.X) <= HalfSize.X
	local InsideZ = math.abs(LocalPosition.Z) <= HalfSize.Z
	local InsideY = math.abs(LocalPosition.Y) <= HalfSize.Y + 10

	return InsideX and InsideZ and InsideY
end

local function GetBackpackToolFrame(ToolName)
	local Backpack = Player.PlayerGui:FindFirstChild("BackpackGui")
	if not Backpack then
		return nil
	end
	local BackpackFrame = Backpack:FindFirstChild("Backpack")
	if not BackpackFrame then
		return nil
	end
	local selected
	for i,v in BackpackFrame:FindFirstChild("Hotbar"):GetChildren() do
		if v:FindFirstChild("ToolName") and v.ToolName.Text == ToolName then
			selected = v
			break
		end
	end
	return selected
end

local function checkPlaced(Name,CustomDir,Count)
	local Container = if CustomDir
		then playerPlot.PlotTest.Placed:FindFirstChild(CustomDir)
		else nil

	if not Container then
		warn("Not a valid Container = ", CustomDir)
		return
	end

	Count = (if Count then Count else 1)

	local function GetPlacedCount()
		local Count = 0

		for _, Child in Container:GetChildren() do
			if Child.Name == Name and not Child:HasTag("Placing") then
				Count += 1
			end
		end

		return Count
	end

	if GetPlacedCount() >= Count then
		return true
	end
	return false
end

function module.Start()
	Player:SetAttribute("InTutorial", true)

	Top.Buy.Visible = false
	Top.MyPlot.Visible = true
	Top.Sell.Visible = false
	PlayerGui:WaitForChild("BackpackGui").Enabled = false
	TutorialUi.Show()

	TutorialUi.UpdateText("Welcome, Chief! We need SCRAPS!",true)
	TutorialUi.UpdateText("But first, we need some Buildings!",true)
	--TutorialUi.UpdateText("Buildings will help us collect the SCRAPS we need.",true)
	--pointUi:show()

	Player:SetAttribute("DisablePlacementTutorial",false)



	--pointUi.MoveTo(Top.MyPlot)

	--UiTutorial:show()

	--Point:Show()
	--Point:MoveTo(playerPlot.PlotTest)

	--MoveToWithText(
	--	Top.MyPlot.Main,
	--	"go to your plot"
	--)
	--TutorialUi.UpdateText("Let's get started, Go to your plot!")


	local Character = Player.Character or Player.CharacterAdded:Wait()
	local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")

	-- The tutorial can continue in two ways:
	-- 1. Player clicks MyPlot.
	-- 2. Player physically walks into their plot.

	--local ReachedPlot = false

	--local ButtonConnection = Top.MyPlot.Activated:Connect(function()
	--	ReachedPlot = true
	--end)

	--local PlotConnection = RunService.Heartbeat:Connect(function()
	--	if not HumanoidRootPart.Parent then
	--		return
	--	end

	--	if IsPlayerInsidePlot(HumanoidRootPart) then
	--		ReachedPlot = true
	--	end
	--end)

	--while not ReachedPlot do
	--	task.wait()
	--end

	--ButtonConnection:Disconnect()
	--PlotConnection:Disconnect()
	--Point:Hide()

	--UiTutorial:hide()

	local ExistingTent = checkPlaced("Tent","Breakables",1)--playerPlot.PlotTest.Placed.Breakables:FindFirstChild("Tent")

	if not ExistingTent then

		--TutorialUi.UpdateText("Every plot needs a place to start!",true)
		TutorialUi.UpdateText("Equip the Tent to build it!")
		PlayerGui:WaitForChild("BackpackGui").Enabled = true
		UiTutorial:show()
		MoveToWithText(GetBackpackToolFrame("Tent")
			,
			""
		)

		pointUi.MoveTo(GetBackpackToolFrame("Tent"))

		WaitForCharacterChild("Tent")
		pointUi:Hide()
		UiTutorial:hide()
		local trail = TrailCreator.createbeam(
			HumanoidRootPart,
			playerPlot.TutorialAttachments.Tent
		)

		TutorialUi.UpdateText("Great! Now place your Tent.")



		pulseTheModel("Tent", true)
		WaitForPlacement("Tent", "Breakables")
		
		PlayerGui:WaitForChild("BackpackGui").Enabled = false

		LogFunnelStep(2)
		
		if trail then
			trail:Destroy()
		end
		
		pulseTheModel("Tent", nil)
		SFX.PlayCloneSFX("Thinking")
		TutorialUi.UpdateText("Nice! We've got our first building.",true)
		


	else
		LogFunnelStep(2)
	end

	local ExistingSlingshot = checkPlaced("NoobSlingshot","Bombers",2)

	if not ExistingSlingshot then

		TutorialUi.UpdateText("But we still need a way to earn scraps!",true)

		TutorialUi.UpdateText("Let's build a Slingshotter!",true)
		PlayerGui:WaitForChild("BackpackGui").Enabled = true

		UiTutorial:show()
		pointUi:show()
		if GetBackpackToolFrame("NoobSlingshot") then
			MoveToWithText(GetBackpackToolFrame("NoobSlingshot")
				,
				""
			)
		end

		pointUi.MoveTo(GetBackpackToolFrame("NoobSlingshot"))

		TutorialUi.UpdateText("Equip the Slingshotter!")
		WaitForCharacterChild("NoobSlingshot")
		TutorialUi.UpdateText("Now place your Slingshotter!")
		UiTutorial:hide()
		pointUi:Hide()

		local trail = TrailCreator.createbeam(
			HumanoidRootPart,
			playerPlot.TutorialAttachments.Slingshotter
		)

		UiTutorial:displayText(
			""
		)

		pulseTheModel("NoobSlingshot", true)
		WaitForPlacement("NoobSlingshot", "Bombers", 1)
		PlayerGui:WaitForChild("BackpackGui").Enabled = false

		LogFunnelStep(3)

		pulseTheModel("NoobSlingshot", nil)

		if trail then
			trail:Destroy()
		end
	else
		LogFunnelStep(3)
	end

	UiTutorial:hide()
	pointUi:Hide()
	Confetti:ShowBottomConfetti(2,60)
	SFX.PlayCloneSFX("Wooooo")
	TutorialUi.UpdateText("Excellent! Your plot is taking shape!",true)


	task.wait(.25)

	return "Finished"
end

return module
