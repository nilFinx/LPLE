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
	req.url = req.url:gsub("http://.-/", "/"):gsub("%.%.", ""):gsub("//", "/")
	if req.url == "/" then
		req.url = "/index.html"
	end
	local f = cache[req.url:sub(2)]
	if not f then
		l:debug(req.url.." cache miss")
		f = fs.readFileSync("static"..req.url)
		if not f then
			f = fs.readFileSync("certs"..req.url)
			if not f then
				res.statusCode = 404
				res:setHeader("Content-Length", nfl)
				res:finish(nft)
				return
			end
		end
	end

	res.statusCode = 200
	res:setHeader("Content-Type", mime[req.url:match("%.(.-)$") or "application/octet-stream"])
	res:finish(f)
end

return {serve, function(req, res)
end}