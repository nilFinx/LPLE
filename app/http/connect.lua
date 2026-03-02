
local tls = require "tls"

-- Keeping for later
--local D_CIPHERS = require "deps.tls.common".DEFAULT_CIPHERS

local minver, maxver = Ver2Num(Config.secure.tls.min), Ver2Num((Config.secure.tls.min))

local errs = {
	EAI_NONAME = {404, "Cannot resolve host"},
	ECONNREFUSED = {503, "Connection refused"},
}

---@param req luvit.http.IncomingMessage
---@param res luvit.http.ServerResponse
return function(req, res)
	local authpass = false
	if req.socket.ssl then
		if Ver2Num(req.socket.ssl:get("version")) <= maxver then
			authpass = true
		end
	end
	if not authpass then
		authpass = HTTPAuth(req)
	end
	local host, port = req.url:match("([^:]+):?(%d*)")
	port = tonumber(port) or 443

	---@type luvit.net.Socket
	local cSocket = req.socket
	local addr = cSocket:address()

	if Config.log_ip then
		l:debug("CONNECT to %s:%s by %s (UA: %s)",
			host, port,
			addr and addr.ip or "none",
			req.headers["User-Agent"] or "none")
	end

	cSocket:removeAllListeners()

	local sSocket sSocket = tls.connect({
		port = port,
		host = host,
		hostname = host
	}, function(skibidi)
		cSocket:write("HTTP/1.1 200 Connection Established\r\n\r\n")

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

		local c, k = GenCert(host)

		local opt = {
			ca = Cert,
			server = true,
			cert = c,
			key = k,

			hostname = host,
			host = host,
			servername = host,

			requestCert = Config.secure.request_cert,
			ciphers = X_CIPHERS..""
		}

		local tSocket tSocket = tls.TLSSocket:new(cSocket, opt)
		---@diagnostic disable-next-line: param-type-mismatch
		tSocket:on('secureConnection', function()
			if not authpass then
				local v = Ver2Num(tSocket.ssl:get("version"))
				if v < minver then -- How did we even get here?
					l:debug "Cutting connection, got lower version than allowed"
					tSocket:destroy()
					sSocket:destroy()
					return
				end
				if v > maxver then
					if not HTTPAuth(req) then
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
	end)

	sSocket:on('end', function()
		cSocket:shutdown()
	end)
	cSocket:on('end', function()
		sSocket:shutdown()
	end)

	sSocket:on("error", function(err)
		l:error("Upstream error: "..(err or "No error..."))
		res.statusCode = errs[err] and errs[err][1] or 404
		-- Something custom. Maybe pushed by the time you see this.
		---@diagnostic disable-next-line: inject-field
		res.statusReason = errs[err] and errs[err][2] or nil
		res:finish()
		cSocket:destroy()
	end)
	cSocket:on("error", function(err)
		l:error("Client error: "..(err or "No error...")) p(err)
		print(debug.traceback())
		sSocket:destroy()
	end)
end