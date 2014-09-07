_ret = { }

_object = { }

_object.new = function (self, t)
	r = t or { }
	setmetatable(r, self)
	self.__index = self
	return r
end

_ret.object = _object

return _ret