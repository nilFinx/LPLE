local cn = require "coro-net"
local ss = require "secure-socket"
local tp = require "app.tlspeek"
local uvproxy = require "app.uvproxy"

local tlspeek = tp.peek
local tpconst = tp.const
local maxver = Ver2Num((Config.secure.tls.max))
local tp_max
if maxver == 0.3 then
	tp_max = tpconst.tlsVersion10 - 1 -- NOT RECOMMENDED
else
	tp_max = tpconst["tlsVersion"..tostring(maxver):gsub("%.", "")]
end

local function server(host, port)
	cn.createServer({
		port = port
	},
	---@param cSocket uv_tcp_t
	function(read, write, cSocket)
		local suc, a, b = xpcall(function()
			if Config.log_ip then
				l:info("DIRECTTCP to %s:%s by %s",
					host, port,
					---@diagnostic disable-next-line: undefined-field
					cSocket:getpeername().ip
				)
			end
		
			local read, write, sSocket = cn.connect({
				port = port,
				host = host,
				hostname = host,
				tls = true,
				timeout = Config.tls_timeout
			})
			if not (read and write and sSocket) then
				read, write, sSocket = cn.connect({ -- Won't work unless the server refuses.
					port = port,
					host = host,
					hostname = host
				})
				if not (read and write and sSocket) then
					local e = errs[write]
					l:error("Error connecting to server non-TLS: "..(e and ("%s (%s)"):format(e[2], write) or write))
					cSocket:close_reset()
				else
					uvproxy(cSocket, sSocket)
				end
				return
			end
		
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
						l:error("Error connecting to server non-TLS: "..(e and ("%s (%s)"):format(e[2], write) or write))
						cSocket:close_reset()
					else
						uvproxy(cSocket, sSocket)
					end
					return
				end)
			end
		
			if err then
				l:warning("Failed to read handshake ("..err..")")
			end
			RemoveIP(cSocket:getpeername().ip)
		
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
		
				initialData = buf,
		
				hostname = host,
				host = host,
				servername = host,
		
				requestCert = request_cert, -- another reminder to do this
				ciphers = X_CIPHERS
			})
		
			if not tSocket then
				l:error("Error when upgrading (usually client issue)\nOpenSSL error: "..(require "openssl".error() or ""))
				return
			end
		
			l:debug("Properly connected to "..host)
		
			uvproxy(tSocket, sSocket)
		end, function(err)
			return debug.traceback(err, 1)
		end)
		if not suc then
			l:error("DirectTCP error: "..(a or "no error??"))
			return issh, issb
		end
	end)
end

for _, t in pairs(Config.ports.directTCP) do
	local host, port = t[1], t[2]
	server(host, port)
	LogStarted("DirectTCP", host, port)
end
