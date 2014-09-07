_ret = { }

__con = {
	BLACK  = string.char(0x1B) .. "[30m",
	RED  = string.char(0x1B) .. "[31m",
	GREEN = string.char(0x1B) .. "[32m",
	YELLOW = string.char(0x1B) .. "[33m",
	BLUE = string.char(0x1B) .. "[34m",
	MAGENTA = string.char(0x1B) .. "[35m",
	CYAN = string.char(0x1B) .. "[36m",
	WHITE = string.char(0x1B) .. "[37m",
	RESET = string.char(0x1B) .. "[0m",
}

_ret.c = __con

return _ret