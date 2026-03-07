---@class config
local c = {
	---@type "none"|"error"|"warning"|"info"|"debug"
	log_level = "info",

	-- Also logs UA for HTTP, format is like DATE | [DEBUG]  | CONNECT to HOST:IP by ClientIP (UA: User-Agent-Here)
	-- Fallback text is always `none`
	-- Note: around [DEBUG] has control characters, match by `CONNECT to` if you use reges
	log_ip = true, -- TODO for standard HTTP and also possibly others

	-- Everything sits in certs dir
	key = "key.pem",
	cert = "cert.pem",

	---@type table<string,table<string,integer|false>>
	-- set any to false to disable
	ports = {
		http = {
			plain = 51531,
			secure = 51532
		},
		imap = { -- TODO
			starttls = 51533,
			secure = 51534
		},
		smtp = { -- TODO
			starttls = 51535,
			secure = 51536,
		},
		xmpp = { -- TODO
			starttls = 51537,
			secure = 51538
		},
		directTCP = {
			--{"_xmpps-client._tcp.disroot.org", 51541} -- SRV record first, A record second
			--{"disroot.org", 51542} -- Always A record
		}
	},

	---@alias ver "SSLv3"|"TLSv1"|"TLSv1.1"|"TLSv1.2"|"TLSv1.3"
	-- iPhoneOS/iOS
	--  3 TLSv1
	--  5.1? TLSv1.2
	-- Android
	-- fill me maybe

	-- TLS/SSL version limits. min is immediately applied, while max is always latest. When handshake ends and the client supports something above max, the pipe will be killed.
	secure = {
		fail2ban_max_tries = 10,
		tls = {
			---@type ver
			-- min always cuts conection
			min = "TLSv1",

			---@type ver
			max = "TLSv1.2",

			key_length = 4096,

			-- Instead of being a limit, use it to immediately pass auth
			pass_auth = true,

			-- Request a client certificate to be used
			-- TODO
			request_cert = false,
		},
		mod = {
			http = {
				username = "lp",
				password = nil,
				-- Verify username if given, don't otherwise
				require_username = false,
				-- Ask for authentication on web UI or not
				webui_authenticate = true,
				-- HTTP1.1 or older = auth immediately
				httpver_auth = true
			},
			directTCP = {
				-- Require HTTP auth to pass on the IP before it gets allowed
				auth = true,
			}
		},

		---@type table<string>
		-- all usernames below will be allowed to connect, if the list isn't empty. ALL OTHER ACCOUNTS ARE BLOCKED.
		-- Format is ["username@server"] = true.
		-- {["username@server"]=true}, etc. Add a `,` in end of each one before the next, like:
		-- {
		-- 	["u@s"] = true,
		-- 	["au@s"] = true
		-- }
		-- For XMPP, it is always username@example.com, but for mail, it could be username@example.com or username (not mail.example.com).
		username_whitelist = {
			--["johndoe@example.com"] = true,
			--["zechfelms-whatsapp-user-somehow-fuck-them"] = true,
			--["matrixsux"] = true
		}
	},

	mod = {
		http = {
			enabled = true,

			-- Set http.webui or http.webui.hosts to nil to disable
			webui = {
				-- Body of when your request gets denied (either proxyless or fail2ban)
				forbidden_response = "403 Forbidden",

				---@type table<string>
				hosts = {
					"lp.r.e.a.l",
					"lp.real.com",
					"liquidproxy.r.e.a.l"
				},

				realm = "admin",

				-- Allow www.<any of the hosts> because fuck world wide web
				www_host = true,

				-- Allow connection by hitting ip:port, not a specified webUI host through proxy
				proxyless = false
			},
		},
		directTCP = {
			enabled = true,
		}
	},
}

return c