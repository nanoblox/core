return function()

    it("should parse ;rainbow all", function(context)
        local result = context.Parser.parseMessage(";rainbow all")

        expect(result[1].commands.rainbow).to.be.ok()
        expect(result[1].qualifiers.all).to.be.ok()
    end)

    it("should parse ;rainbow all,you,me,others", function(context)
        local result = context.Parser.parseMessage(";rainbow all,you,me,others")

        expect(result[1].commands.rainbow).to.be.ok()
        expect(result[1].qualifiers.all).to.be.ok()
        expect(result[1].qualifiers.you).to.be.ok()
        expect(result[1].qualifiers.me).to.be.ok()
        expect(result[1].qualifiers.others).to.be.ok()
    end)

    it("should parse ;rainbowpoop all", function(context)
        local result = context.Parser.parseMessage(";rainbowpoop all")

        expect(result[1].commands.rainbowpoop).to.be.ok()
        expect(result[1].commands.rainbowpoop[1]).to.be.equal("all")
    end)

    it("should parse ;rainbow()poop all", function(context)
        local result = context.Parser.parseMessage(";rainbow()poop all")

        expect(result[1].commands.rainbow).to.be.ok()
        expect(result[1].commands.poop).to.be.ok()
        expect(result[1].qualifiers.all).to.be.ok()
    end)

    it("should parse ;rainbow all;poop others", function(context)
        local result = context.Parser.parseMessage(";rainbow all;poop others")

        expect(result[1].commands.rainbow).to.be.ok()
        expect(result[1].qualifiers.all).to.be.ok()
        expect(result[2].commands.poop).to.be.ok()
        expect(result[2].qualifiers.others).to.be.ok()
    end)

    it("should parse ;rainbow all,team(orange),others", function(context)
        local result = context.Parser.parseMessage(";rainbow all,team(orange),others")

        expect(result[1].commands.rainbow).to.be.ok()
        expect(result[1].qualifiers.all).to.be.ok()
        expect(result[1].qualifiers.team).to.be.ok()
        expect(result[1].qualifiers.team[1]).to.be.equal("orange")
        expect(result[1].qualifiers.others).to.be.ok()
    end)

    it("should parse ;alert all we are going to have a fun", function(context)
        local result = context.Parser.parseMessage(";alert all we are going to have a fun")

        expect(result[1].commands.alert).to.be.ok()
        expect(result[1].commands.alert[1]).to.be.equal("we are going to have a fun")
        expect(result[1].qualifiers.all).to.be.ok()
    end)
end