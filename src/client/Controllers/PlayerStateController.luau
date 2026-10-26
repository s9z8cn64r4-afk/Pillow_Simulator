--!strict
-- Hält den vom Server replizierten Spielerzustand. UI liest NUR hier (Vertrag C.12 Nr. 4).
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local NetClient = require(Shared.Net.NetClient)
local Signal = require(Shared.Util.Signal)

local PlayerStateController = {}
PlayerStateController.state = nil :: any
PlayerStateController.Changed = Signal.new() -- (key, value)
PlayerStateController.Ready = Signal.new() -- (state)
PlayerStateController.Notified = Signal.new() -- (kind, payload)

function PlayerStateController:Start()
	NetClient.on("StateInit", function(snapshot)
		self.state = snapshot
		self.Ready:Fire(snapshot)
		for k, v in snapshot do
			self.Changed:Fire(k, v)
		end
	end)
	NetClient.on("StateDelta", function(delta)
		if not self.state then
			return
		end
		for k, v in delta do
			self.state[k] = v
			self.Changed:Fire(k, v)
		end
	end)
	NetClient.on("Notify", function(kind, payload)
		self.Notified:Fire(kind, payload)
	end)
end

-- Ruft fn sofort auf, wenn der Zustand da ist, sonst sobald er ankommt
function PlayerStateController:onReady(fn: (any) -> ())
	if self.state then
		task.spawn(fn, self.state)
	else
		self.Ready:Once(fn)
	end
end

return PlayerStateController
