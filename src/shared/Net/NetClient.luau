--!strict
-- Client-Seite der Netzwerkschicht. Nur Remotes aus dem Schema.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Schema = require(script.Parent.Schema)

local NetClient = {}
local folder = ReplicatedStorage:WaitForChild("Remotes")

local function remote(name: string): any
	assert(Schema[name], "Remote nicht im Schema: " .. name)
	return folder:WaitForChild(name)
end

function NetClient.fire(name: string, ...: any)
	assert(Schema[name].dir == "c2s", name .. " ist kein Client->Server-Remote")
	remote(name):FireServer(...)
end

function NetClient.on(name: string, handler: (...any) -> ())
	assert(Schema[name].dir == "s2c", name .. " ist kein Server->Client-Remote")
	return remote(name).OnClientEvent:Connect(handler)
end

return NetClient
