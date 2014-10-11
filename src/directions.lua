directions = { }

Directions = {
	Up = 'B',
	Down = 'N',
	Left = 'X',
	Right = 'D',
	Still = 'T',
	Unknown = "blablabla",
}

directions.Directions = Directions

function directions.get_direction(pos1, pos2)
	if pos1.x == pos2.x then
		if pos1.y == pos2.y then
			do return Directions.Still end
		elseif pos1.y > pos2.y then
			do return Directions.Up end
		elseif pos1.y < pos2.y then
			do return Directions.Down end
		end
	elseif pos1.x > pos2.x then
		if pos1.y == pos2.y then
			do return Directions.Left end
		elseif pos1.y > pos2.y then
			do return Directions.Unknown end
		elseif pos1.y < pos2.y then
			do return Directions.Unknown end
		end
	elseif pos1.x < pos2.x then
		if pos1.y == pos2.y then
			do return Directions.Right end
		elseif pos1.y > pos2.y then
			do return Directions.Unknown end
		elseif pos1.y < pos2.y then
			do return Directions.Unknown end
		end
	end
end

function directions.get_primary_direction(pos1, pos2)
	if pos1 == 0 and pos2 == 0 then return Directions.Still end

	if pos1 >= 0 and pos2 >= 0 then
		if pos1 > pos2 then return Directions.Right
		else return Directions.Down end
	end
	if pos1 <= 0 and pos2 >= 0 then
		if (-pos1) > pos2 then return Directions.Left
		else return Directions.Down end
	end
	if pos1 >= 0 and pos2 <= 0 then
		if pos1 > (-pos2) then return Directions.Right
		else return Directions.Up end
	end
	if pos1 <= 0 and pos2 <= 0 then
		if (-pos1) > (-pos2) then return Directions.Left
		else return Directions.Up end
	end
end

Direction_To_Vector = { }

Direction_To_Vector[Directions.Left] = { -1, 0 }
Direction_To_Vector[Directions.Right] = { 1, 0 }
Direction_To_Vector[Directions.Up] = { 0, -1 }
Direction_To_Vector[Directions.Down] = { 0, 1 }
Direction_To_Vector[Directions.Still] = { 0, 0 }

directions.Direction_To_Vector = Direction_To_Vector

function directions.from_dir_to_vec(dir)
	return Direction_To_Vector[dir]
end

function directions.from_vec_to_dir(vec)
	if vec[1] == 0 and vec[2] == 0 then return Directions.Still
	elseif vec[1] == 1 and vec[2] == 0 then return Directions.Right
	elseif vec[1] == -1 and vec[2] == 0 then return Directions.Left
	elseif vec[1] == 0 and vec[2] == -1 then return Directions.Up
	elseif vec[1] == 0 and vec[2] == 1 then return Directions.Down end
end

DirectionRelative = {
	Same = 0,
	Opposite = 1,
	Left = 2,
	Right = 3,
}

directions.DirectionRelative = DirectionRelative

function directions.abs_to_rel(dir1, dir2)
	if dir1 == dir2 then return DirectionRelative.Same end

	local vec_dir1 = directions.from_dir_to_vec(dir1)
	local vec_dir2 = directions.from_dir_to_vec(dir2)

	if vec_dir1[1] == -vec_dir2[1] and vec_dir1[2] == -vec_dir2[2] then return DirectionRelative.Opposite end

	if dir1 == Directions.Up then
		if dir2 == Directions.Left then return DirectionRelative.Left
		elseif dir2 == Directions.Right then return DirectionRelative.Right end
	end

	if dir1 == Directions.Down then
		if dir2 == Directions.Left then return DirectionRelative.Right
		elseif dir2 == Directions.Right then return DirectionRelative.Left end
	end

	if dir1 == Directions.Left then
		if dir2 == Directions.Down then return DirectionRelative.Left
		elseif dir2 == Directions.Up then return DirectionRelative.Right end
	end

	if dir1 == Directions.Right then
		if dir2 == Directions.Down then return DirectionRelative.Right
		elseif dir2 == Directions.Up then return DirectionRelative.Left end
	end
end

return directions