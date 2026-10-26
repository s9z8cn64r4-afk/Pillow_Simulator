--!strict
-- Minimales Signal (ohne BindableEvent, damit Tabellen nicht kopiert werden)
export type Connection = { Disconnect: (Connection) -> () }
export type Signal = {
	Connect: (Signal, (...any) -> ()) -> Connection,
	Fire: (Signal, ...any) -> (),
	Once: (Signal, (...any) -> ()) -> Connection,
}

local Signal = {}
Signal.__index = Signal

function Signal.new(): Signal
	return (setmetatable({ _handlers = {} }, Signal) :: any) :: Signal
end

function Signal:Connect(fn)
	local handlers = self._handlers
	local conn = {}
	function conn:Disconnect()
		local i = table.find(handlers, fn)
		if i then
			table.remove(handlers, i)
		end
	end
	table.insert(handlers, fn)
	return conn
end

function Signal:Once(fn)
	local conn
	conn = self:Connect(function(...)
		conn:Disconnect()
		fn(...)
	end)
	return conn
end

function Signal:Fire(...)
	for _, fn in table.clone(self._handlers) do
		task.spawn(fn, ...)
	end
end

return Signal
