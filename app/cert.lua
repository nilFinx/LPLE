Key = fs.readFileSync("certs/"..cfg.key)
Cert = fs.readFileSync("certs/"..cfg.cert)

if not (Key and Cert) then l:error "Certificate or key file not found" os.exit(1) end

local openssl = require "openssl"
local x509 = openssl.x509

local ca = assert(x509.read(Cert))
local cakey = assert(openssl.pkey.read(Key, true))

-- TODO: Implement caches
local ccache = {}

-- Inspired from https://github.com/zhaozg/lua-openssl/issues/208. Thanks xdays!
-- Bilal(bilalzero) + Nameless(truemedian) also helped me on it.
-- TODO: A mess. Try to reduce the mess. Please.
function GenCert(names)
	if type(names) == "string" then names = {names} end

	local now = UnixEpoch()-One.hour
	local ckey = assert(openssl.pkey.new("rsa", 2048))

	local name = openssl.x509.name.new {{CN=names[1]}}

	local hosts, ips = {}, {}
	for _, v in pairs(names) do
		if v:match("^[0-9.]+$") then
			table.insert(ips, v)
		else
			table.insert(hosts, v)
		end
	end
	local w = ""
	if #ips > 0 then
		w = w .. "IP:"..table.concat(ips, ",IP:")
	end
	if #hosts > 0 then
		w = w .. "DNS:"..table.concat(hosts, ",DNS:")
	end
	local san = {
		object = "subjectAltName",
		value = w
	}

	local req = x509.req.new(name, ckey)
	req:extensions({x509.extension.new_extension(san)})
	req:public(ckey)

	req:sign(ckey, "sha256")

	local c = req:to_x509(ckey, 1)
	c:subject(name)
	c:validat(now, now + 24 * One.hour)
	c:extensions({x509.extension.new_extension(san)})

	c:sign(cakey, ca, "sha256")

	return c:export(), ckey
end