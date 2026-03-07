local cn = require "coro-net"
local ss = require "secure-socket"
local tp = require "app.tlspeek"
local uvproxy = require "app.uvproxy"

local tlspeek = tp.peek
local tpconst = tp.const
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
		local ua = req["User-Agent"]
		l:info("CONNECT to %s:%s by %s (%s)",
			host, port,
			---@diagnostic disable-next-line: undefined-field
			cSocket:getpeername().ip,
			ua and ("UA: "..ua) or "No UA")
	end

	local read, write, sSocket = cn.connect({
		port = port,
		host = host,
		hostname = host,
		tls = true
	})
	if not (read and write and sSocket) then
		read, write, sSocket = cn.connect({
			port = port,
			host = host,
			hostname = host
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
		else
			cSocket:write("HTTP/1.1 200 Connection Established\r\n\r\n")
			uvproxy(cSocket, sSocket) return
		end
	end
	cSocket:write("HTTP/1.1 200 Connection Established\r\n\r\n")

	local buf, info, err, nhs = tlspeek(cSocket)
	if nhs then
		l:warning "Not a TLS handshake, going with direct proxy"
		sSocket:close_reset(function()
			read, write, sSocket = cn.connect({
				port = port,
				host = host,
				hostname = host
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
				cSocket:close_reset()
			else
				write(buf)
				uvproxy(cSocket, sSocket)
			end
		end)
		return
	end

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

	local c, k = GenCert((info and next(info.serverNames)) and info.serverNames or host)
	if not (c and k) then
		cSocket:close_reset()
		sSocket:close_reset()
	end


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

		requestCert = request_cert, -- another reminder to do this
		ciphers = X_CIPHERS
	})

	if not tSocket then
		l:error("Error when upgrading (usually client issue)")
		print("OpenSSL error: ", require "openssl".error())
		return
	end

	uvproxy(tSocket, sSocket)
end