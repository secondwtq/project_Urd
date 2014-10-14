tyre = require 'tyre'
vhere = require 'Vhere'

function test_tyre_bresen()
	local a = vhere.vector2d(0, 0)
	local b = vhere.vector2d(5, -5)

	local c = tyre.build_segment_bresenham(a, b)

	for k, v in pairs(c) do
		print(k, v:str())
	end

	return c
end

function test_tyre_smooth84()

	local a = vhere.vector2d(0, 0)
	local b = vhere.vector2d(5, -5)

	local c = tyre.build_segment_bresenham(a, b)
	local d = tyre.smooth_8to4(c)

	for k, v in pairs(d) do
		print(k, v:str())
	end
end

function test_tyre_local_coord()

	local pos_1 = vhere.vector2d(2, 2)
	local dir_1 = vhere.vector2d(1, 1)
	local target_1 = vhere.vector2d(3, 2)
	print(tyre.local_coord(pos_1, dir_1, target_1):str())

	pos_1 = vhere.vector2d(2, 2)
	dir_1 = vhere.vector2d(1, 0)
	target_1 = vhere.vector2d(3, 1)
	print(tyre.local_coord(pos_1, dir_1, target_1):str())

end

test_tyre_bresen()
test_tyre_smooth84()
test_tyre_local_coord()