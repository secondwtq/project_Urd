object = require('object')

lloger_buffer = object.object:new({

	items = { },

	lbuffer_item = object.object:new({

		item = nil,

		time = nil,

		}),

	to_gen_text = function (self)
		local ret = ''
		for t, p in pairs(self.items) do
			ret = ret .. p.item:to_genstring() .. '\n'
		end
		return ret
	end,

	append = function(self, item)
		local bi = lloger_buffer.lbuffer_item:new({
			item = item
			})
		table.insert(self.items, bi)
	end

	})

lloger = object.object:new({

	name_logger = 'luna_default_logger',

	_buffer = nil,

	init = function (self)
		self._buffer = lloger_buffer:new()
	end,

	log = function (self, item)
		self._buffer:append(item)
	end,

	get = function (self) return self._buffer:to_gen_text() end

	})

llogitem = object.object:new({

	item_type = 'LOGITEM_DEF',

	to_genstring = function (self)
		return "DEFAULT LOG ITEM"
	end

	})

llogitem_debugitem = llogitem:new({

	item_type = 'LOGITEM_DEBUG',

	text_type = 'TEXT_DEF',

	contents = { },

	to_genstring = function (self)
		local ret = ''
		for t, d in ipairs(self.contents) do
			ret = ret .. tostring(d) .. '\t'
		end
		return ret
	end

	})

llogitem_text_debug = llogitem_debugitem:new({

	text_type = 'TEXT_DEBUG',

	})

LLOG_DEBUG = function (...)
	local arg = { ... }

	local ret = llogitem_text_debug:new()
	ret.contents = { }

	for t, d in ipairs(arg) do
		table.insert(ret.contents, tostring(d))
	end
	return ret
end