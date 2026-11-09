local module = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = ReplicatedStorage:WaitForChild("Remotes")


local Player = Players.LocalPlayer

local tutorialService = require(script.Ui)

local Steps = {
	--"Cutscene",
	"Placement1",
	"BuyBuildings",
	"Placement2",
	"CollectScrap",
--	"UpgradeUi",
	"Final"
}

local PlayerData
local Step

local TutorialRunning
local WaitingForData = false

local function IsEmpty(Table)
	return next(Table) == nil
end

local function LogFunnelStep(step)
	Remotes.TutorialFunnel:FireServer(step)
end

local function StopCurrentTutorial()
	if not TutorialRunning then
		return
	end

	if TutorialRunning.Stop then
		TutorialRunning:Stop()
	end

	TutorialRunning = nil
end

function module.InitModifyUi()
	tutorialService.init()

	tutorialService:setUp(
		Player:WaitForChild("PlayerGui"):WaitForChild("Tutorial"):WaitForChild("ScaleFrame"),
		Player:WaitForChild("PlayerGui"):WaitForChild("Tutorial"):WaitForChild("Info")
	)
end

function module.Run()
	if WaitingForData then
		return
	end
	
	

	WaitingForData = true

	Remotes.UpdateData:FireServer()

	while PlayerData == nil do
		task.wait()
	end

	WaitingForData = false

	local TutorialData = PlayerData.Tutorial
	


	if TutorialData == nil or IsEmpty(TutorialData) then
		Step = Steps[1]
		LogFunnelStep(1)
	elseif TutorialData.Final then
		Step = nil
		
	else
		Step = nil

		for _, TutorialStep in ipairs(Steps) do
			if TutorialData[TutorialStep] ~= true then
				Step = TutorialStep
				break
			end
		end
	end

	if Step == nil then
		StopCurrentTutorial()
		return
	end

	local TutorialModule = script:FindFirstChild(Step)

	if not TutorialModule then
		warn("Tutorial module not found:", Step)
		return
	end

	StopCurrentTutorial()

	local CurrentTutorial = require(TutorialModule)

	TutorialRunning = CurrentTutorial

	if not CurrentTutorial.Start then
		warn("Tutorial module has no Start function:", Step)
		TutorialRunning = nil
		return
	end

	if Player:GetAttribute("LoadingScreen") then
		Player:SetAttribute("InTutorial", true)
		repeat task.wait() until Player:GetAttribute("LoadingScreen") ~= true
	end

	local Finished = CurrentTutorial:Start()

	if TutorialRunning ~= CurrentTutorial then
		return
	end

	if Finished then
		module:ChangeIt(Step)
	end
end

function module:ChangeIt(Step)
	if TutorialRunning and TutorialRunning.Stop then
		TutorialRunning:Stop()
	end

	TutorialRunning = nil

	Remotes.TutorialSetup:InvokeServer(Step)

	task.wait(0.5)

	module.Run()
end

Remotes.UpdateData.OnClientEvent:Connect(function(Data)
	PlayerData = Data
end)

return module