-- TODO: Make TLS better again by reading the client hello, and make it optional
local tls = require "tls"
local wrap = require "app.wrap"

-- Keeping for later
--local D_CIPHERS = require "deps.tls.common".DEFAULT_CIPHERS

local maxver = Ver2Num((Config.secure.tls.min))

local errs = {
	EAI_NONAME = {404, "Cannot resolve host"},
	ECONNREFUSED = {502, "Connection refused"},
	ETIMEDOUT = {504, "Timed out"}
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

	local c, k = GenCert(host)

	if not (c and k) then
		l:error("Could not generate key for "..(host or "EMPTY HOST? WTF??"))
		res.statusCode = 500
		res:finish() return
	end

	cSocket:removeAllListeners()

	local sSocket sSocket = tls.connect({
		port = port,
		host = host,
		hostname = host
	}, function()
		cSocket:write("HTTP/1.1 200 Connection Established\r\n\r\n")

		wrap(host, sSocket, cSocket, authpass, HTTPAuth, req)
	end)

	sSocket:on('end', function()
		cSocket:shutdown()
	end)
	cSocket:on('end', function()
		sSocket:shutdown()
	end)

	sSocket:on("error", function(err)
		l:error("Upstream error: "..(err or "No error..."))
		local e = errs[err]
		res.statusCode = e and e[1] or 404
		-- Something custom. Maybe pushed by the time you see this.
		---@diagnostic disable-next-line: inject-field
		res.statusMessage = e and e[2] or nil
		res:finish()
		cSocket:destroy()
	end)
	cSocket:on("error", function(err)
		l:error("Client error: "..(err or "No error..."))
		print(debug.traceback())
		sSocket:destroy()
	end)
end