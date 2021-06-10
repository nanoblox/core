local Utility = {}

--// CONSTANTS //--

local MAIN = require(game.Nanoblox)

--// VARIABLES //--

--// FUNCTIONS //--

--[[

Return all matches in a source using a pattern.

]]
function Utility.getMatches(source, pattern)
	local matches = {}

	for match in string.gmatch(source, pattern) do
		table.insert(matches, match)
	end

	return matches
end

--// getCaptures Helper Functions //--
function Utility.getCapsuleRanges(source)
	local capsuleRanges = {}

	local searchIndex = 0
	while searchIndex ~= nil do
		local open = string.find(source, "%(", searchIndex)
		if open then
			searchIndex = open
			local close = string.find(source, "%)", searchIndex)
			if close then
				searchIndex = close
				table.insert(capsuleRanges, { lower = open, upper = close })
			else
				return nil
			end
		else
			break
		end
	end

	return capsuleRanges
end

--[[

A Capture is found in a source by a table of possible captures and it
includes the arguments in a following capsule if there is any.

A Capture is structured like this [capture] = {[arg1], [arg2], ... }
Captures are structured like this Captures = {[capture1], [capture2], ... }

Returns all the captures found in a source using a sortedKeywords table and
also returns residue (anything left behind in the source after extracting
captures).

]]
function Utility.getCapsuleCaptures(source, sortedKeywords)
	local parserModule = MAIN.modules.Parser

	source = source:lower()
	--// Find all the captures
	local captures = {}
	--// We need sorted table so that larger keywords get captured before smaller
	--// keywords so we solve the issue of large keywords made of smaller ones
	for counter = 1, #sortedKeywords do
		--// If the source became empty or whitespace then break
		if string.match(source, "^%s*$") ~= nil then
			break
		end

		--// If the keyword is empty or whitespace (maybe default value?) then continue
		--// to the next iteration
		local keyword = sortedKeywords[counter]:lower()
		if string.match(keyword, "^%s*$") ~= nil then
			continue
		end
		keyword = Utility.escapeSpecialCharacters(keyword)

		--// Used to prevent parsing duplicates
		local alreadyFound = false

		--// Captures with argument capsules are stripped away from the source
		source = string.gsub(
			source,
			string.format("(%s)%s", keyword, parserModule.patterns.capsuleFromKeyword),
			function(keyword, arguments)
				--// Arguments need to be separated as they are the literal string
				--// in the capsule at this point
				if not alreadyFound then
					local separatedArguments = Utility.getMatches(
						arguments,
						parserModule.patterns.argumentsFromCollection
					)
					table.insert(captures, { [keyword] = separatedArguments })
				end
				alreadyFound = true
				return ""
			end
		)
	end

	return captures, source
end

--[[

]]
function Utility.getPlainCaptures(source, sortedKeywords)
	source = source:lower()

	local captures = {}

	for counter = 1, #sortedKeywords do
		--// If the source became empty or whitespace then break
		if string.match(source, "^%s*$") ~= nil then
			break
		end

		--// If the keyword is empty or whitespace (maybe default value?) then continue
		--// to the next iteration
		local keyword = sortedKeywords[counter]:lower()
		if string.match(keyword, "^%s*$") ~= nil then
			continue
		end
		keyword = Utility.escapeSpecialCharacters(keyword)

		--// Used to prevent parsing duplicates
		local alreadyFound = false

		source = string.gsub(source, keyword, function(keyword, arguments)
			--// Arguments need to be separated as they are the literal string
			--// in the capsule at this point
			if not alreadyFound then
				table.insert(captures, { [keyword] = {} })
			end
			alreadyFound = true
			return ""
		end)
	end

	return captures, source
end

--[[

]]
function Utility.combineCaptures(firstCaptures, secondCaptures)
	local combinedCaptures = {}

	for keyword, arguments in pairs(firstCaptures) do
		combinedCaptures[keyword] = arguments
	end

	for keyword, arguments in pairs(secondCaptures) do
		if combinedCaptures[keyword] == nil then
			combinedCaptures[keyword] = arguments
		end
	end

	return combinedCaptures
end

--[[



]]
function Utility.escapeSpecialCharacters(source)
	return source:gsub("([%.%%%^%$%(%)%[%]%+%*%-%?])", "%%%1")
end

--[[



]]
function Utility.ternary(condition, ifTrue, ifFalse)
	if condition then
		return ifTrue
	else
		return ifFalse
	end
end

--// INSTRUCTIONS //--

return Utility
