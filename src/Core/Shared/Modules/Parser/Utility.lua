local Utility = {}

--// CONSTANTS //--

local MAIN = require(game.HDAdmin)

--// VARIABLES //--



--// FUNCTIONS //--

--[[

Return all matches in a source using a pattern.

]]--
function Utility.getMatches(source, pattern)
	local matches = {}

	for match in string.gmatch(source, pattern) do
		table.insert(matches, match)
	end

	return matches
end

--[[

A Capture is found in a source by a table of possible captures and it
includes the arguments in a following capsule if there is any.

A Capture is structured like this [capture] = {[arg1], [arg2], ... }
Captures are structured like this Captures = {[capture1], [capture2], ... }

Returns all the captures found in a source using a sortedKeywords table and
also returns residue (anything left behind in the source after extracting
captures).

]]--
function Utility.getCaptures(source, sortedKeywords)
    local parser = MAIN.modules.Parser

	--// Find all the captures
	local captures = {}
	--// We need sorted table so that larger keywords get captured before smaller
	--// keywords so we solve the issue of large keywords made of smaller ones
	for counter = 1, #sortedKeywords do
		--// If the source became empty or whitespace then continue
		if (string.match(source, "^%s*$") ~= nil) then break end

		--// If the keyword is empty or whitespace (maybe default value?) then continue
		--// to the next iteration
		local keyword = sortedKeywords[counter]:lower()
		if (string.match(keyword, "^%s*$") ~= nil) then continue end
		keyword = Utility.escapeSpecialCharacters(keyword)

		--// Captures with argument capsules are stripped away from the source
		source = string.gsub(
			source,
			string.format("(%s)%s", keyword, parser.Patterns.CapsuleFromKeyword),
			function(keyword, arguments)
				--// Arguments need to be separated as they are the literal string
				--// in the capsule at this point
				local separatedArguments = Utility.getMatches(arguments, parser.Patterns.ArgumentsFromCollection)
				table.insert(captures, {[keyword] = separatedArguments})
				return ""
			end
		)
		--// Captures without argument capsules are left in the source and are
		--// collected at this point
		source = string.gsub(
			source,
			string.format("(%s)", keyword),
			function(keyword)
				table.insert(captures, {[keyword] = {}})
				return ""
			end
		)
	end

	return captures, source
end

--[[

]]--
function Utility.escapeSpecialCharacters(source)
	return source:gsub(
		"([%.%%%^%$%(%)%[%]%+%*%-%?])",
        "%%%1"
	)
end

return Utility