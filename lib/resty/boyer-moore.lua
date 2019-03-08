local tonumber = tonumber
local ffi = require "ffi"


local _M = { version = "0.8.0"}


local function load_shared_lib(so_name)
    local tried_paths = {}
    local i = 1

    for k, _ in package.cpath:gmatch("[^;]+") do
        local fpath = k:match("(.*/)")
        fpath = fpath .. so_name
        local f = io.open(fpath)
        if f ~= nil then
            io.close(f)
            return ffi.load(fpath)
        end
        tried_paths[i] = fpath
        i = i + 1
    end

    tried_paths[#tried_paths + 1] =
        'tried above paths but can not load ' .. so_name
    error(table.concat(tried_paths, '\n'))
end
local lib = load_shared_lib("librestyboyermoore.so")


ffi.cdef([[
typedef unsigned char uchar;
int bm_find(const uchar *haystack, int haystack_len,
            const uchar *needle, int needle_len, int start);
]])


function _M.bm_find(s, pat, start)
    if not start then
        start = 0
    else
        local typ = type(start)
        if typ ~= "number" then
            start = tonumber(start)
            if start == nil then
                error("bad argument #2 to 'find' (number expected, got "
                      .. typ .. ")")
            end
        end

        if start < 0 then
            start = #s + start
        else
            start = start - 1
        end

        if start < 0 then
            start = 0
        elseif start > #s then
            return nil
        end
    end

    local from = lib.bm_find(s, #s, pat, #pat, start)
    from = tonumber(from)
    if from == -2 then
        return nil, "no memory"
    end

    if from == -1 then
        return nil, "not found"
    end

    return from + 1, from + #pat
end


return _M
