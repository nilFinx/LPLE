return function(cSocket, sSocket)
	sSocket:read_start(function(err, chunk)
		if err then
			l:error("Upstream error: "..err)
			cSocket:close_reset()
		elseif not chunk then
			cSocket:close()
		else
			cSocket:write(chunk)
		end
	end)
	cSocket:read_start(function(err, chunk)
		if err then
			l:error("Client error: "..err)
			sSocket:close_reset()
		elseif not chunk then
			sSocket:close()
		else
			sSocket:write(chunk)
		end
	end)
end