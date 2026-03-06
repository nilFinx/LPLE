local wr = require "coro-channel".wrapRead

---@param socket uv_tcp_t
local function tlspeek(socket)
	socket:read_stop()

	local r = wr(socket)

	local buf = r()
	return buf
end

return tlspeek