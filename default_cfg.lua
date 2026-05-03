---@class config
local c = {
	---@type "none"|"error"|"warning"|"info"|"debug"
	log_level = "info",

	-- Also logs UA for HTTP, format is like DATE | [DEBUG]  | METHOD to HOST:IP by ClientIP (UA: User-Agent-Here)
	-- Fallback text is always `none`
	-- Note: around [DEBUG] has control characters, match by `| [A-Z] to` if you use regex
	log_ip = true,
	
	-- Timeout for the TLS connection in milliseconds. Only applies to CONNECT and DirectTCP.
	tls_timeout = 5000,

	certs = {
		-- relative to the working directory
		path = "certs",

		-- private key for signing stuff
		key = "key.pem",
		-- certificate of the CA itself
		cert = "cert.pem",
	},

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
			{"example.com", 443}
		}
	},

	---@alias ver "SSLv3"|"TLSv1"|"TLSv1.1"|"TLSv1.2"|"TLSv1.3"
	-- iPhoneOS/iOS
	--  3 TLSv1
	--  5.1 TLSv1.2
	-- Android
	-- fill me maybe

	-- TLS/SSL version limits. min is immediately applied, while max is always latest. When handshake ends and the client supports something above max, the pipe will be killed.
	secure = {
		-- Self explainatory, max tries for fail2ban before banning.
		fail2ban_max_tries = 10,
		
		-- Whitelist the IP until reboot when the client passed authentication
		fail2ban_whitelist_on_success = true,
		
		-- auth killswitch. Forces auth to be passed at all times.
		forcepass = false,
		
		---@type table<string>
		-- all usernames below will be allowed to connect, if the list isn't empty. ALL OTHER ACCOUNTS ARE BLOCKED.
		-- Format is ["username@server"] = true.
		-- {["username@server"]=true}, etc. Add a `,` in end of each one before the next, like:
		-- {
		-- 	"u@s",
		-- 	"au@s"
		-- }
		-- For XMPP, it is always username@example.com, but for mail, it could be username@example.com or username (not mail.example.com).
		username_whitelist = {
			-- "johndoe@example.com"
			-- "matrixsux"
			-- shittyim@
		},
		--- Pass auth when the at mark was detected on the username twice (the double at will be replaced with single at)
		username_doubleat_pass = false,
		
		tls = {
			---@type ver
			-- Cuts conection on clients below this version. Adjust if you want to go SSL.
			min = "TLSv1",

			---@type ver
			-- Max version. 
			max = "TLSv1.2",

			-- Private key length. For security, 4096 seems decent enough.
			key_length = 4096,

			-- If you don't know anything about this, don't even bother.
			-- Actually, in case your client hates the cert hash type, pick sha1 as the value. Very unrecommended though.
			hash_type = "sha256",

			-- Instead of max being a limit, use it to immediately pass auth
			pass_auth = true,

			-- Request a client certificate to be used
			request_cert = false,
		},
		mod = {
			http = {
				username = "lp",
				password = "LP_DEFAULT_PASSWORD",
				-- Don't verify username if given
				require_username = false,
				-- Ask for authentication on web UI or not
				webui_authenticate = true,
				-- HTTP1.1 or older = auth immediately
				httpver_auth = true,
				
				connect = {
					---@type table<string|integer>
					-- hosts/ports where MitM is not wanted, due to not being TLS, or other reasons
					nomitm = {
						-- 5222,
						-- "chat.disroot.org",
						-- "iamatoaster.protogen.hub.or.whatever:3926",
						-- other hosts/ports that are 100% not for TLS connections
						-- other hosts/ports where you somehow want MitM to be gone
					},
					
				}
			},
			directTCP = {
				-- Require HTTP auth to pass on the IP before it gets allowed, or the TLS version to match
				auth = true,
				
				---@type tabble<string>
				whitelisted = {
					-- "chat.disroot.org:5223"
				}
			}
		},
	},

	mod = {
		http = {
			enabled = true,

			webui = {
				enabled = true,
				
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
	},
}

return c