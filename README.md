# Name

lua-resty-boyer-moore - An implementation of [Boyer–Moore string-search algorithm](https://en.wikipedia.org/wiki/Boyer%E2%80%93Moore_string-search_algorithm) in LuaJIT

Build status: [![Travis](https://travis-ci.org/spacewander/lua-resty-boyer-moore.svg?branch=master)](https://travis-ci.org/spacewander/lua-resty-boyer-moore)

## MUST READ

* Because the preprocession of the good suffix rule is expensive, it is disabled
by default. If your case benefits from it (for example, there are many repeated
sub-patterns), you could enable it via `make CC="$(CC) -DBM_GOOD_SUFFIX_ENABLED"`.
* To benefit from the Boyer-Moore algorithm, both the pattern and the search
string need to be large enough. For instance, pattern in one hundred bytes and
search string in thousands of bytes. If your pattern is monotonous,
like searching DNA sequence, the Boyer-Moore version could be over 50% faster
than `string.find`. But in the most situations, `string.find` is faster.
You need to benchmark it with your data.

## Synopsis

```lua
local boyer_moore = require "resty.boyer-moore"
local pat = "0123"

local from, to = boyer_moore.bm_find("01450123", pat)
if not from then
    ngx.say(to)
else
    ngx.say(from)
    ngx.say(to)
end
```

For more examples, read the `t/sanity.t`.

## Installation

Run `make`. Then copy the `librestyboyermoore.so` to one of your `lua_package_cpath`.
Yes, this library uses a trick to load the shared object from cpath instead of system shared library path.
Finally, add the `$pwd/lib` to your `lua_package_path`.

[Back to TOC](#table-of-contents)

## Functions

### bm_find
`syntax: from, to|err = bm_find(s, pat[, init])`

This function should work as the same as the LuaJIT's `string.find` function.
Unlike `string.find`, you don't need to pass `true` as the fourth argument.

There is another difference that this function returns `nil, "not found"` when
we could not find the `pat` in the given `s`, and `nil, "no memory"` when there is no enough memory to
preprocess good suffix rule (if enabled). Note that good suffix rule is disabled by default,
see the [Must Read](#must-read) section for more info.
