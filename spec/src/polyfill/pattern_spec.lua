
local pattern = require("src.polyfill.pattern")

describe("pattern", function ()
    describe("number matcher", function ()
        local pat = pattern("%d+")
        
        it("executes on strings", function ()
            local _, _, match = pat("testing 123")

            assert.equal("123", match)
        end)

        it("stringifies", function ()
            local str = tostring(pat)

            assert.equal("%d+", str)
        end)
    end)
end)