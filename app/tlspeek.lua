-- Inspired, and basically copied from Wowfunhappy's AquaProxy.
-- The comments are literally 1-to-1.

--[[
Copyright (c) 2024 Wowfunhappy
	2015 Keith Rarick

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
of the Software, and to permit persons to whom the Software is furnished to do
so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
]]

local bit = require "bit"
local wr = require "coro-channel".wrapRead

-- https://stackoverflow.com/a/65477617 by DarkWiiPlayer + Luatic
local function hex(str)
   return (str:gsub("%x%x", function(digits) return string.char(tonumber(digits, 16)) end))
end

local function str(hex)
	return (hex:gsub(".", function(char) return string.format("%02x", char:byte()) end))
end

-- Go int
local function int(hex)
	return tonumber(str(hex), 16)
end

local function at(str, index)
	return str:sub(index, index)
end

local const = {
	tlsHandshakeTypeClientHello		= 0x01,

	tlsExtensionServerName			= 0x0000,
	tlsExtensionALPN				= 0x0010,
	tlsExtensionSupportedVersions	= 0x002b,

	tlsVersion10 = 0x0301,
	tlsVersion11 = 0x0302,
	tlsVersion12 = 0x0303,
	tlsVersion13 = 0x0304
}

local function parseALPN(buf, info)
	if buf:len() < 2 then
		return
	end

	local protocolListLen = bit.bor(bit.lshift(int(at(buf, 1)), 8), int(at(buf, 2)))
	local pos = 3

	while pos < protocolListLen + 2 and pos < buf:len() do
		local protoLen = int(at(buf, pos))
		pos = pos + 1
		if pos + protoLen <= buf:len() then
			local proto = (buf:sub(pos, pos + protoLen - 1))
			table.insert(info.alpnProtocols, proto)

			if proto == "h2" then
				info.supportsHTTP2 = true
			end
		end

		pos = pos + protoLen
	end
end

local function parseSupportedVersions(buf, info)
	if buf:len() < 1 then
		return
	end

	-- For ClientHello, this is a list
	local listLen = int(at(buf, 1))
	local pos = 2

	local i = 1
	while i < listLen / 2 and pos + 2 <= buf:len() do
		local version = bit.bor(bit.lshift(int(at(buf , pos)), 8), int(at(buf, pos + 1)))
		if version == const.tlsVersion13 then
			info.supportsTLS13 = true
		end
		info.tlsVersions[version] = true
		pos = pos + 2
		i = i + 1
	end
end

local function parseServerName(buf, info)
	if buf:len() < 1 then
		return
	end

	local listLen = int(buf:sub(1, 2))
	local snType = int(at(buf, 3))
	if snType ~= 0 then return end
	local pos = 4

	while pos < listLen + 3 and pos < buf:len() do
		local snLen = int(buf:sub(pos, pos + 1))
		pos = pos + 2
		if pos + snLen <= buf:len() then
			local sn = (buf:sub(pos, pos + snLen - 1))
			table.insert(info.serverNames, sn)
		end

		pos = pos + snLen
	end
end

---@param info info
---@return string?
local function parseExtensions(buf, info)
	local pos = 1

	while pos + 4 <= buf:len() do
		local extType = bit.bor(bit.lshift(int(at(buf , pos)), 8), int(at(buf, pos + 1)))
		local extLen = bit.bor(bit.lshift(int(at(buf, pos + 2)), 8), int(at(buf, pos + 3)))
		pos = pos + 4

		if pos + extLen - 1 > buf:len() then
			return "truncated extension"
		end

		local extData = buf:sub(pos, pos + extLen)

		if extType == const.tlsExtensionALPN then
			parseALPN(extData, info)
		elseif extType == const.tlsExtensionSupportedVersions then
			parseSupportedVersions(extData, info)
		elseif extType == const.tlsExtensionServerName then
			parseServerName(extData, info)
		end

		pos = pos + extLen
	end

	return nil
end

---@return string buffer
---@return info?
---@return string? err
---@return boolean notHS
local function tlspeek(socket)
	---@class info
	local info = {
		supportsTLS13 = false,
		supportsHTTP2 = false,
		---@type table<integer, boolean>
		tlsVersions = {},
		serverNames = {},
		alpnProtocols = {}
	}
	socket:read_stop()
	local buf = wr(socket)()
	if not buf then return "", nil, "no data received", false end
	local len = buf:len()

	local _, err, nhs = pcall(function()
		-- Minimum size check: 5 bytes for TLS record header + 4 bytes for handshake header
		if len < 9 then
			return "data too short to be ClientHello", true
		end

		-- Check TLS record header
		if at(buf, 1) ~= hex("16") then -- Handshake record type
			return "not a TLS handshake record", true
		end

		-- Skip TLS version from record header (backwards compatibility version)

		-- Get record length
		local recordLen = bit.bor(bit.lshift(int(at(buf, 4)), 8), int(at(buf, 5)))
		if len < recordLen + 5 then
			return "incomplete TLS record", true
		end

		-- Parse handshake message

		local pos = 6
		if int(at(buf, pos)) ~= const.tlsHandshakeTypeClientHello then
			return "not a ClientHello message", true
		end

		-- Skip handshake length (3 bytes...?)
		pos = pos + 4

		if len < pos + 2 then
			return "truncated ClientHello"
		end

		info.tlsVersion = bit.bor(bit.lshift(int(at(buf , pos)), 8), int(at(buf, pos + 1)))
		pos = pos + 2

		-- Skip client random (32 bytes)
		pos = pos + 32

		-- Skip session ID
		if len < pos + 1 then
			return "truncated ClientHello at session ID"
		end
		local sessionIDLen = int(at(buf, pos))
		pos = pos + sessionIDLen + 1

		-- Skip cipher suites
		if len < pos + 2 then
			return "truncated ClientHello at cipher suites"
		end
		local cipherSuitesLen = bit.bor(bit.lshift(int(at(buf, pos)), 8), int(at(buf, pos + 1)))
		pos = pos + cipherSuitesLen + 2

		-- Skip compression methods
		if len < pos + 1 then
			return "truncated ClientHello at compression"
		end
		local compressionLen = int(at(buf, pos))
		pos = pos + compressionLen + 1

		if len > pos + 2 then
			local extensionsLen = bit.bor(bit.lshift(int(at(buf, pos)), 8), int(at(buf, pos + 1)))
			pos = pos + 2

			if len >= pos + extensionsLen - 1 then
				local err = parseExtensions(buf:sub(pos, pos + extensionsLen), info)
				if err then
					return err
				end
			end
		end

		info.isModernClient = info.supportsTLS13 or info.supportsHTTP2
	end)
	if err then return buf, nil, err, nhs or false end

	return buf, info, nil, false
end

return {
	peek = tlspeek,
	const = const
}