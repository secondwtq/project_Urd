_ret = { }

pkgutil = require 'ubtpkgutil'

pkgutil.Import('Defs.lua')

Env = pkgutil.Require 'Environment'
object = pkgutil.Require 'object'
Util = pkgutil.Require 'ubtutil'
LCT = pkgutil.Require 'lunacolort'

CellClass = object.object:new({

	pos = { 0, 0 },

	unpassable = 0,

	explored = 0,

	on_sight = false,

	on_path = false,

	ispassable = function (self) if self.unpassable == 1 then return false else return true end end ,

	setexplored = function (self, p)
		if p == nil then p = 1 end
		self.explored = p
	end,

	isonsight = function (self) return self.on_sight end,

	setonsight = function (self, p)
		if p == nil then p = true end
		self.on_sight = p
	end, 

	isonpath = function (self) return self.on_path end,

	setonpath = function (self, p)
		if p == nil then p = true end
		self.on_path = p
	end,

	getpos = function (self) return self.pos end,

	cell_left = nil,
	cell_right = nil,
	cell_up = nil,
	cell_down = nil,

	})

_ret.MapClass = object.object:new({

	width = 0,
	height = 0,

	cells = { },

	initmap = function (self, width, height)
		self.width = width
		self.height = height
		self.cells = { }

		for i = 1, height do
			local xtable = { }
			for j = 1, width do
				local c = CellClass:new()
				c.unpassable, c.explored = 0
				c.pos = { j-1, i-1 }
				table.insert(xtable, c)
			end
			table.insert(self.cells, xtable)
		end

		for y = 0, self.height-1 do
			for x = 0, self.width-1 do
				local c = self:getcell(x, y)
				c.cell_left = self:getneighborcell(c, Directions.Left)
				c.cell_right = self:getneighborcell(c, Directions.Right)
				c.cell_up = self:getneighborcell(c, Directions.Up)
				c.cell_down = self:getneighborcell(c, Directions.Down)
			end
		end
	end,

	iscellexplored = function (self, x, y)
		if self:getcell(x, y).explored == 1 then return true else return false end
	end,

	setcellexplored = function (self, x, y, p)
		if p == nil then p = 1 end
		self:getcell(x, y):setexplored(p)
	end,

	setcellunpassable = function (self, x, y, p)
		if p == nil then p = 1 end
		self:getcell(x, y).unpassable = p
	end,

	getcell = function (self, x, y)
		if x < 0 or x > self.width-1 or y < 0 or y > self.height-1 then return nil end
		return self.cells[y+1][x+1]
	end,

	getneighborcell = function (self, cell, dir)
		if dir == Directions.Up then
			if cell.pos[2] > 0 then return self:getcell(cell.pos[1], cell.pos[2]-1) end
		end

		if dir == Directions.Down then
			if cell.pos[2] < self.height-1 then return self:getcell(cell.pos[1], cell.pos[2]+1) end
		end

		if dir == Directions.Left then
			if cell.pos[1] > 0 then return self:getcell(cell.pos[1]-1, cell.pos[2]) end
		end

		if dir == Directions.Right then
			if cell.pos[1] < self.width-1 then return self:getcell(cell.pos[1]+1, cell.pos[2]) end
		end

		return nil
	end,

	update_explored = function (self, entity, sight)
		for y = 0, self.height-1 do
			for x = 0, self.width-1 do
				local cell = self:getcell(x, y)
				local dis = Util.distance(entity:getpos(), cell.pos)
				if math.floor(dis) <= sight then cell:setexplored() end
			end
		end
	end,

	update_onsight = function (self, entity, sight)
		for y = 0, self.height-1 do
			for x = 0, self.width-1 do
				local cell = self:getcell(x, y)
				local dis = Util.distance(entity:getpos(), cell.pos)
				if math.floor(dis) <= sight then cell:setonsight() end
			end
		end
	end,

	clear_on_sight = function (self)
		for y = 0, self.height-1 do
			for x = 0, self.width-1 do
				cell = self:getcell(x, y):setonsight(false)
			end
		end
	end,

	clear_on_path = function (self)
		for y = 0, self.height-1 do
			for x = 0, self.width-1 do
				cell = self:getcell(x, y):setonpath(false)
			end
		end
	end,

	iscellpassable = function (self, x, y)
		return self:getcell(x, y):ispassable()
	end,

	debug_data = function(self)
		local r = LCT.c.RED .. 'Map Debug Data\n' .. LCT.c.RESET
		.. string.format('Map width: %d, height: %d\n', self.width, self.height)
		.. LCT.c.YELLOW .. 'Detailed data of cells:\n'  .. LCT.c.RESET
		for y = 0, self.height-1 do
			for x = 0, self.width-1 do
				if self:getcell(x, y):isonpath() then 		r = r .. string.format('%s ', self:iscellpassable(x, y) and LCT.c.RED .. '■' .. LCT.c.RESET or '▲') 
				elseif self:getcell(x, y):isonsight() then 	r = r .. string.format('%s ', self:iscellpassable(x, y) and LCT.c.WHITE .. '▣' .. LCT.c.RESET or LCT.c.CYAN .. '▓' .. LCT.c.RESET)
				elseif self:iscellexplored(x, y) then 		r = r .. string.format('%s ', self:iscellpassable(x, y) and LCT.c.GREEN .. '▢' .. LCT.c.RESET or LCT.c.BLUE .. '█' .. LCT.c.RESET)
				else 										r = r .. string.format('%s ', self:iscellpassable(x, y) and LCT.c.YELLOW .. '□' .. LCT.c.RESET or LCT.c.YELLOW .. '▦' .. LCT.c.RESET) end
			end
			r = r .. '\n'
		end
		return r
	end

})

__iscellpassable = function (cell)
	if cell == nil then return nil end
	return cell:ispassable()
end

_ret.iscellpassable = __iscellpassable

return _ret