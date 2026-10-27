-- Installiert die Mehrspieler-Checks als Module im Place (nur Edit-DataModel, per DevTools.RunToolScript):
--   require(game.ServerStorage.DevTools.RunToolScript)("<SHA>", "tools/studio/install_mp_check.luau")
-- Liest die Check-Skripte vom selben Commit (Attribut DevToolsSha an ServerStorage) und legt an:
--   ServerStorage.DevTools.MpCheckServer, ReplicatedStorage.DevToolsClient.MpCheckClient
-- Beide liegen außerhalb des Rojo-Mappings (nur im Place, nicht im Spiel-Code).
local HttpService = game:GetService("HttpService")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local sha = ServerStorage:GetAttribute("DevToolsSha")
assert(type(sha) == "string" and #sha >= 7, "Attribut DevToolsSha an ServerStorage fehlt")
local base = "https://raw.githubusercontent.com/s9z8cn64r4-afk/Pillow_Simulator/" .. sha .. "/tools/studio/"

local function install(parent: Instance, name: string, file: string)
	local src = HttpService:GetAsync(base .. file, true)
	local old = parent:FindFirstChild(name)
	if old then
		old:Destroy()
	end
	local m = Instance.new("ModuleScript")
	m.Name = name
	m.Source = "-- installiert aus " .. file .. " @ " .. sha .. "\nreturn function()\n" .. src .. "\nend\n"
	m.Parent = parent
end

local clientFolder = ReplicatedStorage:FindFirstChild("DevToolsClient") or Instance.new("Folder")
clientFolder.Name = "DevToolsClient"
clientFolder.Parent = ReplicatedStorage
install(ServerStorage.DevTools, "MpCheckServer", "mp_check_server.luau")
install(clientFolder, "MpCheckClient", "mp_check_client.luau")
return "installiert: MpCheckServer, MpCheckClient @ " .. sha
