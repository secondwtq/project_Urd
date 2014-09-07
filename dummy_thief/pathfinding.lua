_ret = { }

pkgutil = require 'ubtpkgutil'
pkgutil.Import('Defs.lua')

open = { }
close = { }

node = {
	[0] = nil,
	-- cell = nil,
	father = nil,
	G = 0, H = 0, F = 0,
	InsideOpen = true,
	Passable = false,
}
node.__index = node

pf_status = {
	map = nil,
	_dest = nil,
	_father = nil,
}

father = nil

function node.new(cell)
	local u = { }
	-- for k, v in pairs(node) do u[k] = v end
	setmetatable(u, node)
	u[0] = cell
	if (cell ~= nil) then u.Passable = cell:ispassable() end
	return u
end

function get_H(src, destCell)
	-- return math.ceil(math.sqrt(x*x+y*y))
	return math.abs(src.pos[1] - destCell.pos[1])+math.abs(src.pos[2] - destCell.pos[2])
	-- return (math.abs(src.pos[1] - destCell.pos[1]) + math.abs(src.pos[2] - destCell.pos[2]))
end

function printTable(tb)
	for k, v in ipairs(tb) do print(k, v) end
end

function InsideOpen(cell)
	if cell.InsideOpen == false then return nil end
	for k, v in pairs(open) do
		if ((v[0].pos[1] == cell[0].pos[1]) and (v[0].pos[2] == cell[0].pos[2])) then return v end
	end
	return nil
end

function InsideClose(cell)
	for k, v in pairs(close) do
		if ((v[0].pos[1] == cell[0].pos[1]) and (v[0].pos[2] == cell[0].pos[2])) then return v end
	end
	return nil
end

function find_rec()
	local dest = pf_status._dest
	local map = pf_status.map
	local father = father
	local ti, nn, mg, ip = table.insert, node.new, map.getneighborcell, ipairs

	local _childNodes = { true, true, true, true }
	local openNode = nn()
	local childNodes = { nil, nil, nil, nil }
	local better = false
	local closeNode = nil

	while father[0].pos[1] ~= dest.pos[1] or father[0].pos[2] ~= dest.pos[2] do
		ti(close, father)

		_childNodes[1] = nn(father[0].cell_left)
		_childNodes[2] = nn(father[0].cell_right)
		_childNodes[3] = nn(father[0].cell_up)
		_childNodes[4] = nn(father[0].cell_down)
		childNodes = { }
		for k, v in ip(_childNodes) do if v.Passable then ti(childNodes, v) end end

		for k, node in ip(childNodes) do
			closeNode = nil
			for k, v in ip(close) do
				if ((v[0].pos[1] == node[0].pos[1]) and (v[0].pos[2] == node[0].pos[2])) then closeNode = v break end
			end

			if closeNode == nil then
				better = false
				node.G = father.G+1
				node.H = math.abs(node[0].pos[1] - dest.pos[1])+math.abs(node[0].pos[2] - dest.pos[2])
				node.F = node.G+node.H

				openNode = InsideOpen(node)
				if openNode == nil then
					ti(open, node)
					better = true
				elseif node.G < openNode.G then better = true
				else better = false end
				if better then node.father = father end
			end
		end
		father.InsideOpen = false

		father = open[1]
		for k, v in ip(open) do
			if v.InsideOpen and father.InsideOpen == false then father = v break end
		end
		for k, v in ip(open) do
			if v.InsideOpen and v.F < father.F then father = v end
		end
	end
	table.insert(close, father)
end

function find(src, dest)
	close = { }
	open = { }
	if src:ispassable() and dest:ispassable() then
		local srcNode = node.new(src, nil)
		srcNode.H = get_H(srcNode[0], dest)
		srcNode.F = srcNode.G+srcNode.H
		table.insert(open, srcNode)
		pf_status._dest = dest
		father = srcNode
		find_rec()
		local c = InsideClose(node.new(dest))
		while c.father ~= nil do
			c[0]:setonpath()
			c = c.father
		end
	end
end

function pf_init(map)
	pf_status.map = map
end

_ret.find = find
_ret.pf_init = pf_init
_ret.pf_status = pf_status

return _ret