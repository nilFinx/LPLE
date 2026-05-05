-- Fixes GravityBox activation. Likely legal as GravityBox Unlocker on Play Store is completely free now.
local lu = require "ext.lua-url"
local json = require "json"

---@param req ch-request
---@return coro-http.alias.response
---@return string? body
return {nil, {["gravitybox.ceco.sk.eu.org"] = function(req, body)
	if req.path == "/service.php" then
		if not body or body == "" then
			local resp = "Invalid request"
			return {code = 400, {"Content-Length", resp:len()}}, resp
		end
		local q = lu.parseArgs(body)
		-- Has to be caps for some reason.
		if q and q.transactionId and string.upper(q.transactionId) == "YES" then
			---@type string
			---@diagnostic disable-next-line: assign-type-mismatch
			local resp = json.encode({
				message = "henlo :3",
				status = "OK",
				-- TRANSACTION_VALID, TRANSACTION_INVALID, TRANSACTION_VIOLATION, TRANSACTION_BLOCKED
				trans_status = "TRANSACTION_VALID"
			})
			return {
				code = 400,
				{"Content-Type", "application/json"},
				{"Content-Length", resp:len()}
			}, resp
		else
			---@type string
			---@diagnostic disable-next-line: assign-type-mismatch
			local resp = json.encode({
				message = "henlo :3",
				status = "OK",
				trans_status = "TRANSACTION_INVALID"
			})
			return {
				code = 400,
				{"Content-Type", "application/json"},
				{"Content-Length", resp:len()}
			}, resp
		end
	else
		local resp = "404 Not Found"
		return {code = 404, {"Content-Length", resp:len()}}, resp
	end
end}}