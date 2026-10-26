--!strict
-- Server-Seite der Netzwerkschicht: erzeugt Remotes aus dem Schema, validiert, drosselt, zählt Verstöße.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Schema = require(Shared.Net.Schema)
local Validate = require(Shared.Net.Validate)
local RateLimiter = require(Shared.Net.RateLimiter)

local NetService = {}
NetService.remotes = {} :: { [string]: any }
NetService.limiters = {} :: { [string]: any }
NetService.violations = {} :: { [Player]: number }
NetService.lastActivity = {} :: { [Player]: number }
NetService.KICK_THRESHOLD = 200 -- Verstöße pro Session, bevor gekickt wird (kein Bann)

local Log

function NetService:Init(registry)
	Log = registry.LogService
	local folder = ReplicatedStorage:FindFirstChild("Remotes")
	if folder then
		folder:Destroy()
	end
	folder = Instance.new("Folder")
	folder.Name = "Remotes"
	for name, entry in Schema do
		local r = Instance.new(if entry.unreliable then "UnreliableRemoteEvent" else "RemoteEvent")
		r.Name = name
		r.Parent = folder
		self.remotes[name] = r
		if entry.dir == "c2s" then
			self.limiters[name] = RateLimiter.new(entry.rate or 5, entry.burst or 5)
		end
	end
	folder.Parent = ReplicatedStorage
end

function NetService:Start()
	Players.PlayerRemoving:Connect(function(player)
		for _, limiter in self.limiters do
			limiter:forget(player)
		end
		self.violations[player] = nil
		self.lastActivity[player] = nil
	end)
end

function NetService:flag(player: Player, reason: string, ctx: { [string]: any }?)
	local n = (self.violations[player] or 0) + 1
	self.violations[player] = n
	if n == 1 or n % 25 == 0 then
		local c = ctx or {}
		c.reason = reason
		c.count = n
		c.userId = player.UserId
		Log:warn("Netz-Verstoß", c)
	end
	if n == self.KICK_THRESHOLD then -- genau einmal kicken
		Log:warn("Kick wegen Netz-Spam", { userId = player.UserId })
		player:Kick("Connection problem detected. Please rejoin.")
	end
end

-- Handler registrieren: handler(player, ...validierte Argumente)
function NetService:on(name: string, handler: (Player, ...any) -> ())
	local entry = Schema[name]
	assert(entry and entry.dir == "c2s", "kein c2s-Remote: " .. name)
	local limiter = self.limiters[name]
	local spec = entry.args or {}
	self.remotes[name].OnServerEvent:Connect(function(player: Player, ...)
		local count = select("#", ...)
		local args = { ... }
		if not limiter:take(player, os.clock()) then
			self:flag(player, "rate", { remote = name })
			return
		end
		local ok, why = Validate.args(spec, args, count)
		if not ok then
			self:flag(player, "args", { remote = name, why = why })
			return
		end
		self.lastActivity[player] = os.clock()
		local success, err = pcall(handler, player, table.unpack(args, 1, #spec))
		if not success then
			Log:error("Handler-Fehler", { remote = name, err = err })
		end
	end)
end

function NetService:fire(name: string, player: Player, ...: any)
	assert(Schema[name].dir == "s2c", "kein s2c-Remote: " .. name)
	self.remotes[name]:FireClient(player, ...)
end

function NetService:fireAll(name: string, ...: any)
	assert(Schema[name].dir == "s2c", "kein s2c-Remote: " .. name)
	self.remotes[name]:FireAllClients(...)
end

-- An alle Spieler im Umkreis (nur kosmetische Effekte)
function NetService:fireNear(name: string, position: Vector3, radius: number, ...: any)
	for _, p in Players:GetPlayers() do
		local root = p.Character and p.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
		if root and (root.Position - position).Magnitude <= radius then
			self.remotes[name]:FireClient(p, ...)
		end
	end
end

return NetService
