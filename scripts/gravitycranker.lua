-- Fixes GravityBox activation. Likely legal as GravityBox Unlocker on Play Store is completely free now.
local lu = require "ext.lua-url"
local json = require "json"

---@param req luvit.http.IncomingMessage
---@param res luvit.http.ServerResponse
return nil, {["gravitybox.ceco.sk.eu.org"] = function(req, res)
	if req.url == "/service.php" then
		local body = ""
		req:on('data', function (chunk)
			body = body .. chunk
		end)
		req:on("end", function()
			if not (body and body ~= "") then
				res.statusCode = 400
			end
			local q = lu.parseArgs(body)
			-- Has to be caps for some reason.
			if q and q.transactionId and string.upper(q.transactionId) == "YES" then
				res.statusCode = 200
				res:setHeader("Content-Type", "application/json")
				---@diagnostic disable-next-line: param-type-mismatch
				res:finish(json.encode({
					message = "henlo :3",
					status = "OK",
					-- TRANSACTION_VALID, TRANSACTION_INVALID, TRANSACTION_VIOLATION, TRANSACTION_BLOCKED
					trans_status = "TRANSACTION_VALID"
				}))
			else
				res.statusCode = 400
				res:setHeader("Content-Type", "application/json")
				---@diagnostic disable-next-line: param-type-mismatch
				res:finish(json.encode({
					message = "henlo :3",
					status = "OK",
					trans_status = "TRANSACTION_INVALID"
				}))
			end
		end)
	else
		res.statusCode = 404
	end
	return true
end}
