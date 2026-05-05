-- dats your ip

---@param req ch-request
---@param body string
---@param go gofunction
---@param socket uv_tcp_t
---@return coro-http.alias.response
---@return string? body
return {nil, {["datsnotyourip.totally.real"] = function(req, body, go, socket)
	local resp = ("Your IP: %s\nThe request body: %s\n"):format(
		socket:getpeername().ip,
		(not body or body == "" and "none" or body)
	)
	return {code = 200, {"Doing", "your mom lol"}, {"Content-Length", resp:len()}}, resp
end}}