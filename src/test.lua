tyre = require 'tyre'
vhere = require 'Vhere'

function test_tyre_bresen()
	a = vhere.vector2d(0, 0)
	b = vhere.vector2d(5, -5)

	c = tyre.build_segment_bresenham(a, b)

	for k, v in pairs(c) do
		print(k, v:str())
	end
end

test_tyre_bresen()