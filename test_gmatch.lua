str_test = '(1,2,3;)<0,1,2;1,2,3;>(1,2,3;)'

_thi_blocks = string.gmatch(str_test, '%<[%d,;]*%>')()

print(_thi_blocks)

for id, x, y in string.gmatch(_thi_blocks, '(%d+),(%d+),(%d+);') do
	print(id, x, y)
end