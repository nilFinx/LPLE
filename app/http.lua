---@type luvit.http
local http = require "http"

---@param req luvit.http.IncomingMessage
function HTTPAuth(req)
	if cfg.http.auth then
		local a = req.headers["Proxy-Authentication"] or req.headers["Authentication"]
		if a then
			p(a)
		end
	end

	return false
end

function Ver2Num(ver)
	if ver:sub(1,4) == "TLSv" then
		return tonumber(ver:sub(5))
	else -- SSL
		return tonumber("0."..ver:sub(5))
	end
end

local webui, wus
if cfg.http.webui and cfg.http.webui.hosts then
	local webui, wus = (table.unpack or unpack)(require "app.http.webui")
end
local plainproxy = require "app.http.plain"
local connectproxy = require "app.http.connect"

HTTPCatchAlls = {}
HTTPMatches = {}
local hmfn = {}

if fs.existsSync "scripts" then
	for _, file in pairs(fs.readdirSync "scripts") do
		if file:find("%.lua$") then
			local func, rules = require("scripts."..file:match("(.+)%.lua"))
			if func then table.insert(HTTPCatchAlls, func) end
			for host, func in pairs(rules or {}) do
				if hmfn[host] then
					l:error("%s conflicts with rule in %s and %s", host, hmfn[host], file)
					os.exit(1)
				else
					HTTPMatches[host] = func
					hmfn[host] = file
				end
			end
		end
	end
end

---@param req luvit.http.IncomingMessage
---@param res luvit.http.ServerResponse
local function onReq(req, res)
	local suc, err = xpcall(function()
		if req.method == "CONNECT" then
			if wus and table.has(cfg.http.webui.hosts, req.url:match("(.-):443")) then
				wus(req, res) return
			end
			connectproxy(req, res)
		else
			if req.url:sub(1, 7) == "http://" then -- This can never be HTTPS
				if webui and table.has(cfg.http.webui.hosts, req.url:sub(8):match("(.-)/")) then
					webui(req, res) return
				end
				plainproxy(req, res)
			else
				if req.url:sub(1, 1) ~= "/" or not (webui and cfg.http.webui.proxyless) then
					res.statusCode = 403
					res:finish(cfg.http.webui.forbidden_response)
				else
					webui(req, res) return
				end
			end
		end
	end, function(err)
        return debug.traceback(err, 1)
	end)
	if not suc then
		l:error(err)
	end
end

local function onConn(socket)
	return http.handleConnection(socket, onReq)
end

local ps = cfg.ports.http

if ps.plain then
	require "net".createServer(onConn)
		:listen(ps.plain, cfg.host)
	LogStarted("HTTP", "plain", ps.plain)
end

if ps.secure then
	require "tls".createServer({key = Key, cert = Cert}, onConn)
		:listen(ps.secure, cfg.host)
	LogStarted("HTTP", "secure", ps.secure)
end
