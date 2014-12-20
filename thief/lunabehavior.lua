dofile('lunalogger.lua')

bt = { }

bt.func_empty = function(self, args) end
bt.func_return_true = function (self, args) return true end

bt.state = { SUCCESS = 0, RUNNING = 1, FAILURE = 2, UNKNOWN = 3 }

btnode = object.object:new({
	init = function (self, args)
		self:init_logger(args)
		self:init_user(args)
	end,

	init_user = bt.func_empty,
	foo_end_user = bt.func_empty,

	evaluate = bt.func_return_true,
	execute = bt.func_empty,

	foo_end = function(self, args)
		self._logger:log(LLOG_DEBUG("btnode foo_end ending ", self.type_node, self))
		self:foo_end_user(args)
	end,

	type_node = '[DEFAULT_NODE]',
	name = 'DEFAULT_NODE_NAME',

	_logger = nil,
	init_logger = function (self, args)
		if args.logger == nil then
			if self._logger ~= nil then
				args.logger = self._logger
			else
				args.logger = lloger:new()
				args.logger:init()
			end
		end
		self._logger = args.logger
	end
})

btnode_create_coroutine = function(co_foo)
	if co_foo == nil then co_foo = bt.func_empty end
	local node = btnode_coroutine:new()
	node.co_execute = co_foo
	return node
end

btnode_coroutine = btnode:new({
	_coroutine = nil,

	co_execute = bt.func_empty,
	co_init = bt.func_empty,

	type_node = '[COROUTINE_NODE]',

	init = function(self, args)
		self:init_logger(args)

		self._logger:log(LLOG_DEBUG("btnode_coroutine init initing ", self.type_node, self))
		self._coroutine = coroutine.create(self.co_execute)
		self:co_init(args)
		self:init_user(args)
	end,

	execute = function(self, args)
		local succeed, ret = coroutine.resume(self._coroutine, self, args)
		if not succeed then print('Error in btnode_coroutine: ', ret) end
		return ret
	end,

	foo_end = function(self, args)
		self._logger:log(LLOG_DEBUG("btnode_coroutine foo_end ending ", self.type_node, self))
		self._coroutine = coroutine.create(self.co_execute)
		self:co_init(args)

		self:foo_end_user(args)
	end,
})

btnode_ctrl = btnode:new({
	children = { },

	type_node = '[CONTROL_NODE]',

	child = function (self, child)
		if #(self.children) == 0 then self.children = { } end
		table.insert(self.children, child)
		return self
	end,

	init = function(self, args)
		self:init_logger(args)
		for i, node in ipairs(self.children) do node:init(args) end
		self:init_user(args)
	end,

	foo_end = function (self, args)
		for i, node in ipairs(self.children) do node:foo_end(args) end
		self:foo_end_user(args)
	end,
})

btnode_coroutine_ctrl = btnode_coroutine:new({
	children = { }, child = btnode_ctrl.child,

	type_node = '[COROUTINE_CONTROL]',

	init = function(self, args)
		for i, node in ipairs(self.children) do node:init(args) end
		btnode_coroutine.init(self, args)
	end,

	foo_end = function (self, args)
		self._logger:log(LLOG_DEBUG("btnode_coroutine_ctrl foo_end ending ", self.type_node, self))
		for i, node in ipairs(self.children) do node:foo_end(args) end
		btnode_coroutine.foo_end(self, args)
	end,
})

btnode_parallel = btnode_ctrl:new({
	statuses = { },

	type_node = '[CONTROL_PARALLEL]',

	init_user = function(self, args)
		for i, node in ipairs(self.children) do
			self.statuses[node] = bt.state.UNKNOWN
		end
	end,

	evaluate = function(self, args)
		for i, node in ipairs(self.children) do
			if node:evaluate(args) == true then return true end
		end
	end,

	execute = function (self, args)
		for i, node in ipairs(self.children) do
			if node:evaluate(args) == true then
				local status = node:execute(args)
				self.statuses[node] = status

				if status == bt.state.SUCCESS then
					self:foo_end()
					return bt.state.SUCCESS
				elseif status == bt.state.FAILURE then
					self:foo_end()
					return bt.state.FAILURE
				end
			end
		end
		return bt.state.RUNNING
	end,
})

btnode_priority_selector = btnode_coroutine_ctrl:new({

	type_node = '[CONTROL_PRIORITY]',
	current_node = nil,

	_get_first_available_node = function (self, args, start)
		print ('PRIORITY GETTING NODE')
		local node_current = nil
		local node_i = nil

		for i, node in ipairs(self.children) do
		if (i >= start) then
			if node:evaluate(args) == true then
				node_current = node
				node_i = i
				break
			end
		end
		end
		
		return node_i, node_current
	end,

	evaluate = function (self, args)
		if self.current_node and self.current_node:evaluate(args) then return true end
		node_i, node_current = self:_get_first_available_node(args, 1)
		print ('PRIORITY EVALUATING', node_current)
		self.current_node = node_current
		return node_current ~= nil
	end,

	co_execute = function (self, args)
		if #(self.children) == 0 then return bt.state.SUCCESS end

		while true do
			if self.current_node == nil then
				self:foo_end(args)
				return bt.state.FAILURE
			end

			local status = self.current_node:execute(args)
			if status == bt.state.SUCCESS then
				print("btnode_priority_selector node success ", self, self.current_node)
				self:foo_end(args)
				self.current_node = nil
				do return bt.state.SUCCESS end
			elseif status == bt.state.FAILURE then
				self:foo_end(args)
				print("btnode_priority_selector node failure ", self)
				self.current_node = nil
				return bt.state.FAILURE
			end
			coroutine.yield(status)
		end
	end
})

btnode_create_priority = function () return btnode_priority_selector:new() end

btnode_sequential = btnode_coroutine_ctrl:new({

	type_node = '[CONTROL_SEQUENTIAL]',
	current_node = nil,

	evaluate = function (self, args)
		if self.current_node == nil then
			current_node = self.children[1]
		end
		return self.current_node:evaluate()
	end,

	co_execute = function (self, args)
		for i, node in ipairs(self.children) do 
			self.current_node = node
			while true do
				if node:evaluate(args) == true then
					local status = node:execute(args)

					if status == bt.state.SUCCESS then
						print("btnode_sequential node success ", node.type_node, node)
						node:foo_end(args)
						break
					elseif status == bt.state.FAILURE then
						print("btnode_sequential node failure ", node.type_node, node)
						self:foo_end(args)
						return status
					end

					coroutine.yield(status)
				else break end
			end
		end

		self:foo_end(args)
		return bt.state.SUCCESS
	end,

})

btnode_create_sequential = function () return btnode_sequential:new() end

btnode_repeat = btnode_coroutine:new({
	_loop_count = 1,
	loop_current = 0,
	_rep_node = nil,
	type_node = '[CONTROL_REPEAT]',

	init = function(self, args)
		btnode_coroutine.init(self, args)
		-- print("repeat_node init _rep_node", self._rep_node, self._rep_node.co_execute)
		-- self._rep_node:init(args)
		-- print("repeat_node rep_node init finished.")
	end,

	evaluate = function (self, args)
		if self.loop_current >= self._loop_count then return false
		else return self._rep_node:evaluate(args) end
	end,

	co_execute = function (self, args)

		local i = 0
		while true do
			if i >= self._loop_count then break end
			i = i + 1
			self.loop_current = i
			self._logger:log(LLOG_DEBUG("repeat_node looping ", i, self))

			if i ~= 0 then
				self._logger:log(LLOG_DEBUG("repeat_node initing node, _rep_node", self._rep_node, self._rep_node.co_execute, " self ", self))
				self._rep_node:init(args)
				self._logger:log(LLOG_DEBUG("repeat_node loop init finished ", self))
			end
			while true do
				local status = self._rep_node:execute(args)

				if status == bt.state.SUCCESS then
					print("repeat success")
					self._rep_node:foo_end(args)
					break
				elseif status == bt.state.FAILURE then
					self._logger:log("repeat failure")
					self:foo_end(args)
					do return status end
				end

				coroutine.yield(status)
			end
		end

		self:foo_end(args)
		return bt.state.SUCCESS

	end,

	foo_end = function(self, args)
		self._logger:log(LLOG_DEBUG("btnode_repeat foo_end ending ", self.type_node, self))
		self._rep_node:foo_end(args)
		btnode_coroutine.foo_end(self, args)
	end,

})

btnode_create_repeat = function (count, node)
	local ret = btnode_repeat:new()
	ret._loop_count, ret._rep_node = count, node
	return ret
end

btnode_dec_cond = btnode:new({
	_node = nil,
	_cond = nil,

	type_node = '[DEC_COND]',

	init = function (self, args) self._node:init(args) end,
	foo_end = function (self, args) return self._node:foo_end(args) end,
	
	evaluate = function (self, args) return (self._cond(args) and self._node:evaluate(args)) end,
	execute = function (self, args) return self._node:execute(args) end
})

btnode_dec_accom_front = btnode:new({
	_node_main = nil, _foo_before = nil,

	type_node = '[DEC_ACCFRONT]',

	init = function (self, args) self._node_main:init(args) end,
	foo_end = function (self, args) return self._node_main:foo_end(args) end,
	
	evaluate = function (self, args) return self._node_main:evaluate(args) end,
	execute = function (self, args) self:_foo_before() return self._node_main:execute(args) end
})

btnode_createdec_cond = function (dnode, cond, name)
	if name == nil then name = '' end
	local node = btnode_dec_cond:new()
	node._node, node._cond, node.type_node = dnode, cond, node.type_node .. ' ' .. name
	return node
end

btnode_createdec_accomfront = function (dnode, foo, name)
	if name == nil then name = '' end
	local node = btnode_dec_accom_front:new()
	node._node_main, node._foo_before, node.type_node = dnode, foo, node.type_node .. ' ' .. name
	return node
end

bnd_priority = btnode_create_priority
bnd_sequential = btnode_create_sequential
bnd_repeat = btnode_create_repeat
bdec_cond = btnode_createdec_cond
bdec_acomfront = btnode_createdec_accomfront