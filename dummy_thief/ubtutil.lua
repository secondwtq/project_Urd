_ret = { }

_ret.findin = function (t, func)
	for k, v in pairs(t) do
		if func(v) then return v end
	end
	return nil
end

_ret.cmpint = function (x, y)
	local x_, y_ = math.floor(x), math.floor(y)
	return x_ == y_
end

_ret.distance = function (pos0, pos1)
	return math.max(math.abs(pos0[1]-pos1[1]), math.abs(pos0[2]-pos1[2]))
end

return _ret