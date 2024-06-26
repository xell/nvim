local tools = {}

function tools.hello()
    print("hello")
end

-- sub_utf8() -- {{{
-- https://blog.csdn.net/fenrir_sun/article/details/52232723
-- return the acutual count of the current string
local function sub_get_byte_count(str, index)
    local curByte = string.byte(str, index)
    local byteCount = 1;
    if curByte == nil then
        byteCount = 0
    elseif curByte > 0 and curByte <= 127 then
        byteCount = 1
    elseif curByte>=192 and curByte<=223 then
        byteCount = 2
    elseif curByte>=224 and curByte<=239 then
        byteCount = 3
    elseif curByte>=240 and curByte<=247 then
        byteCount = 4
    end
    return byteCount;
end

-- return the real count of utf8 string
local function sub_get_total_index(str)
    local curIndex = 0;
    local i = 1;
    local lastCount = 1;
    repeat
        lastCount = sub_get_byte_count(str, i)
        i = i + lastCount;
        curIndex = curIndex + 1;
    until(lastCount == 0);
    return curIndex - 1;
end

local function sub_get_true_index(str, index)
    local curIndex = 0;
    local i = 1;
    local lastCount = 1;
    repeat
        lastCount = sub_get_byte_count(str, i)
        i = i + lastCount;
        curIndex = curIndex + 1;
    until(curIndex >= index);
    return i - lastCount;
end

-- get utf8 sting sub, with or without endIndex
function tools.sub_utf8(str, startIndex, endIndex)
    if startIndex < 0 then
        startIndex = sub_get_total_index(str) + startIndex + 1;
    end

    if endIndex ~= nil and endIndex < 0 then
        endIndex = sub_get_total_index(str) + endIndex + 1;
    end

    if endIndex == nil then
        return string.sub(str, sub_get_true_index(str, startIndex));
    else
        return string.sub(str, sub_get_true_index(str, startIndex), sub_get_true_index(str, endIndex + 1) - 1);
    end
end

-- }}}

-- get_path() {{{
function tools.get_path(full_filename, sep)
    sep=sep or'/'
    return full_filename:match("(.*" .. sep .. ")")
end
-- }}}

-- uri_encode() {{{
function tools.uri_encode(string)
    local vf = vim.fn
    return vf.substitute(vf.iconv(string, 'latin1', 'utf-8'),'[^A-Za-z0-9_.~-]','\\="%".printf("%02X",char2nr(submatch(0)))','g')
end
-- }}}

return tools
-- vim: foldmethod=marker
