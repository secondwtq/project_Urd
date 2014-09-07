_ret = { }

LCT = require 'lunacolort'

__Import = function (filename)
				io.write(LCT.c.GREEN .. "\nImporting file " .. LCT.c.CYAN .. filename .. LCT.c.GREEN .. " ..." .. LCT.c.RESET)
				dofile(filename)
				io.write(LCT.c.RED .. " succeeded.\n" .. LCT.c.RESET)
			end

__Require = function (modname)
				io.write(LCT.c.GREEN .. "\nImporting module " .. LCT.c.CYAN .. modname .. LCT.c.GREEN .. " ..." .. LCT.c.RESET)
				-- io.write(string.format("\nImporting module %s ...", modname))
				local _t = require(modname)
				io.write(LCT.c.RED .. " succeeded.\n" .. LCT.c.RESET)
				return _t
			end

_ret.Import, _ret.Require = __Import, __Require

return _ret