object = { }

_object = { }

_object.new = function (self, t)
	r = t or { }
	setmetatable(r, self)
	self.__index = self
	return r
end

object.object = _object

return object