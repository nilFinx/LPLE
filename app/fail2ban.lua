local leaderboard = {}
---@type table<string,boolean>
BannedIPs = {}

local max_allowed = Config.secure.fail2ban_max_tries

function AddIP(ip)
	local lip = leaderboard[ip]
	leaderboard[ip] = lip and lip + 1 or 1
	if (lip or 1) >= max_allowed - 1 then
		BannedIPs[ip] = true
	end
end

-- auth pass
function RemoveIP(ip)
	leaderboard[ip] = nil
end