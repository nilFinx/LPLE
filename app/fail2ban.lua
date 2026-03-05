local leaderboard = {}
---@type table<string,boolean>
BannedIPs = {}

local max_allowed = Config.secure.fail2ban_max_tries

function AddIP(ip, req)
	local lip = leaderboard[ip]
	leaderboard[ip] = lip and lip + 1 or 1
	l:info(ip.." failed auth")
	if (lip or 1) >= max_allowed - 1 then
		BannedIPs[ip] = true
		l:info("Banned %s for failing fail2ban", ip)
		if req and Config.log_level == "debug" then
			l:debug("Headers:")
			p(req.headers)
		end
	end
end

-- auth pass
function RemoveIP(ip)
	leaderboard[ip] = nil
end