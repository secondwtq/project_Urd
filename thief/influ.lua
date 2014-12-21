object = require 'object'
vhere = require 'Vhere'

local influ = { }

influ.influmap = object.object:new({

	_map_data = { },

	_width = 0, _height = 0,

	_influ_data = { }
})

function influ.influmap:create_map(width, height)
	self._map_data = { }
	self._width, self._height = width, height
	for i = 1, width do
		self._map_data[i] = { }
		for j = 1, height do
			self._map_data[i][j] = 0
		end
	end
end

function influ.influmap:clear_map()

	for i = 1, self._width do
		local sub_table = self._map_data[i]
		for j = 1, self._height do
			sub_table[j] = 0
		end
	end

end

function influ.influmap:calc_influ()


end

function influ.influmap:_influ_foo(orgvec, endvec)
	if orgvec == endvec then return 19961208 end
	return 64/(math.abs(endvec.x-orgvec.x)+math.abs(endvec.y-orgvec.y))
end

function influ.influmap:clear_influnode()
	self._influ_data = { }
end

function influ.influmap:add_node(vecpos, weight)
	if weight == nil then weight = 1 end

	table.insert(self._influ_data, { vecpos.x+1, vecpos.y+1, weight })

	for i = 1, self._width do
		for j = 1, self._height do
			self._map_data[i][j] = self._map_data[i][j] + self:_influ_foo(vhere.vector2d(vecpos.x+1, vecpos.y+1), vhere.vector2d(i, j))
		end
	end
end

function influ.influmap:get_value(vecpos)
	return self._map_data[vecpos.x+1][vecpos.y+1]
end

return influ
