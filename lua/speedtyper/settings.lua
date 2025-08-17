local api = vim.api
local settings_path = ("%s/speedtyper-settings.json"):format(vim.fn.stdpath("data"))
local logger = require("speedtyper.logger")
local notify = require("speedtyper.notify")
local util = require("speedtyper.util")

---@class speedtyper.settings_subcmd
---@field impl fun(args: string[], data: table) The command implementation
---@field complete? fun(subcmd_arg_lead: string): string[] Command completions callback, taking the lead of the subcommand's arguments

-- NOTE: see each field info in instructions.lua

---@alias speedtyper.cursor_style "block" | "line" | "underline"

---@alias speedtyper.notify_method "none" | "notify" | "echo"

---@class speedtyper.settings.round
---@field text_variant table<"punctuation" | "numbers", boolean>
---@field game_mode table<"time" | "word" | "rain" | "custom", boolean>
---@field length table<"15" | "30" | "60" | "120", boolean>

---@class speedtyper.settings.general.keymaps
---@field start_game string | string[]
---@field new_game string | string[]
---@field restart_game string | string[]
---@field hover string | string[]
---@field press_button string | string[]
---TODO: add more

---@class speedtyper.settings.general
---@field language table<string, boolean>
---@field theme table<string, boolean>
---@field cursor_style table<speedtyper.cursor_style, boolean>
---@field cursor_blinking boolean
---@field pace_cursor boolean
---@field pace_cursor_speed integer
---@field pace_cursor_style table<speedtyper.cursor_style, boolean>
---@field strict_space boolean
---@field stop_on_error boolean
---@field confidence_mode boolean
---@field indicate_typos boolean
---@field sound_volume integer
---@field sound_on_keypress table<string, boolean>
---@field sound_on_typo table<string, boolean>
---@field sound_on_notification table<string, boolean>
---@field live_progress boolean
-- -@field average_speed boolean
-- -@field average_accuracy boolean
---@field demojify boolean
---@field notify_method table<speedtyper.notify_method, boolean>
---@field debug_mode boolean
---@field keymaps speedtyper.settings.general.keymaps

---@class speedtyper.default_settings
---@field round speedtyper.settings.round
---@field general speedtyper.settings.general

---@class speedtyper.settings
---@field default speedtyper.default_settings
---@field round speedtyper.settings.round
---@field general speedtyper.settings.general
local Settings = {}
Settings.__index = Settings

---@return speedtyper.settings
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
                language = {},
                theme = {},
                cursor_style = {
                    line = true,
                    block = false,
                    underline = false,
                },
                cursor_blinking = false,
                pace_cursor = false,
                pace_cursor_speed = 100,
                pace_cursor_style = {
                    line = false,
                    block = true,
                    underline = false,
                },
                strict_space = false,
                stop_on_error = false,
                confidence_mode = false,
                indicate_typos = true,
                sound_volume = 50,
                sound_on_keypress = {},
                sound_on_typo = {},
                sound_on_notification = {},
                live_progress = true,
                -- average_speed = false,
                -- average_accuracy = false,
                demojify = false,
                notify_method = {
                    none = false,
                    notify = false,
                    echo = true,
                },
                debug_mode = false,
                keymaps = {
                    start_game = { "I", "i" },
                    new_game = "N",
                    restart_game = "R",
                    hover = "K",
                    press_button = { "<CR>", "<2-LeftMouse>" },
                },
            },
        },
    }, Settings)

    -- read all sounds from the sounds directory
    local sounds = util.read_dir(util.get_plugin_path() .. "/assets/sounds", ".ogg", true)
    for _, sound in ipairs(sounds) do
        self.default.general.sound_on_keypress[sound] = false
        self.default.general.sound_on_typo[sound] = false
        self.default.general.sound_on_notification[sound] = false
    end
    self.default.general.sound_on_keypress["off"] = true
    self.default.general.sound_on_typo["off"] = true
    self.default.general.sound_on_notification["off"] = true

    -- read all languages from the languages directory
    local langs = util.read_dir(util.get_plugin_path() .. "/assets/languages", ".json", true)
    for _, lang in ipairs(langs) do
        self.default.general.language[lang] = false
    end
    self.default.general.language["english"] = true

    -- read all themes from the themes directory
    local themes = util.read_dir(util.get_plugin_path() .. "/lua/speedtyper/themes", ".lua", true)
    for _, theme in ipairs(themes) do
        self.default.general.theme[theme] = false
    end
    self.default.general.theme["random"] = false
    self.default.general.theme["default"] = true

    self.round = vim.deepcopy(self.default.round)
    self.general = vim.deepcopy(self.default.general)

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
end

function Settings:save()
    local settings = {
        round = self.round,
        general = self.general,
    }
    local json = vim.fn.json_encode(settings)
    local file = io.open(settings_path, "w")
    if file then
        file:write(json)
        file:close()
        logger:log("settings saved")
    else
        notify.notify("failed to save settings", vim.log.levels.ERROR)
    end
end

function Settings:reset_settings()
    self.round = vim.deepcopy(self.default.round)
    self.general = vim.deepcopy(self.default.general)
    logger:log("settings reset")
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

---@param option string
---@return string[]
function Settings:get_options(option)
    if type(self.general[option]) ~= "table" then
        return {}
    end
    return vim.tbl_keys(self.general[option])
end

function Settings:create_user_commands()
    ---@type table<string, speedtyper.settings_subcmd >
    local subcmds = {
        info = self:create_info_subcmd(),
        reset_settings = self:create_reset_subcmd(),
        keymaps = self:create_keymap_subcmd(),
        language = self:create_subcmd_for_map_option("language"),
        theme = self:create_subcmd_for_map_option("theme"),
        cursor_style = self:create_subcmd_for_map_option("cursor_style"),
        cursor_blinking = self:create_subcmd_for_bool_option("cursor_blinking"),
        pace_cursor = self:create_subcmd_for_bool_option("pace_cursor"),
        pace_cursor_speed = self:create_subcmd_for_number_option("pace_cursor_speed", 1, 1000),
        pace_cursor_style = self:create_subcmd_for_map_option("pace_cursor_style"),
        strict_space = self:create_subcmd_for_bool_option("strict_space"),
        stop_on_error = self:create_subcmd_for_bool_option("stop_on_error"),
        confidence_mode = self:create_subcmd_for_bool_option("confidence_mode"),
        indicate_typos = self:create_subcmd_for_bool_option("indicate_typos"),
        sound_volume = self:create_subcmd_for_number_option("sound_volume", 0, 100),
        sound_on_keypress = self:create_subcmd_for_map_option("sound_on_keypress"),
        sound_on_typo = self:create_subcmd_for_map_option("sound_on_typo"),
        sound_on_notification = self:create_subcmd_for_map_option("sound_on_notification"),
        live_progress = self:create_subcmd_for_bool_option("live_progress"),
        -- average_speed = self:create_subcmd_for_bool_option("average_speed"),
        -- average_accuracy = self:create_subcmd_for_bool_option("average_accuracy"),
        demojify = self:create_subcmd_for_bool_option("demojify"),
        notify_method = self:create_subcmd_for_map_option("notify_method"),
        debug_mode = self:create_subcmd_for_bool_option("debug_mode"),
    }

    local function cmd(data)
        local fargs = data.fargs
        if #fargs == 0 then
            notify.notify(
                "SpeedtyperSettings: command expects at least one argument",
                vim.log.levels.ERROR
            )
            return
        end
        local subcommand_key = fargs[1]
        -- get the subcommand's arguments, if any
        local args = #fargs > 1 and vim.list_slice(fargs, 2, #fargs) or {}
        local subcmd = subcmds[subcommand_key]
        if not subcmd then
            notify.notify(
                ("SpeedtyperSettings: unknown command '%s'"):format(subcommand_key),
                vim.log.levels.ERROR
            )
            return
        end
        -- invoke the subcommand
        subcmd.impl(args, data)
    end

    local function cmd_completion(arg_lead, cmdline, _)
        -- get the subcommand
        local subcmd_key, subcmd_arg_lead = cmdline:match("^SpeedtyperSettings%s(%S+)%s(.*)$")
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
        if cmdline:match("^SpeedtyperSettings%s+%w*$") then
            -- filter subcommands that match
            local subcommand_keys = vim.tbl_keys(subcmds)
            return vim.iter(subcommand_keys)
                :filter(function(key)
                    return key:find(arg_lead) ~= nil
                end)
                :totable()
        end
    end

    api.nvim_create_user_command("SpeedtyperSettings", cmd, {
        desc = "change speedtyper settings",
        complete = cmd_completion,
        nargs = "*",
    })
end

---@private
---@param option string
---@return speedtyper.settings_subcmd
function Settings:create_subcmd_for_map_option(option)
    return {
        impl = function(args, _)
            -- if no arguments are given, display the current value
            if #args == 0 then
                notify.notify(
                    ("Option '%s' is currently set to '%s'."):format(
                        option,
                        self:get_selected(option)
                    ),
                    vim.log.levels.INFO
                )
                return
            elseif #args > 1 then
                notify.notify(
                    ("SpeedtyperSettings %s: command expects exactly one argument"):format(option),
                    vim.log.levels.ERROR
                )
                return
            end
            if
                not util.tbl_contains(
                    util.get_map_option_completion("", self.general[option]),
                    args[1]
                )
            then
                notify.notify(
                    ("SpeedtyperSettings %s: unknown argument '%s'"):format(option, args[1]),
                    vim.log.levels.ERROR
                )
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

---@private
---@param option string
---@return speedtyper.settings_subcmd
function Settings:create_subcmd_for_bool_option(option)
    return {
        impl = function(args, _)
            if #args == 0 then
                notify.notify(
                    ("Option '%s' is currently %s."):format(
                        option,
                        self:get_selected(option) and "ON" or "OFF"
                    ),
                    vim.log.levels.INFO
                )
                return
            elseif #args ~= 1 then
                notify.notify(
                    ("SpeedtyperSettings %s: command expects exactly one argument"):format(option),
                    vim.log.levels.ERROR
                )
                return
            end
            if not util.tbl_contains(util.get_bool_option_completion(""), args[1]) then
                notify.notify(
                    ("SpeedtyperSettings %s: unknown argument '%s'"):format(option, args[1]),
                    vim.log.levels.ERROR
                )
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

---@private
---@param option string
---@param min number
---@param max number
---@return speedtyper.settings_subcmd
function Settings:create_subcmd_for_number_option(option, min, max)
    return {
        impl = function(args, _)
            if #args == 0 then
                notify.notify(
                    ("Option '%s' is currently set to %d."):format(
                        option,
                        self:get_selected(option)
                    ),
                    vim.log.levels.INFO
                )
                return
            elseif #args ~= 1 then
                notify.notify(
                    ("SpeedtyperSettings %s: command expects exactly one argument"):format(option),
                    vim.log.levels.ERROR
                )
                return
            end
            local new_val = tonumber(args[1])
            if new_val == nil or new_val < min or new_val > max then
                notify.notify(
                    ("SpeedtyperSettings %s: value must be between %d and %d"):format(
                        option,
                        min,
                        max
                    ),
                    vim.log.levels.ERROR
                )
                return
            end
            self.general[option] = new_val
            self:save()
            require("speedtyper.ui"):redraw()
        end,
    }
end

---@private
---@return speedtyper.settings_subcmd
function Settings:create_info_subcmd()
    local all_options = {}
    for option, _ in pairs(self.general) do
        table.insert(all_options, option)
    end
    return {
        impl = function(args, data)
            if #args ~= 1 then
                notify.notify(
                    ("SpeedtyperSettings %s: command expects exactly one argument"):format(
                        data.fargs[1]
                    ),
                    vim.log.levels.ERROR
                )
                return
            end
            if not util.tbl_contains(all_options, args[1]) then
                notify.notify(
                    ("SpeedtyperSettings %s: unknown argument '%s'"):format(data.fargs[1], args[1]),
                    vim.log.levels.ERROR
                )
                return
            end
            notify.notify(require("speedtyper.instructions"):get(args[1]), vim.log.levels.INFO)
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

---@private
---@return speedtyper.settings_subcmd
function Settings:create_reset_subcmd()
    return {
        impl = function(args, _)
            if #args ~= 0 then
                notify.notify(
                    "SpeedtyperSettings reset_settings: no arguments expected",
                    vim.log.levels.ERROR
                )
                return
            end
            local prompt = require("speedtyper.instructions"):get("reset_settings")
            vim.ui.select({ "No", "Yes" }, { prompt = prompt }, function(selected, _)
                if selected == "Yes" then
                    self:reset_settings()
                    self:save()
                    require("speedtyper.ui"):redraw()
                    notify.notify("Settings have been reset.", vim.log.levels.INFO)
                end
            end)
        end,
    }
end

---@private
---@return speedtyper.settings_subcmd
function Settings:create_keymap_subcmd()
    local all_keymaps = {}
    for key, _ in pairs(self.general.keymaps) do
        table.insert(all_keymaps, key)
    end
    return {
        impl = function(args, data)
            if #args <= 1 then
                notify.notify(
                    ("SpeedtyperSettings %s: command expects at least one argument"):format(
                        data.fargs[1]
                    ),
                    vim.log.levels.ERROR
                )
                return
            end
            if not util.tbl_contains(all_keymaps, args[1]) then
                notify.notify(
                    ("SpeedtyperSettings %s: unknown keymap option '%s'"):format(
                        data.fargs[1],
                        args[1]
                    ),
                    vim.log.levels.ERROR
                )
                return
            end
            local keymap = args[1]
            table.remove(args, 1)
            self.general.keymaps[keymap] = args

            self:save()
            require("speedtyper.ui"):redraw()
        end,
        complete = function(subcmd_arg_lead)
            return vim.iter(all_keymaps)
                :filter(function(arg)
                    return arg:find(subcmd_arg_lead) ~= nil
                end)
                :totable()
        end,
    }
end

return Settings.new()
