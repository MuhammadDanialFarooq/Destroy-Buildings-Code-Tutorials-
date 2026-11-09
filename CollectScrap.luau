local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Player = Players.LocalPlayer
local PlayerGui = Player.PlayerGui

local playerPlot = workspace.Tycoons:WaitForChild(`{Player.Name}'s Plot`)
local PlrDataR = ReplicatedStorage.Remotes.UpdateData
local PlayerData

local HUD = PlayerGui.HUD
local SellUi = HUD.Frames.Sell
local Top = HUD.HUD.Top

local UiTutorial = require(script.Parent.Ui)
local PointUi = require(script.Parent.PointUi)
local TrailCreator = require(script.Parent.Trail)
local Point = require(script.Parent.Point)

local SellScraps = workspace.Map.Triggers.Ui.Sell

local module = {}

local function LogFunnelStep(step)
	ReplicatedStorage.Remotes.TutorialFunnel:FireServer(step)
end

local function GetBestBomber()
	local bombers = playerPlot.PlotTest.Placed.Bombers

	local bestBomber = nil
	local bestScraps = -math.huge

	for _, bomber in bombers:GetChildren() do
		local scraps = bomber:GetAttribute("ScrapsCollected")

		if typeof(scraps) == "number" and scraps > bestScraps then
			bestScraps = scraps
			bestBomber = bomber
		end
	end

	return bestBomber
end

local function WaitForScrapAmount(Amount)
	local Connection

	Connection = PlrDataR.OnClientEvent:Connect(function(data)
		PlayerData = data

		UiTutorial:displayText(`Get {PlayerData.Scrap}/{Amount} Scraps`)

		if PlayerData.Scrap >= Amount then
			Connection:Disconnect()
		end
	end)

	while Connection.Connected do
		task.wait()
	end
end

local function MoveToWithText(Frame, Text)
	UiTutorial:moveToFrame(Frame)
	UiTutorial:displayText(Text)
end

local function WaitForClose()

	local closed = false

	local con = SellUi.Main.Close.Activated:Connect(function()

		closed = true

	end)

	while SellUi.Visible == true and closed == false do
		task.wait()
	end
	con:Disconnect()
	con = nil
	closed = nil

end

local function FollowBestBomber()
	local Bombers = playerPlot.PlotTest.Placed.Bombers

	local CurrentBomber = GetBestBomber()
	local Trail = nil

	local Connections = {}

	local function UpdateTarget()
		local BestBomber = GetBestBomber()

		if not BestBomber then
			return
		end

		if BestBomber == CurrentBomber then
			return
		end

		CurrentBomber = BestBomber

		if Trail then
			Trail:Destroy()
			Trail = nil
		end

		local PrimaryPart = CurrentBomber.PrimaryPart

		if PrimaryPart then
			Trail = TrailCreator.createbeam(
				Player.Character,
				PrimaryPart
			)

			Point:MoveTo(PrimaryPart)
		end
	end

	local function WatchBomber(Bomber)
		local Connection = Bomber:GetAttributeChangedSignal("ScrapsCollected"):Connect(UpdateTarget)
		table.insert(Connections, Connection)
	end

	for _, Bomber in Bombers:GetChildren() do
		WatchBomber(Bomber)
	end

	table.insert(
		Connections,
		Bombers.ChildAdded:Connect(function(Bomber)
			WatchBomber(Bomber)
			UpdateTarget()
		end)
	)

	table.insert(
		Connections,
		Bombers.ChildRemoved:Connect(function(Bomber)
			if Bomber == CurrentBomber then
				CurrentBomber = nil
				UpdateTarget()
			end
		end)
	)

	if CurrentBomber and CurrentBomber.PrimaryPart then
		Trail = TrailCreator.createbeam(
			Player.Character,
			CurrentBomber.PrimaryPart
		)

		Point:MoveTo(CurrentBomber.PrimaryPart)
	end

	return function()
		for _, Connection in Connections do
			Connection:Disconnect()
		end

		if Trail then
			Trail:Destroy()
			Trail = nil
		end
	end
end

function module.Start()
	Player:SetAttribute("InTutorial", true)

	Top.Buy.Visible = false
	Top.MyPlot.Visible = false
	Top.Sell.Visible = false
	PlayerGui:WaitForChild("BackpackGui").Enabled = false

	UiTutorial:displayText("Get 0/25 Scraps")

	Point:Show()

	-- Follow the NoobSlingshot that currently has the most ScrapsCollected
	local StopFollowingBomber = FollowBestBomber()

	WaitForScrapAmount(25)

	StopFollowingBomber()

	Point:Hide()

	LogFunnelStep(8)

	Top.Buy.Visible = false
	Top.MyPlot.Visible = false
	Top.Sell.Visible = true

	--UiTutorial:show()
	PointUi.show()
	--MoveToWithText(Top.Sell, "Click on Sell")
	PointUi.MoveTo(Top.Sell)
	--Top.Sell.Activated:Wait()

	--UiTutorial:hide()

	UiTutorial:displayText("Go to Sell Scraps")

	local Trail = TrailCreator.createbeam(
		Player.Character.HumanoidRootPart,
		SellScraps
	)

	repeat
		SellUi:GetPropertyChangedSignal("Visible"):Wait()
	until SellUi.Visible
	PointUi.Hide()
	LogFunnelStep(9)

	PointUi.show()

	Trail:Destroy()

	UiTutorial:displayText("Click on Sell")

	PointUi.MoveTo(SellUi.Main.SellScraps)

	SellUi.Main.SellScraps.Activated:Wait()

	LogFunnelStep(10)



	UiTutorial:show()

	MoveToWithText(
		SellUi.Main.Close,
		"Close the Ui"
	)
	PointUi.MoveTo(SellUi.Main.Close)
	WaitForClose()

	UiTutorial:hide()

	PointUi.Hide()

	Top.Buy.Visible = true
	Top.MyPlot.Visible = true
	Top.Sell.Visible = true
	PlayerGui:WaitForChild("BackpackGui").Enabled = true
	task.wait(0.5)

	return true
end

return module