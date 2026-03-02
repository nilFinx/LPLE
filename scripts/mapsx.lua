-- Fixes Apple Maps. Thanks to MapsX teamfor original discovery!
-- Thanks to Pod (caffemacs) also known as Eric (Epixx512) for guiding me a bit.
local append = "&accessKey=1771263947_2253116135311925630_%2F_oCF9gr1p%2BmhfpmMi%2BafsBlyTJysoz%2Byp%2FHBCt5rbE00%3D"
local f = function(req, res, go)
	print(req.path)
	req.path = req.path..append
	print(req.path)
end

-- catch-if-domain-match.
return nil, {
	["gsp35.ls.apple.com"] = f,
	["gsp19-ms12.ls.apple.com"] = f,
	["gsp12-ms12.ls.apple.com"] = f,
	["gsp11.ls.apple.com"] = f,
	["gsp21.ls.apple.com"] = f
}