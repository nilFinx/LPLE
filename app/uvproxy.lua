return function(cSocket, sSocket)
	sSocket:read_start(function(err, chunk)
		if err then
			l:error("Upstream error: "..err)
			cSocket:close_reset()
		elseif not chunk then
			cSocket:shutdown()
		else
			cSocket:write(chunk)
		end
	end)
	cSocket:read_start(function(err, chunk)
		if err then
			l:error("Client error: "..err)
			sSocket:close_reset()
		elseif not chunk then
			sSocket:shutdown()
		else
			sSocket:write(chunk)
		end
	end)
end