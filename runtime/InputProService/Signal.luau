--!native
--!optimize 2

local Signal = {}
Signal.__index = Signal

export type Connection = {
	Disconnect: (self: Connection) -> (),
}

export type Signal = {
	Connect: (self: Signal, callback: (...any) -> ()) -> Connection,
	Fire: (self: Signal, ...any) -> (),
	Destroy: (self: Signal) -> (),
	Wait: (self: Signal) -> ...any
}

function Signal.new(): Signal
	local self = setmetatable({ _head = nil, _tail = nil }, Signal)
	return self :: any
end

function Signal:Connect(callback)
	local node = {
		Connected = true,
		_signal = self,
		_callback = callback,
		_next = nil,
		_prev = self._tail,
	}

	if self._tail then
		self._tail._next = node
	else
		self._head = node
	end
	self._tail = node

	return {
		Disconnect = function()
			if not node.Connected then return end
			node.Connected = false

			local sig = node._signal
			if sig._head == node then
				sig._head = node._next
			end
			if sig._tail == node then
				sig._tail = node._prev
			end
			if node._prev then
				node._prev._next = node._next
			end
			if node._next then
				node._next._prev = node._prev
			end

			node._signal = nil
			node._callback = nil
			node._prev = nil
			node._next = nil
		end
	}
end

function Signal:Fire(...)
	local node = self._head
	local last = self._tail
	while node do
		local nextNode = node._next
		if node.Connected then
			task.spawn(node._callback, ...)
		end
		if node == last then break end
		node = nextNode
	end
end

function Signal:Destroy()
	local node = self._head
	while node do
		local nextNode = node._next
		node.Connected = false
		node._signal = nil
		node = nextNode
	end
	self._head = nil
	self._tail = nil
end

function Signal:Wait()
	local thread = coroutine.running()
	local connection
	connection = self:Connect(function(...)
		connection.Disconnect()
		task.spawn(thread, ...)
	end)
	return coroutine.yield()
end

return Signal
