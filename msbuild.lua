

local function target_sln(word)
    local matches = {}
    local glob = clink.find_files(word..'*', true)
    for _, file in ipairs(glob) do
        local is_sln = file:sub(-4):lower() == '.sln'
        if is_sln or file:sub(-8):lower() == '.vcxproj' then
            table.insert(matches, file)
        end
    end
    if #matches ~= 0 then
        clink.matches_are_files()
    end
    return matches
end

local function msbuild_target_parser(word)
    local matches = {}

    local words = {}
    rl_state.line_buffer:gsub("%S+", function(w) table.insert(words, w) end)
    if #words >= 2 then
        local f = io.open(words[2], "rb")
        local content = f:read("*all")
        f:close()
        for proj, path in content:gmatch('Project%([^%)]+%)[^"]+"([^"]+)"[^"]+"([^"]+)"') do
            --print(proj, path)
            if path:sub(-8):lower() == '.vcxproj' then
                table.insert(matches, '/t:' .. path:sub(1,path:len()-8))
            else
                table.insert(matches, '/t:' .. path)
            end
        end
    end

    return matches
end


local msbuild_parser = clink.arg.new_parser()
msbuild_parser:set_arguments(
    { target_sln },
    { msbuild_target_parser }
)

clink.arg.register_parser("msbuild", msbuild_parser)



