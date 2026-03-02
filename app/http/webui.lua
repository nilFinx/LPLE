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

local index = fs.readFileSync("static/index.html")
if not index then
	l:error "static/index.html not found or could not be read"
	os.exit(1)
end

index = index:gsub("{CERT_PEM}", Config.cert)

local function serve(req, res)
	req.url = req.url:gsub("http://.-/", "/"):gsub("%.%.", ""):gsub("//", "/")
	local f
	if req.url == "/" then
		f = index
	end
	if not f then
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