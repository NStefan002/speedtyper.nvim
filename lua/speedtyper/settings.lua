local api = vim.api
local util = require("speedtyper.util")
local settings_path = ("%s/speedtyper-settings.json"):format(vim.fn.stdpath("data"))
local logger = require("speedtyper.logger")

---@class SpeedTyperSettingsSubcmd
---@field impl fun(args: string[], data: table) The command implementation
---@field complete? fun(subcmd_arg_lead: string): string[] Command completions callback, taking the lead of the subcommand's arguments

-- NOTE: see each field info in instructions.lua

---@alias SpeedTyperCursorStyle "block" | "line" | "underline"

---@class SpeedTyperRoundSettings
---@field text_variant table<"punctuation" | "numbers", boolean>
---@field game_mode table<"time" | "word" | "rain", boolean>
---@field length table<"15" | "30" | "60" | "120", boolean>

---@class SpeedTyperGeneralSettings
---@field language table<string, boolean>
---@field theme table<string, boolean>
---@field cursor_style table<SpeedTyperCursorStyle, boolean>
---@field cursor_blinking boolean
---@field pace_cursor boolean
---@field pace_cursor_speed integer
---@field pace_cursor_style table<SpeedTyperCursorStyle, boolean>
---@field pace_cursor_blinking boolean
---@field strict_space boolean
---@field stop_on_error boolean
---@field confidence_mode boolean
---@field indicate_typos boolean
---@field sound_volume integer
---@field sound_on_keypress table<string, boolean>
---@field sound_on_typo table<string, boolean>
---@field live_progress boolean
---@field average_speed boolean
---@field average_accuracy boolean
---@field demojify boolean
---@field debug_mode boolean

---@class SpeedTyperKeymapSettings
---@field start_game string | string[]
---@field hover string | string[]
---@field press_button string | string[]
---TODO: add more

---@class SpeedTyperDefaultSettings
---@field round SpeedTyperRoundSettings
---@field general SpeedTyperGeneralSettings
---@field keymaps SpeedTyperKeymapSettings

---@class SpeedTyperSettings
---@field default SpeedTyperDefaultSettings
---@field round SpeedTyperRoundSettings
---@field general SpeedTyperGeneralSettings
---@field keymaps SpeedTyperKeymapSettings
local Settings = {}
Settings.__index = Settings

---@return SpeedTyperSettings
function Settings.new()
    local self = setmetatable({
        default = {
            round = {
                text_variant = {
                    punctuation = false,
                    numbers = false,
                },
                game_mode = {
                    time = true,
                    words = false,
                    rain = false,
                    custom = false,
                },
                length = {
                    ["15"] = false,
                    ["30"] = true,
                    ["60"] = false,
                    ["120"] = false,
                },
            },

            general = {
                language = {
                    english = true,
                    serbian = false,
                },
                theme = {
                    default = true,
                    random = false,
                },
                cursor_style = {
                    line = true,
                    block = false,
                    underline = false,
                },
                cursor_blinking = false,
                pace_cursor = false,
                pace_cursor_speed = 100,
                pace_cursor_style = {
                    line = true,
                    block = false,
                    underline = false,
                },
                pace_cursor_blinking = false,
                strict_space = false,
                stop_on_error = false,
                confidence_mode = false,
                indicate_typos = true,
                sound_volume = 50,
                sound_on_keypress = {
                    off = true,
                    back_1 = false,
                    back_2 = false,
                    back_3 = false,
                    back_4 = false,
                    bong_1 = false,
                    click_1 = false,
                    click_2 = false,
                    click_3 = false,
                    click_4 = false,
                    click_5 = false,
                    close_1 = false,
                    close_2 = false,
                    close_3 = false,
                    close_4 = false,
                    confirmation_1 = false,
                    confirmation_2 = false,
                    confirmation_3 = false,
                    confirmation_4 = false,
                    drop_1 = false,
                    drop_2 = false,
                    drop_3 = false,
                    drop_4 = false,
                    error_1 = false,
                    error_2 = false,
                    error_3 = false,
                    error_4 = false,
                    error_5 = false,
                    error_6 = false,
                    error_7 = false,
                    error_8 = false,
                    glass_1 = false,
                    glass_2 = false,
                    glass_3 = false,
                    glass_4 = false,
                    glass_5 = false,
                    glass_6 = false,
                    glitch_1 = false,
                    glitch_2 = false,
                    glitch_3 = false,
                    glitch_4 = false,
                    maximize_1 = false,
                    maximize_2 = false,
                    maximize_3 = false,
                    maximize_4 = false,
                    maximize_5 = false,
                    maximize_6 = false,
                    maximize_7 = false,
                    maximize_8 = false,
                    maximize_9 = false,
                    minimize_1 = false,
                    minimize_2 = false,
                    minimize_3 = false,
                    minimize_4 = false,
                    minimize_5 = false,
                    minimize_6 = false,
                    minimize_7 = false,
                    minimize_8 = false,
                    minimize_9 = false,
                    open_1 = false,
                    open_2 = false,
                    open_3 = false,
                    open_4 = false,
                    pluck_1 = false,
                    pluck_2 = false,
                    question_1 = false,
                    question_2 = false,
                    question_3 = false,
                    question_4 = false,
                    scratch_1 = false,
                    scratch_2 = false,
                    scratch_3 = false,
                    scratch_4 = false,
                    scratch_5 = false,
                    scroll_1 = false,
                    scroll_2 = false,
                    scroll_3 = false,
                    scroll_4 = false,
                    scroll_5 = false,
                    select_1 = false,
                    select_2 = false,
                    select_3 = false,
                    select_4 = false,
                    select_5 = false,
                    select_6 = false,
                    select_7 = false,
                    select_8 = false,
                    switch_1 = false,
                    switch_2 = false,
                    switch_3 = false,
                    switch_4 = false,
                    switch_5 = false,
                    switch_6 = false,
                    switch_7 = false,
                    tick_1 = false,
                    tick_2 = false,
                    tick_4 = false,
                    toggle_1 = false,
                    toggle_2 = false,
                    toggle_3 = false,
                    toggle_4 = false,
                },
                sound_on_typo = {
                    off = true,
                    back_1 = false,
                    back_2 = false,
                    back_3 = false,
                    back_4 = false,
                    bong_1 = false,
                    click_1 = false,
                    click_2 = false,
                    click_3 = false,
                    click_4 = false,
                    click_5 = false,
                    close_1 = false,
                    close_2 = false,
                    close_3 = false,
                    close_4 = false,
                    confirmation_1 = false,
                    confirmation_2 = false,
                    confirmation_3 = false,
                    confirmation_4 = false,
                    drop_1 = false,
                    drop_2 = false,
                    drop_3 = false,
                    drop_4 = false,
                    error_1 = false,
                    error_2 = false,
                    error_3 = false,
                    error_4 = false,
                    error_5 = false,
                    error_6 = false,
                    error_7 = false,
                    error_8 = false,
                    glass_1 = false,
                    glass_2 = false,
                    glass_3 = false,
                    glass_4 = false,
                    glass_5 = false,
                    glass_6 = false,
                    glitch_1 = false,
                    glitch_2 = false,
                    glitch_3 = false,
                    glitch_4 = false,
                    maximize_1 = false,
                    maximize_2 = false,
                    maximize_3 = false,
                    maximize_4 = false,
                    maximize_5 = false,
                    maximize_6 = false,
                    maximize_7 = false,
                    maximize_8 = false,
                    maximize_9 = false,
                    minimize_1 = false,
                    minimize_2 = false,
                    minimize_3 = false,
                    minimize_4 = false,
                    minimize_5 = false,
                    minimize_6 = false,
                    minimize_7 = false,
                    minimize_8 = false,
                    minimize_9 = false,
                    open_1 = false,
                    open_2 = false,
                    open_3 = false,
                    open_4 = false,
                    pluck_1 = false,
                    pluck_2 = false,
                    question_1 = false,
                    question_2 = false,
                    question_3 = false,
                    question_4 = false,
                    scratch_1 = false,
                    scratch_2 = false,
                    scratch_3 = false,
                    scratch_4 = false,
                    scratch_5 = false,
                    scroll_1 = false,
                    scroll_2 = false,
                    scroll_3 = false,
                    scroll_4 = false,
                    scroll_5 = false,
                    select_1 = false,
                    select_2 = false,
                    select_3 = false,
                    select_4 = false,
                    select_5 = false,
                    select_6 = false,
                    select_7 = false,
                    select_8 = false,
                    switch_1 = false,
                    switch_2 = false,
                    switch_3 = false,
                    switch_4 = false,
                    switch_5 = false,
                    switch_6 = false,
                    switch_7 = false,
                    tick_1 = false,
                    tick_2 = false,
                    tick_4 = false,
                    toggle_1 = false,
                    toggle_2 = false,
                    toggle_3 = false,
                    toggle_4 = false,
                },
                live_progress = true,
                average_speed = false,
                average_accuracy = false,
                demojify = false,
                debug_mode = false,
            },

            -- TODO: figure out how to set these (commandline or via `setup`)
            keymaps = {
                start_game = "i",
                hover = "K",
                press_button = { "<CR>", "<2-LeftMouse>" },
            },
        },
    }, Settings)

    self.round = vim.deepcopy(self.default.round)
    self.general = vim.deepcopy(self.default.general)
    self.keymaps = vim.deepcopy(self.default.keymaps)

    return self
end

function Settings:load()
    local settings = {}
    local file, _ = io.open(settings_path, "r")
    if file then
        local json = file:read("*a")
        file:close()
        settings = vim.fn.json_decode(json)
        logger:log("settings loaded from file")
    else
        logger:log("settings file not found, using default settings")
    end
    self.round = vim.tbl_deep_extend("force", self.round, settings.round or {})
    self.general = vim.tbl_deep_extend("force", self.general, settings.general or {})
    self.keymaps = vim.tbl_deep_extend("force", self.keymaps, settings.keymaps or {})
end

function Settings:save()
    local settings = {
        round = self.round,
        general = self.general,
        keymaps = self.keymaps,
    }
    local json = vim.fn.json_encode(settings)
    local file = io.open(settings_path, "w")
    if file then
        file:write(json)
        file:close()
        logger:log("settings saved")
    else
        util.error("failed to save settings")
    end
end

function Settings:reset_settings()
    self.round = vim.deepcopy(self.default.round)
    self.general = vim.deepcopy(self.default.general)
    self.keymaps = vim.deepcopy(self.default.keymaps)
    logger:log("settings reset")
end

---@param option string
---@return SpeedTyperSettingsSubcmd
function Settings:_create_subcmd_for_map_option(option)
    return {
        impl = function(args, _)
            -- if no arguments are given, display the current value
            if #args == 0 then
                util.info(
                    ("Option '%s' is currently set to '%s'."):format(
                        option,
                        self:get_selected(option)
                    )
                )
                return
            elseif #args > 1 then
                util.error(
                    ("SpeedTyperSettings %s: command expects exactly one argument"):format(option)
                )
                return
            end
            if
                not util.tbl_contains(
                    util.get_map_option_completion("", self.general[option]),
                    args[1]
                )
            then
                util.error(("SpeedTyperSettings %s: unknown argument '%s'"):format(option, args[1]))
                return
            end
            for opt, _ in pairs(self.general[option]) do
                self.general[option][opt] = false
            end
            self.general[option][args[1]] = true
            self:save()
            require("speedtyper.ui"):redraw()
        end,
        complete = function(subcmd_arg_lead)
            return util.get_map_option_completion(subcmd_arg_lead, self.general[option])
        end,
    }
end

---@param option string
---@return SpeedTyperSettingsSubcmd
function Settings:_create_subcmd_for_bool_option(option)
    return {
        impl = function(args, _)
            if #args == 0 then
                util.info(
                    ("Option '%s' is currently %s."):format(
                        option,
                        self:get_selected(option) and "ON" or "OFF"
                    )
                )
                return
            elseif #args ~= 1 then
                util.error(
                    ("SpeedTyperSettings %s: command expects exactly one argument"):format(option)
                )
                return
            end
            if not util.tbl_contains(util.get_bool_option_completion(""), args[1]) then
                util.error(("SpeedTyperSettings %s: unknown argument '%s'"):format(option, args[1]))
                return
            end
            ---@type boolean
            local new_val = args[1] == "on"
            self.general[option] = new_val
            self:save()
            require("speedtyper.ui"):redraw()
        end,
        complete = function(subcmd_arg_lead)
            return util.get_bool_option_completion(subcmd_arg_lead)
        end,
    }
end

---@param option string
---@param min number
---@param max number
---@return SpeedTyperSettingsSubcmd
function Settings:_create_subcmd_for_number_option(option, min, max)
    return {
        impl = function(args, _)
            if #args == 0 then
                util.info(
                    ("Option '%s' is currently set to %d."):format(
                        option,
                        self:get_selected(option)
                    )
                )
                return
            elseif #args ~= 1 then
                util.error(
                    ("SpeedTyperSettings %s: command expects exactly one argument"):format(option)
                )
                return
            end
            local new_val = tonumber(args[1])
            if new_val == nil or new_val < min or new_val > max then
                util.error(
                    ("SpeedTyperSettings %s: value must be between %d and %d"):format(
                        option,
                        min,
                        max
                    )
                )
                return
            end
            self.general[option] = new_val
            self:save()
            require("speedtyper.ui"):redraw()
        end,
    }
end

function Settings:_create_info_subcmd()
    local all_options = {}
    for option, _ in pairs(self.general) do
        table.insert(all_options, option)
    end
    return {
        impl = function(args, data)
            if #args ~= 1 then
                util.error(
                    ("SpeedTyperSettings %s: command expects exactly one argument"):format(
                        data.fargs[1]
                    )
                )
                return
            end
            if not util.tbl_contains(all_options, args[1]) then
                util.error(
                    ("SpeedTyperSettings %s: unknown argument '%s'"):format(data.fargs[1], args[1])
                )
                return
            end
            util.info(require("speedtyper.instructions"):get(args[1]))
        end,
        complete = function(subcmd_arg_lead)
            return vim.iter(all_options)
                :filter(function(arg)
                    return arg:find(subcmd_arg_lead) ~= nil
                end)
                :totable()
        end,
    }
end

function Settings:_create_reset_subcmd()
    return {
        impl = function(args, _)
            if #args ~= 0 then
                util.error("SpeedTyperSettings reset_settings: no arguments expected")
                return
            end
            local prompt = require("speedtyper.instructions"):get("reset_settings")
            vim.ui.select({ "No", "Yes" }, { prompt = prompt }, function(selected, _)
                if selected == "Yes" then
                    self:reset_settings()
                    self:save()
                    require("speedtyper.ui"):redraw()
                    util.info("Settings have been reset.")
                end
            end)
        end,
    }
end

---@param option string
---@return any
function Settings:get_selected(option)
    if type(self.general[option]) == "table" then
        for opt, selected in pairs(self.general[option]) do
            if selected then
                return opt
            end
        end
    end
    -- if the option is a boolean or number
    return self.general[option]
end

function Settings:create_user_commands()
    ---@type table<string, SpeedTyperSettingsSubcmd>
    local subcmds = {
        info = self:_create_info_subcmd(),
        reset_settings = self:_create_reset_subcmd(),
        language = self:_create_subcmd_for_map_option("language"),
        theme = self:_create_subcmd_for_map_option("theme"),
        cursor_style = self:_create_subcmd_for_map_option("cursor_style"),
        cursor_blinking = self:_create_subcmd_for_bool_option("cursor_blinking"),
        pace_cursor = self:_create_subcmd_for_bool_option("pace_cursor"),
        pace_cursor_speed = self:_create_subcmd_for_number_option("pace_cursor_speed", 1, 1000),
        pace_cursor_style = self:_create_subcmd_for_map_option("pace_cursor_style"),
        strict_space = self:_create_subcmd_for_bool_option("strict_space"),
        stop_on_error = self:_create_subcmd_for_bool_option("stop_on_error"),
        confidence_mode = self:_create_subcmd_for_bool_option("confidence_mode"),
        indicate_typos = self:_create_subcmd_for_bool_option("indicate_typos"),
        sound_volume = self:_create_subcmd_for_number_option("sound_volume", 0, 100),
        sound_on_keypress = self:_create_subcmd_for_map_option("sound_on_keypress"),
        sound_on_typo = self:_create_subcmd_for_map_option("sound_on_typo"),
        live_progress = self:_create_subcmd_for_bool_option("live_progress"),
        average_speed = self:_create_subcmd_for_bool_option("average_speed"),
        average_accuracy = self:_create_subcmd_for_bool_option("average_accuracy"),
        demojify = self:_create_subcmd_for_bool_option("demojify"),
        debug_mode = self:_create_subcmd_for_bool_option("debug_mode"),
    }

    local function cmd(data)
        local fargs = data.fargs
        if #fargs == 0 then
            util.error("SpeedTyperSettings: command expects at least one argument")
            return
        end
        local subcommand_key = fargs[1]
        -- get the subcommand's arguments, if any
        local args = #fargs > 1 and vim.list_slice(fargs, 2, #fargs) or {}
        local subcmd = subcmds[subcommand_key]
        if not subcmd then
            util.error(("SpeedTyperSettings: unknown command '%s'"):format(subcommand_key))
            return
        end
        -- invoke the subcommand
        subcmd.impl(args, data)
    end

    local function cmd_completion(arg_lead, cmdline, _)
        -- get the subcommand
        local subcmd_key, subcmd_arg_lead = cmdline:match("^SpeedTyperSettings%s(%S+)%s(.*)$")
        if
            subcmd_key
            and subcmd_arg_lead
            and subcmds[subcmd_key]
            and subcmds[subcmd_key].complete
        then
            -- the subcommand has completions, return them
            return subcmds[subcmd_key].complete(subcmd_arg_lead)
        end
        -- check if cmdline is a subcommand
        if cmdline:match("^SpeedTyperSettings%s+%w*$") then
            -- filter subcommands that match
            local subcommand_keys = vim.tbl_keys(subcmds)
            return vim.iter(subcommand_keys)
                :filter(function(key)
                    return key:find(arg_lead) ~= nil
                end)
                :totable()
        end
    end

    api.nvim_create_user_command("SpeedTyperSettings", cmd, {
        desc = "Change SpeedTyper settings.",
        complete = cmd_completion,
        nargs = "*",
    })
end

return Settings.new()
