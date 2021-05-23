return function()

    beforeAll(function(context)
        context.Parser = context.main.modules.Parser
    end)

end