ubtutil = { }

LCT = require 'lunacolort'
Env = require 'Environment'

ubtutil.findin = function (t, func)
	for k, v in pairs(t) do
		if func(v) then return v end
	end
	return nil
end

ubtutil.cmpint = function (x, y)
	local x_, y_ = math.floor(x), math.floor(y)
	return x_ == y_
end

ubtutil.distance = function (pos0, pos1)
	return math.max(math.abs(pos0[1]-pos1[1]), math.abs(pos0[2]-pos1[2]))
end

ubtutil.distance_manhattan = function (pos0, pos1)
	return math.abs(pos0[1]-pos1[1]) + math.abs(pos0[2]-pos1[2])
end

ubtutil.distance_sqrt = function (pos0, pos1)
	return math.sqrt(math.pow(math.abs(pos0[1]-pos1[1]), 2) + math.pow(math.abs(pos0[2]-pos1[2]), 2))
end

ubtutil.add_2dpos = function (pos0, pos1)
	return { pos0[1] + pos1[1], pos0[2] + pos1[2] }
end

ubtutil.mul_2dpos = function (pos0, pos1)
	if type(pos1) == 'table' then
		return { pos0[1]*pos1[1], pos0[2]*pos1[2] }
	elseif type(pos1) == 'number' then
		return { pos0[1]*pos1, pos0[2]*pos1 }
	end
end

ubtutil.dot_2dpos = function (pos0, pos1)
	return pos0[1]*pos1[1] + pos0[2]*pos1[2]
end

ubtutil.len_2dpos = function (pos)
	return ubtutil.distance_sqrt({0, 0}, pos);
end

ubtutil.nom_2dpos = function(pos)
	local length = ubtutil.len_2dpos(pos);
	return ubtutil.mul_2dpos(pos, 1.0/length)
end

ubtutil.equ_2dpos = function (pos0, pos1)
	if pos0[1] == pos1[1] and pos0[2] == pos1[2] then return true end
	return false
end

function ubtutil.we_are_police()
	return Env.INST_INIT == 'POL' end

ubtutil.map_debug_data = function(map)
		local r = LCT.c.RED .. 'Map Debug Data\n' .. LCT.c.RESET
		.. string.format('Map width: %d, height: %d\n', map.width, map.height)
		.. LCT.c.YELLOW .. 'Detailed data of cells:\n'  .. LCT.c.RESET
		for y = 0, map.height-1 do
			for x = 0, map.width-1 do
				local cell = map:getcell(x, y)
				local passable = cell:ispassable()
				local explored = cell:isexplored()
				if map:getcell(x, y):isonpath() then 		r = r .. string.format('%s ', passable and LCT.c.RED .. '■' .. LCT.c.RESET or '▲') 
				elseif map:getcell(x, y):isonsight() then 	r = r .. string.format('%s ', passable and LCT.c.WHITE .. '▣' .. LCT.c.RESET or LCT.c.CYAN .. '▓' .. LCT.c.RESET)
				elseif explored then 		r = r .. string.format('%s ', passable and LCT.c.GREEN .. '▢' .. LCT.c.RESET or LCT.c.BLUE .. '█' .. LCT.c.RESET)
				else 										r = r .. string.format('%s ', passable and LCT.c.YELLOW .. '□' .. LCT.c.RESET or LCT.c.YELLOW .. '▦' .. LCT.c.RESET) end
			end
			r = r .. '\n'
		end
		return r
	end

return ubtutil
