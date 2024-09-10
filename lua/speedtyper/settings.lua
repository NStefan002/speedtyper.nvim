local util = require("speedtyper.util")
local settings_path = ("%s/speedtyper-settings.json"):format(vim.fn.stdpath("data"))

---@class SpeedTyperSettingsSubcmd
---@field impl fun(args:string[], data: table) The command implementation
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
---@field randomize_theme boolean
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
---@field sound_volume table<"quiet" | "medium" | "loud", boolean>
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
                    custom = false,
                },
                randomize_theme = false,
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
                sound_volume = {
                    quiet = false,
                    medium = true,
                    loud = false,
                },
                sound_on_keypress = {
                    off = true,
                    click = false,
                    pop = false,
                },
                sound_on_typo = {
                    off = true,
                    click = false,
                    pop = false,
                },
                live_progress = true,
                average_speed = false,
                average_accuracy = false,
                demojify = false,
                debug_mode = false,
            },

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
    else
        require("speedtyper.util").error("Failed to save settings")
    end
end

function Settings:reset_settings()
    self.round = vim.deepcopy(self.default.round)
    self.general = vim.deepcopy(self.default.general)
    self.keymaps = vim.deepcopy(self.default.keymaps)
end

---@param option string
---@return SpeedTyperSettingsSubcmd
function Settings:_create_subcmd_for_map_option(option)
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
            if
                not util.tbl_contains(
                    util.get_map_option_completion("", self.general[option]),
                    args[1]
                )
            then
                util.error(
                    ("SpeedTyperSettings %s: unknown argument '%s'"):format(data.fargs[1], args[1])
                )
                return
            end
            for opt, _ in pairs(self.general[option]) do
                self.general[option][opt] = false
            end
            self.general[option][args[1]] = true
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
        impl = function(args, data)
            if #args ~= 1 then
                util.error(
                    ("SpeedTyperSettings %s: command expects exactly one argument"):format(
                        data.fargs[1]
                    )
                )
                return
            end
            if not util.tbl_contains(util.get_bool_option_completion(""), args[1]) then
                util.error(
                    ("SpeedTyperSettings %s: unknown argument '%s'"):format(data.fargs[1], args[1])
                )
                return
            end
            ---@type boolean
            local new_val = args[1] == "on"
            self.general[option] = new_val
            require("speedtyper.ui"):redraw()
        end,
        complete = function(subcmd_arg_lead)
            return util.get_bool_option_completion(subcmd_arg_lead)
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

function Settings:create_user_commands()
    ---@type table<string, SpeedTyperSettingsSubcmd>
    local subcmds = {
        info = self:_create_info_subcmd(),
        language = self:_create_subcmd_for_map_option("language"),
        theme = self:_create_subcmd_for_map_option("theme"),
        randomize_theme = self:_create_subcmd_for_bool_option("randomize_theme"),
        cursor_style = self:_create_subcmd_for_map_option("cursor_style"),
        cursor_blinking = self:_create_subcmd_for_bool_option("cursor_blinking"),
        pace_cursor = self:_create_subcmd_for_bool_option("pace_cursor"),
        -- TODO: pace_cursor_speed = ...
        pace_cursor_style = self:_create_subcmd_for_map_option("pace_cursor_style"),
        strict_space = self:_create_subcmd_for_bool_option("strict_space"),
        stop_on_error = self:_create_subcmd_for_bool_option("stop_on_error"),
        confidence_mode = self:_create_subcmd_for_bool_option("confidence_mode"),
        indicate_typos = self:_create_subcmd_for_bool_option("indicate_typos"),
        sound_volume = self:_create_subcmd_for_map_option("sound_volume"),
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

    vim.api.nvim_create_user_command("SpeedTyperSettings", cmd, {
        desc = "Change SpeedTyper settings.",
        complete = cmd_completion,
        nargs = "*",
    })
end

return Settings.new()
