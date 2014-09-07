lbobject = { }

lbobject.new = function (self, t)
	r = t or { }
	setmetatable(r, self)
	self.__index = self
	return r
end

bt = { }

bt.func_empty = function(self, args) end

bt.state = { SUCCESS = 0, RUNNING = 1, FAILURE = 2, UNKNOWN = 3 }

btnode = lbobject:new({
		init = function (self, args)
			self:init_user(args) end,
		foo_end = function (self, args)
			self:foo_end(args) end,

		init_user = bt.func_empty,
		foo_end_user = bt.func_empty,

		execute = bt.func_empty,
	})

btnode_coroutine = btnode:new({
		_coroutine = nil,

		co_execute = bt.func_empty,
		co_init = bt.func_empty,

		init = function(self, args)
			self._coroutine = coroutine.create(self.co_execute)
			self:co_init(args)
			self:init_user(args)
		end,

		execute = function(self, args)
			local succeed, ret = coroutine.resume(self._coroutine, self, args)
			return ret
		end,

		foo_end = function(self, args)
			self._coroutine = nil
			self._coroutine = coroutine.create(self.co_execute)
			self:foo_end_user(args)
		end,
	})

btnode_ctrl = btnode:new({
		children = { },
		add_child = function (self, child)
			if #(self.children) == 0 then self.children = { } end
			table.insert(self.children, child)
			return self
		end,

		init = function(self, args)
			for i, node in ipairs(self.children) do node:init(args) end
			self:init_user(args)
		end,

		foo_end = function (self, args)
			for i, node in ipairs(self.children) do node:foo_end(args) end
			self:foo_end_user(args)
		end,
	})

btnode_coroutine_ctrl = btnode_coroutine:new({
		children = { }, add_child = btnode_ctrl.add_child,

		init = function(self, args)
			for i, node in ipairs(self.children) do
				node:init(args)
			end
			btnode_coroutine.init(self, args)
		end,
	})

btnode_parallel = btnode_ctrl:new({
		statuses = { },

		init_user = function(self, args)
			for i, node in ipairs(self.children) do
				self.statuses[node] = bt.state.UNKNOWN
			end
		end,

		execute = function (self, args)
			for i, node in ipairs(self.children) do
				local status = node:execute(args)
				self.statuses[node] = status

				if status == bt.state.SUCCESS then
					self:foo_end()
					return bt.state.SUCCESS
				end
				if status == bt.state.FAILURE then
					self:foo_end()
					return bt.state.FAILURE
				end
			end
			return bt.state.RUNNING
		end,
	})

btnode_priority_selector = btnode_coroutine_ctrl:new({

		_get_first_available_node = function (self, args, start)
			local node_current = nil
			local node_i = nil
			local ret_status = nil

			for i, node in ipairs(self.children) do
				if (i >= start) then
					local status = node:execute(args)
					if status ~= bt.state.FAILURE then
						node_current = node
						node_i = i
						ret_status = status
						break
					end
				end
			end
			
			return node_i, node_current, ret_status
		end,

		co_execute = function (self, args)

			if #(self.children) == 0 then return bt.state.SUCCESS end
			local node_i = 0
			local node_current
			local beg_status
			node_i, node_current, beg_status = self:_get_first_available_node(args, 1)

			if node_current == nil then
				self:foo_end(args)
				return bt.state.FAILURE
			else coroutine.yield(beg_status)
			end

			while true do
				local status = node_current:execute(args)

				if status == bt.state.RUNNING then
					coroutine.yield(status)
				elseif status == bt.state.SUCCESS then
					self:foo_end(args)
					do return bt.state.SUCCESS end
				elseif status == bt.state.FAILURE then
					node_i, node_current, beg_status = self:_get_first_available_node(args, node_i+1)
					
					if node_current == nil then
						self:foo_end(args)
						return bt.state.FAILURE
					else coroutine.yield(beg_status)
					end
				end
			end

		end,
	})

btnode_create_sequential = function () return btnode_sequential:new() end

btnode_sequential = btnode_coroutine_ctrl:new({

	co_execute = function (self, args)

		for i, node in ipairs(self.children) do 
			while true do
				local status = node:execute(args)

				if status == bt.state.SUCCESS then
					break
				elseif status == bt.state.FAILURE then
					return status
				end

				coroutine.yield(status)
			end
		end

		return bt.state.SUCCESS
	end,

	})

btnode_create_condition = function (cond, check)
	if check == nil then check = true end
	local node = btnode_condition:new()

	node._condition = cond
	node._check = check

	return node
end

btnode_condition = btnode:new({
	_condition = function(args) return true end,
	_check = true,

	execute = function (self, args)
		if self:_condition(args) == self._check then
			return bt.state.SUCCESS
		else
			return bt.state.FAILURE
		end
	end
})