local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UiTutorial = require(script.Parent.Ui)
local TrailCreator = require(script.Parent.Trail)

local Player = game.Players.LocalPlayer
local PlayerGui = Player.PlayerGui

local HUD = PlayerGui.HUD
local ItemShop = HUD.Frames.ItemShop
local Top = HUD.HUD.Top

local Point = require(script.Parent.Point)
local PointUi = require(script.Parent.PointUi)
local TutorialUi = require(script.Parent.TutorialPopup)

local PlrDataR = ReplicatedStorage.Remotes.UpdateData
local PlayerData

local BuyButton = Top.Buy

local module = {}

PlrDataR.OnClientEvent:Connect(function(data)
	PlayerData = data
end)

local function LogFunnelStep(step)
	ReplicatedStorage.Remotes.TutorialFunnel:FireServer(step)
end

local function MoveToWithText(Frame, Text)
	UiTutorial:moveToFrame(Frame)
	UiTutorial:displayText(Text)
end

local function HasTool(toolName)
	if not PlayerData then
		PlrDataR:FireServer()
		return false
	end

	for _, data in PlayerData.Tools do
		if data.Name == toolName and data.Left > 0 then
			return true
		end
	end

	return false
end

local function GetToolAmount(toolName)
	if not PlayerData then
		PlrDataR:FireServer()
		return 0
	end

	for _, data in PlayerData.Tools do
		if data.Name == toolName then
			return data.Left or 0
		end
	end

	return 0
end

local function WaitForTool(toolName, requiredAmount)
	requiredAmount = requiredAmount or 1

	if GetToolAmount(toolName) >= requiredAmount then
		return
	end

	local Connection

	Connection = PlrDataR.OnClientEvent:Connect(function(data)
		PlayerData = data
		if requiredAmount >= 2 then
			TutorialUi.UpdateText(`Buy  <font color="#FFD700">{GetToolAmount(toolName)}/2 <b>Slingshotters</b></font>.`)
		end
		if GetToolAmount(toolName) >= requiredAmount then

			Connection:Disconnect()
		end
	end)
	--'Buy  <font color="#FFD700">0/2 <b>Slingshotters</b></font>.'
	while Connection.Connected do
		task.wait()
	end
end

local function WaitForClose()
	local Closed = false
	
	local con = ItemShop.Close.Activated:Connect(function()
		Closed = true
	end)
	while ItemShop.Visible == true and Closed == false do
		task.wait()
	end
	con:Disconnect()
	con = nil
end

local function getItemShopHitbox(FrameType)
	for i , v in  workspace.Map.Triggers.Ui:GetChildren() do
		if v:GetAttribute("FrameType") == FrameType and v.Name == "ItemShop" then
			return v
		end
	end
end

function module.Start()
	Player:SetAttribute("InTutorial", true)
	PlayerGui:WaitForChild("BackpackGui").Enabled = false
	TutorialUi.Show()
	Player:SetAttribute("DisablePlacementTutorial",true)
	
	--TutorialUi.UpdateText('But we need more <font color="#ffd500"><b>FIREPOWER</b></font>!',true) 
	--TutorialUi.UpdateText('Bombers can help you collect more SCRAPS.',true) 
	
	--TutorialUi.UpdateText('Let\'s get some!',true)
	Top.MyPlot.Visible = false
	Top.Sell.Visible = false
	BuyButton.Visible = false
	--UiTutorial:show()
	Top.MyPlot.Visible = false
	Top.Sell.Visible = false
	BuyButton.Visible = true
	PointUi.show()
	MoveToWithText(
		BuyButton,
		''
	)
	PointUi.MoveTo(BuyButton)
	--TutorialUi.UpdateText('Click <font color="#00FFFF"><b>BUY</b></font>.')


	--BuyButton.Activated:Wait()
	--PointUi.Hide()
	--

	--UiTutorial:hide()


	Point:Show()
	Point:MoveTo(getItemShopHitbox("Bombers"))
	
	--UiTutorial:hide()


	TutorialUi.UpdateText('Go to Bombers Shack.')
	

	-- WAIT FOR THE BOMBER SHOP / UI TO OPEN HERE

	-- Example:

	local trail = TrailCreator.createbeam(Player.Character.HumanoidRootPart ,getItemShopHitbox("Bombers"))



	repeat
		ItemShop:GetPropertyChangedSignal("Visible"):Wait()
	until ItemShop.Visible
	LogFunnelStep(4)
	
	if not ItemShop.Items.Bombers.Visible then
		ItemShop.Items.Bombers:GetPropertyChangedSignal("Visible"):Wait()
	end

	Point:Hide()

	ItemShop.Items.Bombers.ScrollingEnabled = false

	if trail then
		trail:Destroy()
	end

	UiTutorial:show()
	PointUi.show()

	MoveToWithText(
		ItemShop.Items.Bombers:WaitForChild("NoobSlingshot"),
		""
	)
	TutorialUi.UpdateText(`Buy a <font color="#FFD700"><b>Slingshotter</b></font>.`)
	PointUi.MoveTo(ItemShop.Items.Bombers:WaitForChild("NoobSlingshot").Buttons.Buy)

	WaitForTool("NoobSlingshot",1)
	ItemShop.Items.Bombers:WaitForChild("NoobSlingshot").Buttons.Buy.Interactable = false
	ItemShop.Items.Bombers:WaitForChild("NoobSlingshot").Buttons.Buy.Active = false -- stop it to be able to be clicked

	LogFunnelStep(5)



	PointUi.MoveTo(ItemShop.Close)

	MoveToWithText(
		ItemShop.Close,
		""
	)

	TutorialUi.UpdateText('Close the shop.')
	WaitForClose()
	
	PointUi.Hide()
	
	
	ItemShop.Items.Bombers:WaitForChild("NoobSlingshot").Buttons.Buy.Interactable = true
	ItemShop.Items.Bombers:WaitForChild("NoobSlingshot").Buttons.Buy.Active = true -- stop it to be able to be clicked
	ItemShop.Items.Bombers.ScrollingEnabled = true
	
	--TutorialUi.UpdateText('Excellent! We\'ve got our firepower!',true)


	-- Once finished:
	UiTutorial:hide()
	BuyButton.Visible = false
	Top.MyPlot.Visible = true
	Top.Sell.Visible = false
	task.wait(.25)
	Player:SetAttribute("DisablePlacementTutorial", false)

	return "Finished"
end

return module