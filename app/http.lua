local ch = require "coro-http"
local fs = require "fs"
---@diagnostic disable-next-line: undefined-field
local btoa = require "base64".decode

local ports = Config.ports.http
local mod_secure = Config.secure.mod.http
local mod = Config.mod.http

local webui, wus, whtest
local authpls = "Please authenticate :)"
local authplsl = tostring(authpls:len())
if mod.webui then
	webui, wus = (table.unpack or unpack)(require "app.http.webui")

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

-- 0.3, 1.0, 1.1, 1.2, 1.3
function Ver2Num(ver)
	if ver:sub(1,4) == "TLSv" then
		return tonumber(ver:sub(5))
	else -- SSL
		return tonumber("0."..ver:sub(5))
	end
end
local maxver = Ver2Num((Config.secure.tls.max))

local function haw(req, socket)
	if socket.ssl then
		if Ver2Num(req.socket.ssl:get("version")) <= maxver then
			return true
		end
	end
	if mod_secure.password then
		local a = req["Proxy-Authorization"] or req["Authorization"]
		if a then
			if a:sub(1, 6) == "Basic " then
				local u, p = btoa(a:sub(7)):match("^([^:]*):?(.+)$")
				if u == "" then
					if mod_secure.require_username then
						l:debug "Auth fail: No username but server requires it" return false
					end
				elseif u ~= mod_secure.username then
					if Config.secure.username_whitelist[u] then
						return true
					else
						l:debug "Auth fail: Wrong and not whitelisted username" return false
					end
				end
				if p == mod_secure.password then
					return true
				else
					l:debug "Auth fail: Wrong password" return false
				end
			end
		else
			l:debug "Auth fail: No authorization header" return
		end
	end

	l:debug "Auth fail: Unspecified" return false
end
function HTTPAuth(req, socket)
	local ip = socket:getpeername().ip
	if AllowedIPs[ip] then return true end
	if haw(req, socket) then
		RemoveIP(ip) return true
	else
		AddIP(ip) return false
	end
end

local plainproxy = require "app.http.plain"
local connectproxy = require "app.http.connect"

local authb = "Please authenticate :)\r\n"
local auth_webui = {
	code = 401,
	{"WWW-Authenticate", mod.webui.realm and "Basic realm=\""..mod.webui.realm.."\"" or "Basic"},
	{"Content-Length", authb:len()}
}
local auth_proxy = {
	code = 407,
	{"Proxy-Authenticate", "Basic"},
	{"Content-Lenghth", authb:len()}
}

local nob = Config.mod.http.forbidden_response
local noh = {code = 200}
if nob then
	nob = nob.."r\n"
	noh = {
		code = 200,
		{"Content-Type", "text/plain"},
		{"Content-Length", nob:len()}
	}
end

local issb = "Internal Server Error\r\n"
local issh = {
	code = 500,
	{"Content-Length", issb:len()}
}

local head_metatable = {
	__index = function(t, k)
		local ct = rawget(t, "_cache")
		if not ct then
			ct = {}
			rawset(t, "_cache", ct)
		end
		local c = ct[k]
		if c then return c end
		for _, t in pairs(t) do
			if type(t) == "table" and t[1] == k then
				return t[2]
			end
		end
	end
}

---@return table headers
---@return string? body
local function onReq(req, body, socket)
	setmetatable(req, head_metatable)
	local ip = socket:getpeername().ip
	if BannedIPs[ip] then
		return noh, nob
	end
	local suc, a, b = xpcall(function()
		if req.method == "CONNECT" then
			if not HTTPAuth(req, socket) then
				return auth_proxy, authb
			end
			if wus and whtest(req.path:match("^([^:]+)")) then
				return wus(req)
			end
			return connectproxy(req, socket)
		else
			if req.path:sub(1, 7) == "http://" then -- This can never be HTTPS
				if not HTTPAuth(req, socket) then
					return auth_proxy, authb
				end
				if webui and whtest(req.path:sub(8):match("^(.-)/")) then
					if mod_secure.webui_authenticate then
						if not HTTPAuth(req, socket) then
							return auth_webui, authb
						end
					end
					return webui(req)
				end
				return plainproxy(req, body)
			else
				if req.path:sub(1, 1) ~= "/" or not (webui and mod.webui.proxyless) then
					return noh, nob
				else
					if mod_secure.webui_authenticate then
						if not HTTPAuth(req, socket) then
							return auth_webui, authb
						end
					end
					return webui(req)
				end
			end
		end
	end, function(err)
        return debug.traceback(err, 1)
	end)
	if not suc then
		l:error(a)
		return issh, issb
	end
	---@diagnostic disable-next-line: return-type-mismatch
	return a, b
end

if ports.plain then
	ch.createServer("0.0.0.0", ports.plain, onReq)
	LogStarted("HTTP", "plain", ports.plain)
end

if ports.secure then
	--TODO: remove diag
---@diagnostic disable-next-line: redundant-parameter
	ch.createServer("0.0.0.0", ports.secure, onReq, {key = Key, cert = Cert, server = true})
	LogStarted("HTTP", "secure", ports.secure)
end
