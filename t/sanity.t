use Test::Nginx::Socket::Lua 'no_plan';
use Cwd qw(cwd);

my $pwd = cwd();

add_block_preprocessor(sub {
    my ($block) = @_;
    my $name = $block->name;

    if (!defined $block->error_log) {
        $block->set_value("no_error_log", "[error]");
    }

    if (!defined $block->request) {
        $block->set_value("request", 'GET /t');
    }

    my $http_config = $block->http_config // "";
    $http_config .= <<_EOC_;
    lua_package_path "$pwd/lib/?.lua;$pwd/t/lib/?.lua;;";
    lua_package_cpath "$pwd/?.so;;";
    init_by_lua_block {
        require "resty.core"
    }
_EOC_
    $block->set_value("http_config", $http_config);

    if (defined $block->lua) {
        my $lua = $block->lua;
        my $config = <<_EOC_;
        location = /t {
            content_by_lua_block {
                local function say_find(from, to)
                    if not from then
                        ngx.say(nil)
                    else
                        ngx.say(from, " ", to)
                    end
                end
                local lib = require "resty.boyer-moore"
                local bm_find = lib.bm_find
                local find = string.find
                --local bm_find = find
                $lua
            }
        }
_EOC_
        $block->set_value("config", $config);
    }

    $block;
});

check_accum_error_log();
no_long_string();
run_tests();

__DATA__

=== TEST 1: fuzzy
--- timeout: 5s
--- lua
local start = ngx.now()
while true do
    for _ = 1, 1000 do
        local size = math.random(100, 1024)
        local buf = table.new(size, 0)
        for i = 1, size do
            buf[i] = math.random(33, 126)
        end

        local pat = string.char(unpack(buf))

        local size = math.random(2048, 5000)
        local buf = table.new(size, 0)
        for i = 1, size do
            buf[i] = math.random(33, 126)
        end

        local s = string.char(unpack(buf))
        local out = bm_find(s, pat, 1)
        local exp = find(s, pat, 1, true)

        if out ~= exp then
            ngx.say("got: ", out, " exp: ", exp, " for s: ", s, ", pat: ", pat)
            return
        end
    end

    ngx.update_time()
    if ngx.now() - start > 3 then
        break
    end
end
ngx.say("ok")
--- response_body
ok



=== TEST 2: negative start
--- lua
local s = "abcabc"
say_find(bm_find(s, "abc", -2))
say_find(bm_find(s, "abc", -3))
say_find(bm_find(s, "abc", -999999999))
--- response_body
nil
4 6
1 3



=== TEST 3: positive start
--- lua
local s = "abcabc"
say_find(bm_find(s, "abc", 1))
say_find(bm_find(s, "abc", 3))
say_find(bm_find(s, "abc", 4))
say_find(bm_find(s, "abc", 5))
say_find(bm_find(s, "abc", 999999999))
--- response_body
1 3
4 6
4 6
nil
nil



=== TEST 4: not a number
--- lua
local s = "abcabc"
say_find(bm_find(s, "abc", nil))
say_find(bm_find(s, "abc"))
say_find(bm_find(s, "abc", "4"))

local ok = pcall(bm_find, s, "abc", "1e.2")
ngx.say(ok)
--- response_body
1 3
1 3
4 6
false



=== TEST 5: empty str
--- lua
local s = "abcabc"
say_find(bm_find(s, ""))
say_find(bm_find("", s))
say_find(bm_find("", ""))
--- response_body
1 0
nil
1 0
