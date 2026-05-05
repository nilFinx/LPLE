local uverrs = require "app.uverrs"

local ch = require "coro-http"

local bpb = "Bad protocol"
local bph = {
	code = 400,
	{"Content-Length", tostring(bpb:len())}
}

-- Tiny request wrapper
---@class gofunction
local function go(req, body)
	local headers = {}

	for k, h in pairs(req) do
		if type(k) == "number" then
			table.insert(headers, {h[1], h[2]})
		end
	end

	local suc, res, body = pcall(ch.request, req.method, req.path, headers, body, {
		followRedirects = false
	})

	if suc then
		return res, body
	else
		---@diagnostic disable-next-line: undefined-field
		return {code = 502, errored_out = true, {"Content-Length", res:len()}}, res
	end
end

---@param socket uv_tcp_t
return function (req, body, socket)
	local proto = req.path:match("^(%S+)://")
	--TODO: websocket
	if proto ~= "ws" and proto ~= "http" then
		return bph, bpb
	end

	local match = HTTPMatches[req.path:match("http://([^/]+)/")]
	if not match then
		l:debug("Plain proxy to "..req.path)
		return go(req, body)
	else
		l:debug("Plain proxy intercepted by a script to "..req.path)
		req.path = req.path:match("http://[^/]+(/.+)$")
		return match(req, body, go, socket)
	end
end