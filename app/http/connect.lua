local cn = require "coro-net"
local ss = require "secure-socket"
local tp = require "app.tlspeek"
local uprox = require "app.uvproxy"

local tlspeek = tp.peek
local tpconst = tp.const
local gc = collectgarbage
local request_cert = Config.secure.request_cer
local maxver = Ver2Num((Config.secure.tls.max))
local tp_max
if maxver == 0.3 then
	tp_max = tpconst.tlsVersion10 - 1 -- NOT RECOMMENDED
else
	tp_max = tpconst["tlsVersion"..tostring(maxver):gsub("%.", "")]
end

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
	local authpass = HTTPAuth(req, cSocket)
	local host, port = req.path:match("([^:]+):?(%d*)")
	port = tonumber(port) or 443

	if Config.log_ip then
		l:info("CONNECT to %s:%s by %s (UA: %s)",
			host, port,
			---@diagnostic disable-next-line: undefined-field
			cSocket:getpeername().ip,
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

	local buf, info, err = tlspeek(cSocket)

	if err then
		l:warning("Failed to read handshake ("..err..")")
	end
	if not authpass then
		if info then
			if Config.secure.mod.http.httpver_auth and not info.supportsHTTP2 then
				authpass = true
			elseif Config.secure.tls.pass_auth and not (info.tlsVersion == tp_max or info.tlsVersions[tp_max]) then
				authpass = true
			end
		end
	end
	if not authpass then
		---@diagnostic disable-next-line: undefined-field
		l:info("Post-connect auth failed ("..cSocket:getpeername().ip..")")
		cSocket:close_reset()
		sSocket:close_reset()
	end

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

	uprox(tSocket, sSocket)
	gc()
end