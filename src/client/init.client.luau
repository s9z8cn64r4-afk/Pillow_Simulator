--!strict
-- Client-Bootstrap: Controller laden, Init() dann Start().
local ORDER = {
	"PlayerStateController",
	"FxController",
	"SwingController",
	"SoundController",
	"ZoneController",
	"LightingController",
	"AmbientController",
	"UIController",
}

local folder = script:WaitForChild("Controllers")
local registry: { [string]: any } = {}
for _, name in ORDER do
	registry[name] = require(folder:WaitForChild(name) :: any) :: any
end
for _, name in ORDER do
	if registry[name].Init then
		registry[name]:Init(registry)
	end
end
for _, name in ORDER do
	if registry[name].Start then
		task.spawn(function()
			registry[name]:Start()
		end)
	end
end

-- Nur Studio: Mehrspieler-Check (zählt, was dieser Client vom Mitspieler sieht)
if game:GetService("RunService"):IsStudio() then
	local dev = script:FindFirstChild("Dev")
	local probe = dev and dev:FindFirstChild("MultiplayerProbe")
	if probe then
		(require(probe :: any) :: any).start()
	end
end
