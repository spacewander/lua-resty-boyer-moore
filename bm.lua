#!/usr/bin/env resty


require "resty.core"
local lib = require "lib.resty.boyer-moore"
local bm_find = lib.bm_find
local find = string.find
local t = {}
local N = 1e4
for i = 1, N do
    local size = math.random(100, 1024)
    local buf = table.new(size, 0)
    for i = 1, size do
        buf[i] = math.random(33, 126)
    end

    local pat = string.char(unpack(buf))

    local size = math.random(2000, 5000)
    local buf = table.new(size, 0)
    for i = 1, size do
        buf[i] = math.random(33, 126)
    end

    local s = string.char(unpack(buf))
    s = s:rep(10)
    t[i] = {s, pat}
end

local start = ngx.now()
for i = 1, 1e1 do
    for i = 1, N do
        --assert(bm_find(t[i][1], t[i][2]) == find(t[i][1], t[i][2], 1, true))
        bm_find(t[i][1], t[i][2])
        --find(t[i][1], t[i][2], 1, true)
    end
end

ngx.update_time()
ngx.say(ngx.now() - start)
ngx.say("ok")
