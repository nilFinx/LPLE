---@type luvit.http
local http = require "http"
local fs = require "fs"
---@diagnostic disable-next-line: undefined-field
local btoa = require "base64".decode

local ports = Config.ports.http
local mod_secure = Config.secure.mod.http
local mod = Config.mod.http

local webui, wus, whtest, plsauth
local authpls = "Please authenticate :)"
local authplsl = tostring(authpls:len())
if mod.webui then
	webui, wus = (table.unpack or unpack)(require "app.http.webui")
	function plsauth(res)
		res.statusCode = 407
		res:setHeader("Proxy-Authenticate", "Basic")
		res:setHeader("Content-Length", authplsl)
		res:setHeader("Proxy-Connection", "Keep-Alive")
		res:finish(authpls)
	end

	local wuih = mod.webui.hosts
	function whtest(url)
		if wuih then
			if table.has(wuih, url) then return true end
			if url:sub(1, 4) == "www." then
				if table.has(wuih, url:sub(5)) then return true end
			end
		end
		return false
	end
end

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

function Ver2Num(ver)
	if ver:sub(1,4) == "TLSv" then
		return tonumber(ver:sub(5))
	else -- SSL
		return tonumber("0."..ver:sub(5))
	end
end
local maxver = Ver2Num((Config.secure.tls.max))

---@param req luvit.http.IncomingMessage
-- false means they haven't tried to authenticate at all, so you shouldn't fail2ban on it
function HTTPAuth(req)
	local ip = req.socket:address().ip
	if req.socket.ssl then
		if Ver2Num(req.socket.ssl:get("version")) <= maxver then
			RemoveIP(ip) return true
		end
	end
	if mod_secure.password then
		local a = req.headers["Proxy-Authorization"] or req.headers["Authorization"]
		if a then
			if a:sub(1, 6) == "Basic " then
				local u, p = btoa(a:sub(7)):match("^([^:]*):?(.+)$")
				if u == "" then
					if mod_secure.require_username then
						AddIP(ip) return false
					end
				elseif u ~= mod_secure.username then
					if Config.secure.username_whitelist[u] then
						RemoveIP(ip) return true
					else
						AddIP(ip) return false
					end
				end
				if p == mod_secure.password then
					RemoveIP(ip) return true
				end
			end
		end
	end

	AddIP(ip) return false
end

local plainproxy = require "app.http.plain"
local connectproxy = require "app.http.connect"


local fb = Config.mod.http.forbidden_response
local fbl = tostring(fb and fb:len() or nil)

local function no(res)
	res.statusCode = 403
	if fb then res:setHeader("Content-Length", fbl) end
	res:finish(fb)
end

local function plsauthnorm(res)
	res.statusCode = 401
	res:setHeader("WWW-Authenticate", "Basic realm=\""..mod.webui.realm.."\"")
	res:setHeader("Content-Length", authplsl)
	res:setHeader("Connection", "Keep-Alive")
	res:finish(authpls)
end

---@param req luvit.http.IncomingMessage
---@param res luvit.http.ServerResponse
local function onReq(req, res)
	local ip = req.socket:address().ip
	if BannedIPs[ip] then
		no(res) return
	end
	local suc, err = xpcall(function()
		if req.method == "CONNECT" then
			if not HTTPAuth(req) then
				plsauth(res) return
			end
			if wus and whtest(req.url:match("^([^:]+)")) then
				wus(req, res) return
			end
			connectproxy(req, res)
		else
			if req.url:sub(1, 7) == "http://" then -- This can never be HTTPS
				if not HTTPAuth(req) then
					plsauth(res) return
				end
				if webui and whtest(req.url:sub(8):match("^(.-)/")) then
					if mod_secure.webui_authenticate then
						if not HTTPAuth(req) then
							plsauthnorm(res) return
						end
					end
					webui(req, res) return
				end
				plainproxy(req, res)
			else
				if req.url:sub(1, 1) ~= "/" or not (webui and mod.webui.proxyless) then
					no(res)
				else
					if mod_secure.webui_authenticate then
						if not HTTPAuth(req) then
							plsauthnorm(res) return
						end
					end
					webui(req, res) return
				end
			end
		end
	end, function(err)
		res.statusCode = 500
		local ISS = "Internal server error"
		res:setHeader("Content-Length", tostring(ISS:len()))
		res:finish(ISS)
        return debug.traceback(err, 1)
	end)
	if not suc then
		l:error(err)
	end
end

local function onConn(socket)
	return http.handleConnection(socket, onReq)
end

if ports.plain then
	require "net".createServer(onConn)
		:listen(ports.plain)
	LogStarted("HTTP", "plain", ports.plain)
end

if ports.secure then
	require "tls".createServer({key = Key, cert = Cert}, onConn)
		:listen(ports.secure)
	LogStarted("HTTP", "secure", ports.secure)
end
