-- 복도 초상화 속 그림을 그려요. (각 플레이어의 화면에서만)
-- 서버가 액자 캔버스(Canvas)에 "어떤 동물 그림인지" 적어 두면, 여기서 그 그림을 캔버스에 붙여요.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Animals = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Animals"))
local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
local rgb = Color3.fromRGB

local folder = Instance.new("Folder")
folder.Name = "Portraits"
folder.Parent = playerGui

local drawn = {} -- [canvas] = SurfaceGui

local function draw(canvas)
	if drawn[canvas] then
		drawn[canvas]:Destroy()
		drawn[canvas] = nil
	end
	if not canvas.Parent or not canvas:GetAttribute("Portrait") then
		return
	end
	local gui = Instance.new("SurfaceGui")
	gui.Name = "PortraitGui"
	gui.Adornee = canvas
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 80
	gui.LightInfluence = 0 -- 어두운 복도에서도 그림이 보여요
	gui.Brightness = 0.9

	local view = Instance.new("ViewportFrame")
	view.Size = UDim2.fromScale(1, 1)
	view.BackgroundColor3 = canvas:GetAttribute("Background") or rgb(30, 40, 34)
	view.BorderSizePixel = 0
	view.Ambient = rgb(150, 135, 120)
	view.LightColor = rgb(255, 225, 190)
	view.LightDirection = Vector3.new(-0.6, -0.5, 1)
	view.ImageColor3 = rgb(235, 220, 195) -- 오래된 유화처럼 누렇게
	view.Parent = gui

	local camera = Instance.new("Camera")
	camera.FieldOfView = 30
	camera.CFrame = CFrame.lookAt(Vector3.new(0, 5.7, -13), Vector3.new(0, 5.5, 0))
	camera.Parent = view
	view.CurrentCamera = camera

	local data = {
		id = canvas:GetAttribute("DataId") or 1,
		name = "Portrait",
		animal = canvas:GetAttribute("Animal") or "cat",
		fur = canvas:GetAttribute("Fur"),
		cloth = canvas:GetAttribute("Cloth"),
	}
	local ok, subject = pcall(Animals.build, data, nil)
	if ok and subject then
		subject.Parent = view
	end

	-- 가장자리가 어두운 유화 느낌
	local shade = Instance.new("Frame")
	shade.Size = UDim2.fromScale(1, 1)
	shade.BackgroundColor3 = rgb(0, 0, 0)
	shade.BorderSizePixel = 0
	shade.ZIndex = 2
	shade.Parent = gui
	local gradient = Instance.new("UIGradient")
	gradient.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.4),
		NumberSequenceKeypoint.new(0.5, 1),
		NumberSequenceKeypoint.new(1, 0.4),
	})
	gradient.Parent = shade

	gui.Parent = folder
	drawn[canvas] = gui
end

local function watch(inst)
	if inst:IsA("BasePart") and inst.Name == "Canvas" then
		task.defer(draw, inst)
		inst.AncestryChanged:Connect(function()
			if not inst:IsDescendantOf(workspace) and drawn[inst] then
				drawn[inst]:Destroy()
				drawn[inst] = nil
			end
		end)
	end
end

for _, inst in ipairs(workspace:GetDescendants()) do
	watch(inst)
end
workspace.DescendantAdded:Connect(watch)
