session = { }

object = require 'object'
Util = require 'ubtutil'
LCT = require 'lunacolort'

Entity = object.object:new({

	id = 0,

	pos = { 0, 0 },

	mov_id = 'D',

	move = function (self, dir) self.mov_id = dir end,

	getpos = function (self) return self.pos end,

	setpos = function (self, x, y) self.pos = { x, y } end,

	getobjtype = function (self) return 'undefined' end,

	getcell = function (self, _mapobj) return _mapobj:getcell(unpack(self.pos)) end,

	debug_data = function (self) return string.format('Entity: %s, id=%d, x=%d, y=%d\n', self:getobjtype(), self.id, unpack(self.pos)) end
	})

PoliceObject = Entity:new({

	getobjtype = function (self) return 'POL' end,

	})

ThiefObject = Entity:new({

	getobjtype = function (self) return 'THI' end,

	})

session.PoliceObject, session.ThiefObject = PoliceObject, ThiefObject

session.SessionObject = object.object:new({

	map_obj = nil,

	num_pol = 0,

	num_thi = 0,

	sight_pol = 0,

	sight_thi = 0,

	polices = { },

	thives = { },

	before_update = function (self)
		Util.findin(self.polices, function (o) o.mov_id = 'T' end)
		Util.findin(self.thives, function (o) o.mov_id = 'T' end)
		self.map_obj:clear_on_sight()
		self.map_obj:clear_on_path()
	end,

	init_entities = function (self, num_pol, num_thi, type_self)
		self.polices, self.thives = { }, { }
		self.num_pol, self.num_thi = num_pol, num_thi

		for i = 1, num_pol do
			local t = PoliceObject:new()
			t.id = i-1
			table.insert(self.polices, t)
		end
		for i = 1, num_thi do 
			local t = ThiefObject:new()
			t.id = i-1
			table.insert(self.thives, t)
		end
	end,

	debug_data = function (self)
		local r = LCT.c.RED .. 'Session Debug Data\n' .. LCT.c.RESET
		if self.map_obj ~= nil then r = r .. string.format('Map width: %d, height: %d\n', self.map_obj.width, self.map_obj.height)
		else r = r .. "Map data not inited.\n" end
		r = r .. string.format('Num of polices: %d, thives: %d\n', self.num_pol, self.num_thi)
		.. string.format('Sight of polices: %d, thives: %d\n', self.sight_pol, self.sight_thi)
		.. LCT.c.YELLOW .. 'Detailed data of entities:\n' .. LCT.c.RESET

		Util.findin(self.polices, function (o) r = r .. o:debug_data() end)
		Util.findin(self.thives, function (o) r = r .. o:debug_data() end)
		return r
	end,

	pass_mov = function (self, ntick, type_self)
		local entities = nil
		if type_self == 'POL' then entities = self.polices else entities = self.thives end
		local t = ''
		Util.findin(entities, function (o) t = t .. string.format('%d,%s;', o.id, o.mov_id) end)

		return string.format('MOV[%d](%s)', ntick, t)
	end

	})

return session