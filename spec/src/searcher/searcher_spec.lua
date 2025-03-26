
local searcher = require("src.searcher")

describe("searcher", function ()
    describe("default", function ()
        it("loads relative modules", function ()
            local adjacent_mod = searcher(".adjacent")
            local adjacent = adjacent_mod()

            assert.equal("adjacent", adjacent)
        end)

        it("loads wildcard modules", function ()
            local get_modules = searcher("spec.src.searcher.folder.*")
            local modules = get_modules()

            assert.equal(2, #modules)

            assert.equal("1", modules[1])
            assert.equal("2", modules[2])
        end)

        it("loads multiple modules", function ()
            local get_modules = searcher("spec.src.searcher.folder.(1|2)")
            local modules = get_modules()

            assert.equal(2, #modules)

            assert.equal("1", modules[1])
            assert.equal("2", modules[2])
        end)
    end)

    it("matches strings", function ()
        ---@diagnostic disable-next-line:invisible
        local m_start, m_end = searcher._match_pattern("ing", "testing in this string", 1)

        assert.equal(5, m_start)
        assert.equal(7, m_end)
    end)

    it("doesn't fail awfully for aliases that don't match", function ()
        local search = searcher.create({
            { "bruh", "bruhtendo" }
        })

        local get_mod = search("spec.src.searcher.folder.1")
        
        assert.Nil(get_mod)
    end)

    it("allows string replacers", function ()
        local pattern = "shortcut"
        local replacer = "some.long.long.path"
        
        ---@diagnostic disable-next-line:invisible
        local mods = searcher._permute({ "shortcut.module" }, pattern, replacer)

        assert.equal(1, #mods)
        assert.equal("some.long.long.path.module", mods[1])
    end)
end)