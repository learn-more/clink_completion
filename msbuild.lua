

local function target_sln(word)
    local matches = {}
    local glob = clink.find_files(word..'*', true)
    for _, i in ipairs(glob) do
        table.insert(matches, i)
    end
    if #matches ~= 0 then
        clink.matches_are_files()
    end
    return matches
end

local function strip_exts(filename, exts)
    for _, ext in pairs(exts) do
        local len = ext:len()
        if filename:sub(-len):lower() == ext:lower() then
            return filename:sub(1, filename:len()-len)
        end
    end
    return filename
end

local function read_sln(filename)
    local matches = {}
    local f = io.open(filename, "rb")
    local content = f:read("*all")
    f:close()
    local extensions = { '.vcxproj', '.vcproj' }
    local projects = {}
    local scopes = {}
    for nested in content:gmatch('GlobalSection%(NestedProjects%)(.-)EndGlobalSection') do
        --print(#nested)
        for left, right in nested:gmatch('({[A-Z0-9%-]-}).-=.-({[A-Z0-9%-]-})') do
            --print(left, right)
            assert(scopes[left] == nil)
            scopes[left] = right
        end
    end

    for proj, path, guid in content:gmatch('Project%([^%)]+%)[^"]+"([^"]+)"[^"]+"([^"]+)"[^"]+"([^"]+)"') do
        assert(projects[guid] == nil)
        projects[guid] = proj   --path
    end

    for guid, path in pairs(projects) do
        local fullname = path
        local parent = scopes[guid]
        --print(guid, parent)
        while parent do
            local parentname = projects[parent]
            fullname = parentname .. '\\' .. fullname
            parent = scopes[parent]
        end
        table.insert(matches, '/t:' .. fullname)
        --print(fullname)
    end
    return matches
end


local function msbuild_target_parser(word)
    local matches = {}

    local words = {}
    rl_state.line_buffer:gsub("%S+", function(w) table.insert(words, w) end)
    if #words >= 3 then
        matches = read_sln(words[2])
    end

    return matches
end

if clink == nil then
    -- when this script is running without clink, show all computed matches
    local matches = read_sln('D:\\testdata\\example.sln')
    for _,value in pairs(matches) do
        print(value)
    end
else
    local msbuild_parser = clink.arg.new_parser()
    msbuild_parser:set_arguments(
        { target_sln },
        { msbuild_target_parser }
    )

    clink.arg.register_parser("msbuild", msbuild_parser)
    clink.arg.register_parser("msbuild.exe", msbuild_parser)
end

