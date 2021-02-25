return function()

    beforeAll(function(context)
        context.Utility = context.Parser.Utility
    end)

end