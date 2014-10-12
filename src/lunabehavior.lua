object = require('object')
dofile('lunalogger.lua')

bt = { }

bt.func_empty = function(self, args) end

bt.state = { SUCCESS = 0, RUNNING = 1, FAILURE = 2, UNKNOWN = 3 }

btnode = object.object:new({
		init = function (self, args)
			self:init_logger(args)

			self:init_user(args)
		end,

		init_user = bt.func_empty,
		foo_end_user = bt.func_empty,

		execute = bt.func_empty,

		foo_end_user = bt.func_empty,

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

		add_child = function (self, child)
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
		children = { }, add_child = btnode_ctrl.add_child,

		type_node = '[COROUTINE_CONTROL]',

		init = function(self, args)
			for i, node in ipairs(self.children) do
				node:init(args)
			end
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

		type_node = '[CONTROL_PRIORITY]',

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
				print("btnode_priority_selector running ", node_current.type_node, status)

				if status == bt.state.RUNNING then
					coroutine.yield(status)
				elseif status == bt.state.SUCCESS then
					print("btnode_priority_selector node success ", self, node_current)
					self:foo_end(args)
					do return bt.state.SUCCESS end
				elseif status == bt.state.FAILURE then
					local node_temp = nil
					node_i, node_temp, beg_status = self:_get_first_available_node(args, 1)
					node_current:foo_end()
					node_current = node_temp
					
					if node_current == nil then
						self:foo_end(args)
						print("btnode_priority_selector node failure ", self)
						return bt.state.FAILURE
					else coroutine.yield(beg_status)
					end
				end
			end

		end,
	})

btnode_create_priority = function () return btnode_priority_selector:new() end

btnode_sequential = btnode_coroutine_ctrl:new({

	type_node = '[CONTROL_SEQUENTIAL]',

	co_execute = function (self, args)

		for i, node in ipairs(self.children) do 
			while true do
				local status = node:execute(args)
				-- print(status)

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
			end
		end

		self:foo_end(args)
		return bt.state.SUCCESS
	end,

	})

btnode_create_sequential = function () return btnode_sequential:new() end

btnode_repeat = btnode_coroutine:new({

	_loop_count = 1,

	type_node = '[CONTROL_REPEAT]',

	init = function(self, args)
		btnode_coroutine.init(self, args)
		-- print("repeat_node init _rep_node", self._rep_node, self._rep_node.co_execute)
		-- self._rep_node:init(args)
		-- print("repeat_node rep_node init finished.")
	end,

	co_execute = function (self, args)

		local i = 0
		while true do
			if i >= self._loop_count then break end
			i = i + 1
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

btnode_condition = btnode:new({
	_condition = function(args) return true end,
	_check = true,

	type_node = '[CONTROL_CONDITION]',

	execute = function (self, args)
		if self:_condition(args) == self._check then
			return bt.state.SUCCESS
		else
			return bt.state.FAILURE
		end
	end
})

btnode_create_condition = function (cond, check)
	if check == nil then check = true end
	local node = btnode_condition:new()

	node._condition = cond
	node._check = check

	return node
end

-- when executed
--		execute _cond_node
--		if SUCCEED, execute _node and return status
--		if FAILED, return _fail_ret(default SUCCESS)
btnode_dec_cond = btnode:new({
	_node = nil,
	_cond_node = nil,

	_fail_ret = bt.state.SUCCESS,

	type_node = '[DEC_COND]',

	init = function (self, args)
		-- self.init = self._node.init
		self._node:init(args)
	end,

	foo_end = function (self, args)
		return self._node:foo_end(args)
	end,

	execute = function (self, args)
		local cond = self._cond_node:execute(args)
		if cond == bt.state.SUCCESS then
			do return self._node:execute(args) end
		else return self._fail_ret end
	end
})

btnode_createdec_cond = function (dnode, cond, failret, name)
	if failret == nil then failret = btnode_dec_cond._fail_ret end
	if name == nil then name = '' end

	local node = btnode_dec_cond:new()

	node._node, node._cond_node, node._fail_ret, node.type_node = dnode, cond, failret, node.type_node .. ' ' .. name

	return node
end