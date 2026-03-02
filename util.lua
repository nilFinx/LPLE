One = {
    minute = 60,
    hour = 60 * 60
}
function UnixEpoch()
---@diagnostic disable-next-line: param-type-mismatch
    return os.time(os.date("!*t"))
end

local function table_patch(table, patches)
    for k, v in pairs(patches) do
        if type(table[k]) == "table" then
            if (not next(table)) or #table ~= 0 then
                table[k] = v
            else
                table_patch(table[k], patches[k])
            end
        else
            table[k] = v
        end
    end
    return table
end

table.patch = table_patch

function table.v2k(t)
	local new = {}
	for k, v in pairs(t) do
		new[v] = k
	end
	return new
end

function table.has(t, v)
    for _, w in pairs(t) do
        if v == w then
            return true
        end
    end
end

function table.keyof(t, v)
    for k, w in pairs(t) do
        if v == w then
            return k
        end
    end
    return nil
end

function table.indexof(t, v)
    for i, _, w in ipairs(t) do
        if v == w then
            return i
        end
    end
    return nil
end

function table.keylist(t)
    local u = {}
    for k in pairs(t) do
        table.insert(u, k)
    end
    return u
end

-- True if one value from left table exists as a value in right table
function table.hasleftinright(t,u)
    for _, v in pairs(t) do
        for _, w in pairs(u) do
            if v == w then
                return true
            end
        end
    end
    return false
end

-- Properly clones table in first argument, and returns it. Always deep.
function table.clone(tbl)
    local t = {}
    for k, v in pairs(tbl) do
        local v = v
        if type(v) == "table" then
            v = table.clone(v)
        end
        t[k] = v
    end
    return t
end
