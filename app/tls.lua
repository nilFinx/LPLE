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