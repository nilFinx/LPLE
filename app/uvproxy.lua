local gc = collectgarbage

local rs = function(s1, s2)
	s1:read_start(function(err, chunk)
		if err then
			l:error("Upstream error: "..err)
			s2:close_reset()
		elseif not chunk then
			s2:shutdown(function()
				s2:close()
				gc()
			end)
		else
			s2:write(chunk)
		end
	end)
end

return function(s1, s2)
	rs(s1, s2) rs(s2, s1)
end