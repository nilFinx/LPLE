-- TODO: Make TLS better again by reading the client hello, and make it optional

local cn = require "coro-net"
local tls = require "tls"
local wrap = require "app.wrap"
local tlspeek = require "app.tlspeek"
local ss = require "secure-socket"

local gc = collectgarbage
local request_cert = Config.secure.request_cer
local maxver = Ver2Num((Config.secure.tls.min))

-- Keeping for later
--local D_CIPHERS = require "deps.tls.common".DEFAULT_CIPHERS

local errs = {
	EAI_NONAME = {404, "Cannot resolve host"},
	ECONNREFUSED = {502, "Connection refused"},
	ETIMEDOUT = {504, "Timed out"}
}

errs.EAI_NODATA = errs.EAI_NONAME

for _, t in pairs(errs) do
	t[3] = tostring(t[2]:len())
end

local issb = "Internal Server Error\r\n"
local issh = {
	code = 500,
	{"Content-Length", issb:len()}
}

---@param cSocket uv_tcp_t
return function(req, cSocket, cread, cwrite)
	local authpass = false
	--[[if cSocket.ssl then
		if Ver2Num(cSocket.ssl:get("version")) <= maxver then
			authpass = true
		end
	end]]
	if not authpass then
		authpass = HTTPAuth(req, cSocket)
	end
	local host, port = req.path:match("([^:]+):?(%d*)")
	port = tonumber(port) or 443

	if Config.log_ip then
		l:info("CONNECT to %s:%s by %s (UA: %s)",
			host, port,
			---@diagnostic disable-next-line: undefined-field
			(cSocket.socket or cSocket):getpeername().ip,
			req["User-Agent"] or "none")
	end

	local c, k = GenCert(host)
	if not (c and k) then
		return issh, issb
	end

	local read, write, sSocket = cn.connect({
		port = port,
		host = host,
		hostname = host,
		tls = true
	})
	if not (read and write and sSocket) then
		local e = errs[write]
		l:error("Error connecting to server: "..(e and ("%s (%s)"):format(e[2], write) or write))
		if e then
			return {
				code = e[1],
				reason = e[2],
				{"Content-Length", errs[3]}
			}, e[2]
		end
		return issh, issb
	end
	cSocket:write("HTTP/1.1 200 Connection Established\r\n\r\n")

	local buf = tlspeek(cSocket)

	l:debug "client handshake start"
	---@type uv_tcp_t
	local tSocket = ss(cSocket, {
		ca = Cert,
		cert = c:export(), -- I have zero clue on why this is needed
		key = k:export(), -- But I do it because I apparently have to
		server = true,

		buffer = buf,

		hostname = host,
		host = host,
		servername = host,

		requestCert = request_cert,
	})

	if not tSocket then
		l:error("Error when upgrading (usually client issue)")
		print("OpenSSL error: ", require "openssl".error())
		return
	end
	l:debug "successful TLS handshake"

	sSocket:read_start(function(err, chunk)
		if err then
			l:error("Upstream error: "..err)
			tSocket:close_reset()
		elseif not chunk then
			tSocket:close()
		else
			tSocket:write(chunk)
		end
	end)
	tSocket:read_start(function(err, chunk)
		if err then
			l:error("Client error: "..err)
			sSocket:close_reset()
		elseif not chunk then
			sSocket:close()
		else
			sSocket:write(chunk)
		end
	end)
end