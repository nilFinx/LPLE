local fs = require "fs"

local certype = "application/x-x509-ca-cert"
local mime = {
	css = "text/css",
	html = "text/html",

	cer = certype,
	pem = certype,
	p12 = "application/x-pkcs12",
	mobileconfig = "application/x-apple-aspen-config"
}

local nft = "Not found"
local nfl = nft:len()

local cache = {}
local function preload(filename)
	fs.readFile("static/"..filename, function(err, data)
		if err then
			print("Error loading "..filename)
			print(err)
			os.exit(1)
		end
		cache[filename] = data
	end)
end

local topreload = {
	"index.html", "cydia.css", "style.css"
}
for _, v in pairs(topreload) do preload(v) end

local function serve(req, res)
	req.path = req.path:gsub("http://.-/", "/"):gsub("%.%.", ""):gsub("//", "/")
	if req.path == "/" then
		req.path = "/index.html"
	end
	local f = cache[req.path:sub(2)]
	if not f then
		l:debug(req.path.." cache miss")
		f = fs.readFileSync("static"..req.path)
		if not f then
			f = fs.readFileSync("certs"..req.path)
			if not f then
				return {code = 404, {"Content-Length", nfl}}, nft
			end
		end
	end

	return {
		code = 200,
		{"Content-Type",  mime[req.path:match("%.(.-)$")] or "application/octet-stream"},
		{"Content-Length", tostring(f:len())}
	}, f
end

return {serve, function(req, res)
end}