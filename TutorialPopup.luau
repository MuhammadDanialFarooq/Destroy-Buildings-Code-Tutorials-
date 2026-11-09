local module = {}

local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")

local Sfx = require("@game/ReplicatedStorage/Module/Sounds")

local TutorialPopup = Players.LocalPlayer
	:WaitForChild("PlayerGui")
	:WaitForChild("Tutorial")
	:WaitForChild("TutorialFrame")

local Spring = require("@game/ReplicatedStorage/Module/Ui/SpringUI")

local Positions = {
	Show = UDim2.fromScale(0.5, 0.68),
	Hide = UDim2.fromScale(0.5, 1.5),
}

local UpdateId = 0

Spring.Add("Tutorial", TutorialPopup, Positions.Hide)

function module.Show()
	Spring.Move("Tutorial", Positions.Show)
end

function module.UpdateText(Text: string, WaitForCompletion: boolean?)
	UpdateId += 1

	local CurrentId = UpdateId

	if not WaitForCompletion then
		task.spawn(function()
			local TextLabel = TutorialPopup.Items.TextLabel

			TextLabel.Text = Text
			TextLabel.MaxVisibleGraphemes = 0

			local Skipped = false

			local Connection = UserInputService.InputBegan:Connect(function(Input, GameProcessed)
				if GameProcessed or CurrentId ~= UpdateId then
					return
				end

				if Input.KeyCode == Enum.KeyCode.Space
					or Input.KeyCode == Enum.KeyCode.ButtonX
					or Input.UserInputType == Enum.UserInputType.MouseButton1
					or Input.UserInputType == Enum.UserInputType.Touch
					or Input.UserInputType == Enum.UserInputType.Gamepad1 then

					Skipped = true
				end
			end)

			for i = 1, Text:len() do
				if Skipped or CurrentId ~= UpdateId then
					break
				end
				Sfx.PlayCloneSFX("TalkTutorial")
				TextLabel.MaxVisibleGraphemes = i
				task.wait(0.035)
			end

			if CurrentId ~= UpdateId then
				Connection:Disconnect()
				return
			end

			if Skipped then
				TextLabel.MaxVisibleGraphemes = -1
			end

			Connection:Disconnect()
		end)

		return
	end

	local TextLabel = TutorialPopup.Items.TextLabel

	TextLabel.Text = Text
	TextLabel.MaxVisibleGraphemes = 0

	local SkipTyping = false
	local SkipWait = false

	-- First input: skip the typewriter
	local TypingConnection = UserInputService.InputBegan:Connect(function(Input, GameProcessed)
		if GameProcessed or CurrentId ~= UpdateId then
			return
		end

		if Input.KeyCode == Enum.KeyCode.Space
			or Input.KeyCode == Enum.KeyCode.ButtonX
			or Input.UserInputType == Enum.UserInputType.MouseButton1
			or Input.UserInputType == Enum.UserInputType.Touch
			or Input.UserInputType == Enum.UserInputType.Gamepad1 then

			SkipTyping = true
		end
	end)

	-- Typewriter
	for i = 1, Text:len() do
		if SkipTyping or CurrentId ~= UpdateId then
			break
		end
		Sfx.PlayCloneSFX("TalkTutorial")
		TextLabel.MaxVisibleGraphemes = i
		task.wait(0.035)
	end

	if CurrentId ~= UpdateId then
		TypingConnection:Disconnect()
		return
	end

	-- Make sure the full text is visible
	TextLabel.MaxVisibleGraphemes = -1
	TypingConnection:Disconnect()

	-- Wait another 3 seconds.
	-- This has its OWN skip.
	local WaitConnection = UserInputService.InputBegan:Connect(function(Input, GameProcessed)
		if GameProcessed or CurrentId ~= UpdateId then
			return
		end

		if Input.KeyCode == Enum.KeyCode.Space
			or Input.KeyCode == Enum.KeyCode.ButtonX
			or Input.UserInputType == Enum.UserInputType.MouseButton1
			or Input.UserInputType == Enum.UserInputType.Touch
			or Input.UserInputType == Enum.UserInputType.Gamepad1 then

			SkipWait = true
		end
	end)

	local StartTime = os.clock()

	while os.clock() - StartTime < 3 do
		if SkipWait or CurrentId ~= UpdateId then
			break
		end

		task.wait()
	end

	WaitConnection:Disconnect()
end

function module.Hide()
	UpdateId += 1
	Spring.Move("Tutorial", Positions.Hide)
end

return module