local eq = assert.are.same

describe("Settings tests", function()
    local settings = require("speedtyper.settings")
    settings:load()
    local backup = {}

    before_each(function()
        backup = vim.deepcopy(settings.general)
    end)

    it("get_selected bool", function()
        settings.general.demojify = true
        eq(true, settings:get_selected("demojify"))
        settings.general.demojify = false
        eq(false, settings:get_selected("demojify"))
    end)

    it("get_selected integer", function()
        settings.general.pace_cursor_speed = 120
        eq(120, settings:get_selected("pace_cursor_speed"))
    end)

    it("get_selected map", function()
        for opt, _ in pairs(settings.general.language) do
            settings.general.language[opt] = false
        end
        settings.general.language["serbian"] = true
        eq("serbian", settings:get_selected("language"))
    end)

    after_each(function()
        settings.general = vim.deepcopy(backup)
        settings:save()
    end)
end)
