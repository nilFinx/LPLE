local uverrs = require "app.uverrs"

---@type luvit.http
local http = require "http"

local url = require "ext.lua-url"

local connections = {}

return function (req, res)
	local proto = req.url:match("^(%S+)://")
	if proto ~= "ws" and proto ~= "http" then
		res.statusCode = 400
		local rs = "Bad protocol"
		res:setHeader("Content-Length", tostring(#rs))
		res:finish(rs)
		return
	end
	local dom, port = req.url:match("://(%S+):?(%d)*/")
	local path = req.url:match("://%S+(/.+)$")
	local opts = {
		headers = req.headers,
		host = dom,
		method = req.method,
		path = path,
		port = port or 80
	}

	local c = http.request(opts, function(cres)
		res.headers = cres.headers
		res.statusCode = cres.statusCode
		cres:pipe(res)
	end)

	c:done()
	local suc = true
	local rs = "hi"
	if suc then
		---@diagnostic disable-next-line: param-type-mismatch
		--[[for k, v in pairs(rs) do
			if tonumber(k) then
				res.headers[k] = v
			else
				res[k] = v
			end
		end
		p(req)
		local c = r:get("Connection")
		if c then
			--res:
		end
		res:finish(body)]]
	else
		res.statusCode = 502
		local et = "LiquidProxy: "..(uverrs[rs] or rs).."\r\n"
		res:setHeader("Content-Type", "text/plain")
		res:setHeader("Content-Length", tostring(et:len()))
		res:finish(et)
	end
end