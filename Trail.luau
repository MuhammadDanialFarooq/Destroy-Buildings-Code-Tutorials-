local module = {}

function module.createbeam(Part1 , Part2)
	local beam = Instance.new("Beam")
	
	local att1 = Part1:FindFirstChild("Attachment") or Instance.new("Attachment")
	local att2 = Part2:FindFirstChild("Attachment") or Instance.new("Attachment")
	
	att1.Parent = Part1
	att2.Parent = Part2
	
	beam.Attachment0 = att1
	beam.Attachment1 = att2
	beam.Texture = "rbxassetid://83783269780335"
	beam.TextureMode = Enum.TextureMode.Wrap
	beam.Width0 = 3
	beam.Width1 = 3
	beam.TextureLength = 3
	beam.FaceCamera = true
	beam.Parent = Part1
	return beam
end

return module
