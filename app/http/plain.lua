local uverrs = require "app.uverrs"

local ch = require "coro-http"

local bpb = "Bad protocol"
local bph = {
	code = 400,
	{"Content-Length", tostring(bpb:len())}
}

-- Tiny request wrapper
local function go(req)
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

return function (req, body)
	local proto = req.path:match("^(%S+)://")
	--TODO: websocket
	if proto ~= "ws" and proto ~= "http" then
		return bph, bpb
	end

	if not HTTPMatches[req.path:match("http://([^/]+)/")] then
		return go(req)
	end
end