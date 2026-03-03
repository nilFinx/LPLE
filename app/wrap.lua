local tls = require "tls"

-- Keeping for later
--local D_CIPHERS = require "deps.tls.common".DEFAULT_CIPHERS

local minver, maxver = Ver2Num(Config.secure.tls.min), Ver2Num((Config.secure.tls.min))

local request_cert = Config.secure.request_cert

-- Credit to AquaProxy
local X_CIPHERS =
	"RC4-SHA:"..
	"DES-CBC3-SHA:"..
	"AES128-SHA:"..
	"AES256-SHA:"..
	"ECDHE-ECDSA-RC4-SHA:"..
	"ECDHE-ECDSA-AES128-SHA:"..
	"ECDHE-RSA-DES-CBC3-SHA:" ..
	"ECDHE-RSA-AES128-SHA:"..
	"ECDHE-RSA-AES256-SHA"

---@param host string
---@param sSocket luvit.tls.TLSSocket
---@param socket luvit.net.Socket
---@param authpass boolean
---@param pcAuth function
---@param pcAuthArg any
local function wrap(host, sSocket, socket, authpass, pcAuth, pcAuthArg)
	local c, k = GenCert(host)

	local opt = {
		ca = Cert,
		server = true,
		cert = c,
		key = k,

		hostname = host,
		host = host,
		servername = host,

		requestCert = request_cert,
		ciphers = X_CIPHERS..""
	}

	local tSocket tSocket = tls.TLSSocket:new(socket, opt)
	---@diagnostic disable-next-line: param-type-mismatch
	tSocket:on('secureConnection', function()
		if not authpass then
			local v = Ver2Num(tSocket.ssl:get("version"))
			if v < minver then
				l:debug "Cutting connection, got lower version than allowed"
				tSocket:destroy()
				sSocket:destroy()
				return
			end
			if v > maxver then
				if not (pcAuth or function() end)(pcAuthArg) then
					l:debug "Cutting connection, failed post-serverconn auth"
					tSocket:destroy()
					sSocket:destroy()
					return
				end
			end
		end
		tSocket:pipe(sSocket) sSocket:pipe(tSocket)
	end)
	tSocket:on('error',function(err)
		l:error("Error when upgrading (usually client issue): "..err)
		print("OpenSSL error: ", require "openssl".error())
	end)
	return tSocket
end

return wrap