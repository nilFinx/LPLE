---@class config
local c = {
    ---@type "none"|"error"|"warning"|"info"|"debug"
    log_level = "info",

    -- Also logs UA for HTTP, format is like DATE | [DEBUG]  | CONNECT to HOST:IP by ClientIP (UA: User-Agent-Here)
    -- Fallback text is always `none`
    -- Note: around [DEBUG] has control characters, match by `CONNECT to` if you use reges
    log_ip = true,

    -- Everything sits in certs dir
    key = "key.pem",
    cert = "cert.pem",

    timeout = 10000, -- ms, not guaranteed to be enforced everywhere

    host = nil,
    -- nil any of this to disable
    ports = {
        http = {
            plain = 51531,
            secure = 51532
        },
        imap = {
            starttls = 51533,
            secure = 51534
        },
        smtp = {
            starttls = 51535,
            secure = 51536,
        },
        xmpp = {
            starttls = 51537,
            secure = 51538
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
        ---@type ver
        -- min always cuts conection
        min = "TLSv1",

        ---@type ver
        max = "TLSv1.2",

        -- Instead of being a limit, use it to immediately pass auth
        pass_auth = true,
    },

    http = {
        https = true,

        -- allow connection to local hosts
        allow_local = false,

        -- "Temporary failure" and stuff on error
        expose_error = true,

        webui = {
            -- Body of when your request gets denied (either proxyless or fail2ban)
            forbidden_response = "403 Forbidden",

            ---@type table<string>
            -- Set to nil to disable web UI
            hosts = {
                "lp.r.e.a.l",
                "liquidproxy.r.e.a.l"
            },

            -- Allow connection by hitting ip:port, not a specified webUI host through proxy
            proxyless = false
        },
    }
}

return c