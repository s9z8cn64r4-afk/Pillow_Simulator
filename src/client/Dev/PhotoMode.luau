--!strict
-- Studio-Fotomodus für Spielseiten-Bilder (Icon + Thumbnails, `docs/marketing/store-page.md`). Nur in Studio.
-- Tasten: P = Fotomodus an/aus · N = nächste Szene · B = vorige Szene.
-- Je Szene: Figur an festen Platz, Kamera fest, HUD aus, Licht der Zone, Kissen der Szene (nur lokal, nur im
-- Fotomodus – zeigt echte Spielinhalte), Schlag-Animation + Federburst in Schleife. Beim Beenden wird alles
-- zurückgesetzt (Kamera, HUD, eigenes Kissen). Spielstand und Server bleiben unberührt.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local PillowTool = require(ReplicatedStorage:WaitForChild("Shared").Util.PillowTool)

local PhotoMode = {}

type Scene = {
	name: string,
	zone: string,
	pillow: string,
	char: Vector3,
	face: Vector3, -- Blickrichtung der Figur (Punkt)
	cam: Vector3,
	look: Vector3,
	fov: number?,
}

-- Koordinaten passend zu Map + `tools/studio/build_zones_v2.luau`
PhotoMode.SCENES = {
	{
		name = "Icon (quadratisch zuschneiden)",
		zone = "bedroom",
		pillow = "dream",
		char = Vector3.new(0, 3, -6),
		face = Vector3.new(0, 3, 10),
		cam = Vector3.new(1.5, 5.2, 3.5),
		look = Vector3.new(0, 4, -6),
		fov = 45,
	},
	{
		name = "Thumbnail 1 – Kinderzimmer",
		zone = "bedroom",
		pillow = "heart",
		char = Vector3.new(14, 3, 6),
		face = Vector3.new(20, 3, 10),
		cam = Vector3.new(-6, 11, 32),
		look = Vector3.new(14, 5, 0),
	},
	{
		name = "Thumbnail 2 – Pyjama-Lounge",
		zone = "livingroom",
		pillow = "sleepover",
		char = Vector3.new(14, 3, 136),
		face = Vector3.new(20, 3, 130),
		cam = Vector3.new(-4, 12, 178),
		look = Vector3.new(8, 10, 140),
	},
	{
		name = "Thumbnail 3 – Hotel-Suite",
		zone = "hotelsuite",
		pillow = "royal",
		char = Vector3.new(14, 3, 276),
		face = Vector3.new(20, 3, 270),
		cam = Vector3.new(-8, 11, 318),
		look = Vector3.new(10, 9, 280),
	},
	{
		name = "Thumbnail 4 – Wolkenreich",
		zone = "cloudrealm",
		pillow = "starlight",
		char = Vector3.new(14, 3, 416),
		face = Vector3.new(20, 3, 410),
		cam = Vector3.new(-12, 12, 458),
		look = Vector3.new(20, 10, 410),
	},
} :: { Scene }

local active = false
local index = 1
local photoPart: BasePart? = nil
local hiddenTools: { Tool } = {}
local loopToken = 0
local registry: any = nil

local function character(): Model?
	return Players.LocalPlayer.Character
end

local function setHud(visible: boolean)
	local gui = Players.LocalPlayer:FindFirstChild("PlayerGui")
	if not gui then
		return
	end
	for _, g in gui:GetChildren() do
		if g:IsA("ScreenGui") then
			g.Enabled = visible
		end
	end
end

local function clearTool()
	if photoPart then
		photoPart:Destroy()
		photoPart = nil
	end
	for _, t in hiddenTools do
		if t.Parent then
			local h = t:FindFirstChild("Handle")
			if h and h:IsA("BasePart") then
				h.LocalTransparencyModifier = 0
			end
		end
	end
	table.clear(hiddenTools)
end

local function holdPillow(char: Model, pillowId: string)
	clearTool()
	-- echtes Werkzeug unsichtbar machen (bleibt in der Hand, Server unverändert)
	for _, t in char:GetChildren() do
		if t:IsA("Tool") then
			local h = t:FindFirstChild("Handle")
			if h and h:IsA("BasePart") then
				h.LocalTransparencyModifier = 1
				table.insert(hiddenTools, t)
			end
		end
	end
	local tool = PillowTool.build(pillowId)
	local handle = tool:FindFirstChild("Handle") :: BasePart?
	local hand = char:FindFirstChild("RightHand") or char:FindFirstChild("Right Arm")
	if not handle or not hand or not hand:IsA("BasePart") then
		tool:Destroy()
		return
	end
	-- lokal an die Hand schweißen, Lage wie bei einem Tool (Griff-Attachment * Grip⁻¹)
	local gripAtt = hand:FindFirstChild("RightGripAttachment")
	local gripCf = if gripAtt and gripAtt:IsA("Attachment")
		then gripAtt.WorldCFrame
		else (hand :: BasePart).CFrame * CFrame.new(0, -(hand :: BasePart).Size.Y / 2, 0)
	handle.Parent = char
	handle.Name = "PhotoPillow"
	handle.CFrame = gripCf * tool.Grip:Inverse()
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = hand :: BasePart
	weld.Part1 = handle
	weld.Parent = handle
	tool:Destroy()
	photoPart = handle
end

local function swingLoop()
	loopToken += 1
	local my = loopToken
	task.spawn(function()
		while active and my == loopToken do
			local char = character()
			if char and registry then
				local Swing = registry.SwingController
				if Swing and Swing.animateCharacter then
					Swing.animateCharacter(char, 0.6)
				end
				local Fx = registry.FxController
				if Fx and Fx.localSwing then
					task.delay(0.15, function()
						if active and my == loopToken then
							Fx:localSwing()
						end
					end)
				end
			end
			task.wait(0.7)
		end
	end)
end

local function apply(i: number)
	local scene = PhotoMode.SCENES[i]
	local char = character()
	local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not scene or not char or not root then
		return
	end
	root.AssemblyLinearVelocity = Vector3.zero
	root.CFrame = CFrame.lookAt(scene.char, Vector3.new(scene.face.X, scene.char.Y, scene.face.Z))
	local hum = char:FindFirstChildOfClass("Humanoid")
	if hum then
		hum.WalkSpeed = 0
		hum.JumpPower = 0
	end
	holdPillow(char, scene.pillow)
	local cam = workspace.CurrentCamera
	cam.CameraType = Enum.CameraType.Scriptable
	cam.FieldOfView = scene.fov or 70
	cam.CFrame = CFrame.lookAt(scene.cam, scene.look)
	if registry and registry.LightingController then
		registry.LightingController:apply(scene.zone, true)
	end
	print(
		("[PHOTO] Szene %d/%d: %s – jetzt Screenshot machen (N = weiter, P = Ende)"):format(
			i,
			#PhotoMode.SCENES,
			scene.name
		)
	)
end

local function stop()
	active = false
	loopToken += 1
	clearTool()
	setHud(true)
	local cam = workspace.CurrentCamera
	cam.CameraType = Enum.CameraType.Custom
	cam.FieldOfView = 70
	local char = character()
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if hum then
		hum.WalkSpeed = 16
		hum.JumpPower = 50
	end
	local zone = Players.LocalPlayer:GetAttribute("Zone")
	if registry and registry.LightingController and typeof(zone) == "string" then
		registry.LightingController:apply(zone, true)
	end
	print("[PHOTO] Fotomodus aus")
end

function PhotoMode.start(reg: any)
	if not RunService:IsStudio() then
		return
	end
	registry = reg
	UserInputService.InputBegan:Connect(function(input, processed)
		if processed or input.UserInputType ~= Enum.UserInputType.Keyboard then
			return
		end
		if input.KeyCode == Enum.KeyCode.P then
			if active then
				stop()
			else
				active = true
				index = 1
				setHud(false)
				apply(index)
				swingLoop()
			end
		elseif active and input.KeyCode == Enum.KeyCode.N then
			index = index % #PhotoMode.SCENES + 1
			apply(index)
		elseif active and input.KeyCode == Enum.KeyCode.B then
			index = (index - 2) % #PhotoMode.SCENES + 1
			apply(index)
		end
	end)
	-- Für Werkzeug-Steuerung (execute_luau): Attribut PhotoScene am Spieler (0 = aus)
	Players.LocalPlayer:GetAttributeChangedSignal("PhotoScene"):Connect(function()
		local v = Players.LocalPlayer:GetAttribute("PhotoScene")
		if typeof(v) ~= "number" or v <= 0 then
			if active then
				stop()
			end
			return
		end
		index = math.clamp(math.floor(v), 1, #PhotoMode.SCENES)
		if not active then
			active = true
			setHud(false)
			swingLoop()
		end
		apply(index)
	end)
end

return PhotoMode
