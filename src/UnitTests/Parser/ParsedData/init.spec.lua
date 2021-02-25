return function()

    beforeAll(function(context)
        context.ParsedData = context.Parser.ParsedData
    end)

end