-- Keeping for later? Maybe this will remain unused forever. PR not welcome.
--local D_CIPHERS = require "deps.tls.common".DEFAULT_CIPHERS

-- Credit to AquaProxy
X_CIPHERS =
	"RC4-SHA:"..
	"DES-CBC3-SHA:"..
	"AES128-SHA:"..
	"AES256-SHA:"..
	"ECDHE-ECDSA-RC4-SHA:"..
	"ECDHE-ECDSA-AES128-SHA:"..
	"ECDHE-RSA-DES-CBC3-SHA:" ..
	"ECDHE-RSA-AES128-SHA:"..
	"ECDHE-RSA-AES256-SHA"..
	"@SECLEVEL=0" -- Allow TLSv1.1, 1.0, etc

-- 0.3, 1.0, 1.1, 1.2, 1.3
-- Expects SSLv3, TLSv1.3, etc
function Ver2Num(ver)
	if ver:sub(1,4) == "TLSv" then
		return tonumber(ver:sub(5))
	else -- SSL
		return tonumber("0."..ver:sub(5))
	end
end

local minver = Ver2Num((Config.secure.tls.min))
local maxver = Ver2Num((Config.secure.tls.max))

---@param v number 0.3, 1.0 ~ 1.3
---@return boolean fail
---@return "L"|"H"? reason L=lower than expected, H=higher than expected
function CheckVer(v)
	if v < minver then
		return true, "L"
	end
	if v > maxver then
		return true, "H"
	end
	return false
end
