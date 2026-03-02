_G.LuaRequire = _G.require
_G.require = require

require "string-extensions"
require "util"

_G.fs = require "fs"

_G.cfg = require "default_cfg"
if fs.existsSync "cfg.lua" then
    if not pcall(function() require "cfg" end) then
        print "cfg.lua failed to load"
        os.exit(1)
    end
    cfg = table.patch(_G.cfg, require "cfg")
end

_G.l = require "logger" (cfg.log_level)

local stack = {}
_G.LogStarted = function(name, type, port)
    if not stack[name] then stack[name] = {} end
    table.insert(stack[name], {port = port, type = type})
end

require "app.cert"

require "app.http"

for name, tbl in pairs(stack) do
    local t = name.." proxy started ("
    for i, tbl2 in pairs(tbl) do
        if i ~= 1 then
            t = t .. ", "
        end
        t = t .. tbl2.type .. ": " .. tostring(tbl2.port)
    end
    l:info(t..")")
end
