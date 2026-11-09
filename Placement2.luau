local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local UiTutorial = require(script.Parent.Ui)
local TrailCreator = require(script.Parent.Trail)

local Player = game.Players.LocalPlayer
local PlayerGui = Player.PlayerGui

local HUD = PlayerGui.HUD
local ItemShop = HUD.Frames.ItemShop
local Top = HUD.HUD.Top

local TutorialUi = require(script.Parent.TutorialPopup)
local playerPlot = workspace.Tycoons:WaitForChild(`{Player.Name}'s Plot`)
local sfx = require("@game/ReplicatedStorage/Module/Sounds")

local pointUi = require(script.Parent.PointUi)
local Point = require(script.Parent.Point)

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

	RequiredCount = if RequiredCount then RequiredCount else 1

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
		for _, ModelGot in playerPlot.TutorialModel:GetChildren() do
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
	if playerPlot.PlotTest:IsA("BasePart") then
		return playerPlot.PlotTest
	end

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

	for i, v in BackpackFrame:FindFirstChild("Hotbar"):GetChildren() do
		if v:FindFirstChild("ToolName") and v.ToolName.Text == ToolName then
			selected = v
			break
		end
	end

	return selected
end

local function checkPlaced(Name, CustomDir, Count)
	local Container = if CustomDir
		then playerPlot.PlotTest.Placed:FindFirstChild(CustomDir)
		else nil

	if not Container then
		warn("Not a valid Container = ", CustomDir)
		return
	end

	Count = if Count then Count else 1

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

	UiTutorial:hide()
	task.wait(0.5)


	Player:SetAttribute("DisablePlacementTutorial", false)

	Top.Buy.Visible = false
	Top.MyPlot.Visible = true
	Top.Sell.Visible = false
	PlayerGui:WaitForChild("BackpackGui").Enabled = false
	
	sfx.PlayCloneSFX("EvilLaugh")
	TutorialUi.UpdateText("Now let's put that firepower to work!", true)
	
	pointUi:show()

	pointUi.MoveTo(Top.MyPlot)

	Point:Show()
	Point:MoveTo(playerPlot.PlotTest)

	TutorialUi.Show()
	
	TutorialUi.UpdateText("Head over to your plot!")

	local Character = Player.Character or Player.CharacterAdded:Wait()
	local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")

	local ReachedPlot = false

	local ButtonConnection = Top.MyPlot.Activated:Connect(function()
		ReachedPlot = true
	end)

	local PlotConnection = RunService.Heartbeat:Connect(function()
		if not HumanoidRootPart.Parent then
			return
		end

		if IsPlayerInsidePlot(HumanoidRootPart) then
			ReachedPlot = true
		end
	end)

	while not ReachedPlot do
		task.wait()
	end

	LogFunnelStep(6)

	ButtonConnection:Disconnect()
	PlotConnection:Disconnect()

	Point:Hide()

	local ExistingSlingshot = checkPlaced("NoobSlingshot", "Bombers", 2)

	if not ExistingSlingshot then
		

		UiTutorial:show()
		pointUi:show()
		PlayerGui:WaitForChild("BackpackGui").Enabled = true
		MoveToWithText(
			GetBackpackToolFrame("NoobSlingshot"),
			""
		)
		TutorialUi.UpdateText("Equip the Slingshotter!")
		pointUi.MoveTo(GetBackpackToolFrame("NoobSlingshot"))

		WaitForCharacterChild("NoobSlingshot")

		UiTutorial:hide()
		pointUi:Hide()

		local trail = TrailCreator.createbeam(
			HumanoidRootPart,
			playerPlot.TutorialAttachments.Slingshotter
		)

		TutorialUi.UpdateText("Place your Slingshotter!")-- Slingshotters on your plot!", true)

		pulseTheModel("NoobSlingshot", true)

		WaitForPlacement("NoobSlingshot", "Bombers", 2)
		PlayerGui:WaitForChild("BackpackGui").Enabled = false

		LogFunnelStep(7)

		pulseTheModel("NoobSlingshot", nil)

		if trail then
			trail:Destroy()
		end
	else
		LogFunnelStep(7)
	end

	TutorialUi.UpdateText("Excellent! You're ready for action!", true)

	UiTutorial:hide()
	TutorialUi.Hide()
	pointUi:Hide()

	task.wait(0.25)

	return "Finished"
end

return module
