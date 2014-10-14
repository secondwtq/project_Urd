local __vhere = { }

-- local vector_2d_meta = { }

local vector_2d_table = {
	x = 0,
	y = 0
}

local function vector2d(x, y)
	local ret = { }
	setmetatable(ret, vector_2d_table)
	ret.x, ret.y = x, y
	return ret
end

function vector_2d_table.__add(op1, op2)
	if type(op1) == 'table' and type(op2) == 'table' then
		return vector2d(op1.x+op2.x, op1.y+op2.y)
	end
end

function vector_2d_table.__sub(op1, op2)
	if type(op1) == 'table' and type(op2) == 'table' then
		return vector2d(op1.x-op2.x, op1.y-op2.y)
	end
end

function vector_2d_table.__mul(op1, op2)
	if type(op1) == 'table' and type(op2) == 'table' then
		return vector2d(op1.x*op2.x, op1.y*op2.y)
	elseif type(op2) == 'number' then
		return vector2d(op1.x*op2, op1.y*op2)
	end
end

function vector_2d_table.__div(op1, op2)
	if type(op1) == 'table' and type(op2) == 'number' then
		return vector2d(op1.x/op2+op1.y/op2)
	end
end

function vector_2d_table.__eq(op1, op2)
	if type(op1) == 'table' and type(op2) == 'table' then
		return (op1.x == op2.x and op1.y == op2.y)
	end
end

function vector_2d_table.__unm(op)
	return op * -1
end

function vector_2d_table.__index(table, key)
	if key == 1 then return table.x
	elseif key == 2 then return table.y
	elseif vector_2d_table[key] ~= nil then return vector_2d_table[key]
	else return nil end
end

function vector_2d_table.__newindex(table, key, value)
	if key == 1 then table.x = value
	elseif key == 2 then table.y = value
	else rawset(table, key, value)
	end
end

function vector_2d_table.__len(op)
	return 2
end

function vector_2d_table:dot(op)
	if type(op2) == 'table' then
		return self.x*op2.x+self.y*op2.y
	elseif type(op2) == 'number' then
		return vector2d(self.x*op2, self.y*op2)
	end
end

function vector_2d_table:len()
	return math.sqrt(math.pow(self.x, 2)+math.pow(self.y, 2))
end

function vector_2d_table:str()
	return '<' .. tostring(self.x) .. ', ' .. tostring(self.y) .. '>'
end

function vector_2d_table:apply(foo)
	return vector2d(foo(self.x), foo(self.y))
end

function vector_2d_table:copy()
	return vector2d(self.x, self.y)
end

-- setmetatable(vector_2d_table, vector_2d_meta)

__vhere.vector2d = vector2d

return __vhere