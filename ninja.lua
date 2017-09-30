

local function dir_match_generator_impl(text)
    -- Strip off any path components that may be on text.
    local prefix = ""
    local i = text:find("[\\/:][^\\/:]*$")
    if i then
        prefix = text:sub(1, i)
    end

    local include_dots = text:find("%.+$") ~= nil

    local matches = {}
    local mask = text.."*"

    -- Find matches.
    for _, dir in ipairs(clink.find_dirs(mask, true)) do
        local file = prefix..dir

        if include_dots or (dir ~= "." and dir ~= "..") then
            if clink.is_match(text, file) then
                table.insert(matches, prefix..dir)
            end
        end
    end

    return matches
end

--------------------------------------------------------------------------------
local function dir_match_generator(word)
    local matches = dir_match_generator_impl(word)

    if #matches == 0 then
        if clink.is_dir(rl_state.text) then
            table.insert(matches, rl_state.text)
        end
    end

    return matches
end

local ninja_dir_parser = clink.arg.new_parser()
ninja_dir_parser:set_arguments({dir_match_generator})

local function target_function(word)
	local matches = {}
	for line in io.popen("ninja -t targets 2>nul"):lines() do
		xline = string.gsub(line, ':(.-)$','')
		table.insert(matches, xline)
	end
	return matches
end

local ninja_parser = clink.arg.new_parser()
ninja_parser:set_arguments({
	"-C" .. ninja_dir_parser,
	target_function
})

clink.arg.register_parser("ninja", ninja_parser)
