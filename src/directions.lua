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

return directions