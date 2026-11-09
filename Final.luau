local Confetti = require("@game/ReplicatedStorage/Module/Ui/Effects/Confetti")
local UiTutorial = require(script.Parent.Ui)
local TutorialPopup = require(script.Parent.TutorialPopup)

local Player = game.Players.LocalPlayer
local PlayerGui = Player.PlayerGui

local module = {}

local function LogFunnelStep(step)
	game.ReplicatedStorage.Remotes.TutorialFunnel:FireServer(step)
end

function module.Start()
	Player:SetAttribute("InTutorial", true)

	Confetti:ShowBottomConfetti(2, 60)
	TutorialPopup.Show()

	TutorialPopup.UpdateText("Tutorial Completed!", true)

	TutorialPopup.UpdateText("Great job, Chief!", true)

	TutorialPopup.UpdateText(
		"Now head back to your plot and start collecting SCRAPS!",
		true
	)

	TutorialPopup.UpdateText(
		"Build, defend, and cause some chaos!",
		true
	)
	
	TutorialPopup.Hide()

	LogFunnelStep(11)

	Player:SetAttribute("InTutorial", false)
	PlayerGui:WaitForChild("BackpackGui").Enabled = true

	UiTutorial:displayText("")

	return true
end

return module