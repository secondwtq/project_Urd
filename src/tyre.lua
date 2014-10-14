local vhere = require 'Vhere'
local vector2d = vhere.vector2d

local __tyre = { }

local function build_segment_bresenham(start_vec, end_vec)
	local ret = { }

	local delta = end_vec - start_vec
	local step = vector2d(1, 1)
	local cnext = vector2d(0, 0)

	local frac = 0
	local cur_step = 0

	if delta.x < 0 then step.x = -1 end
	if delta.y < 0 then step.y = -1 end
	cur_step = cur_step + 1

	delta = delta:apply(function (o) return math.abs(o*2) end)

	if (delta.y > delta.x) then
		frac = delta.x*2 - delta.y
		while cnext.y ~= end_vec.y do
			if frac >= 0 then
				cnext.x = cnext.x + step.x
				frac = frac - delta.y
			end
			cnext.y = cnext.y + step.y
			frac = frac + delta.x
			ret[cur_step] = cnext:copy()
			cur_step = cur_step + 1
		end
	else
		frac = delta.y*2 - delta.x
		while cnext.x ~= end_vec.x do
			if frac >= 0 then
				cnext.y = cnext.y + step.y
				frac = frac - delta.x
			end
			cnext.x = cnext.x + step.x
			frac = frac + delta.y
			ret[cur_step] = cnext:copy()
			cur_step = cur_step + 1
		end
	end

	return ret
end

local function smooth_8to4(path)
	local ret = { }

	local last = path[1]
	local cur = path[1]

	for i, v in ipairs(path) do
		cur = v

		local delta = cur - last

		if delta == vector2d(1, 1) then
			table.insert(ret, last+vector2d(0, 1))
		elseif delta == vector2d(-1, 1) then
			table.insert(ret, last+vector2d(-1, 0))
		elseif delta == vector2d(1, -1) then
			table.insert(ret, last+vector2d(0, -1))
		elseif delta == vector2d(-1, -1) then
			table.insert(ret, last+vector2d(-1, 0))
		end

		table.insert(ret, cur)

		last = cur
	end

	return ret
end

-- local_dir -> direction of local y
local function local_coord(local_pos, local_dir, target)
	local offset = target - local_pos
	local local_dir_nom = local_dir:nom()

	local theta_cos = vector2d(0, 1):angle_cos(local_dir_nom)
	local theta = math.acos(theta_cos)
	local theta_sin = math.sin(theta)

	-- print(offset:len(), local_dir:len())
	-- print(theta_sin, theta_cos)

	return vector2d(offset:dot(vector2d(local_dir_nom.y, -local_dir_nom.x)), offset:dot(local_dir_nom))
end

__tyre.build_segment_bresenham = build_segment_bresenham
__tyre.smooth_8to4 = smooth_8to4
__tyre.local_coord = local_coord

return __tyre