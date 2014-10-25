lunacolort = { }

__available = false

if _URD_HOSTPLATFORM_ISPOSIX_ == true then __available = true end

__colors = { "BLACK", "RED", "GREEN", "YELLOW", "BLUE", "MAGENTA", "CYAN", "WHITE", "RESET" }

if __available then

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

else

__con = { }

for k, v in pairs(__colors) do __con[v] = "" end

end

lunacolort.c = __con
lunacolort.available = __available

return lunacolort