# ✅☑️ TODO

List of planned features and bug fixes.

## General (changes that users will notice)

- [x] change highlight groups
- [ ] update README
  - [ ] add screenshots and gifs
- [ ] rain mode (does not count towards stats, it's just for fun)
- [ ] make independent ui
  - [x] hover instructions
  - [x] select game modes in the speedtyper ui (instead of `vim.ui.select` like in v1)
  - [ ] display requested info in the speedtyper ui
- [x] punctuation game modifier
- [x] numbers game modifier
- [ ] if the pace cursor has the same style as the real cursor, then it should be highlighted differently
- [ ] Stats
  - [x] wpm
  - [x] raw wpm
  - [x] accuracy
  - [x] total time
  - [ ] consistency (maaaybe)
  - [ ] Additional stats and units (the user selects which ones to display)
    - [ ] wps, cps, cpm
  - [ ] save stats
  - [ ] detect AFK
- [x] Instructions
  - [x] show how each thing is calculated in a pop-up window on 'K' (like lsp.hover)
  - [x] show each game mode details in a pop-up window (like lsp.hover)
- [ ] Settings
  - [x] fully (or almost fully) remove config and the 'standard' way of configuring plugin
  - [x] if no arguments are passed to `:SpeedtyperSettings <option>` then show the current value
  - [x] customize settings in the ~~ui~~ commandline and refresh them live
  - [x] save settings in json somewhere
  - [x] language
  - [x] theme
  - [x] cursor_style
  - [x] cursor_blinking
  - [x] pace_cursor
  - [x] make sure that the pace_cursor `move_up` logic is good
  - [x] pace_cursor_speed
  - [x] pace_cursor_style
  - [ ] pace_cursor_blinking
  - [x] strict_space
  - [x] stop_on_error
  - [x] confidence_mode
  - [x] indicate_typos
  - [x] sound_volume (pplay, mpv, ffmpeg->ffplay, cvlc, mplayer, sox->play)
  - [x] sound_on_keypress
  - [x] sound_on_typo
  - [ ] sound_on_notification
  - [ ] sound_on_game_end (or something like that, maybe)
  - [x] live_progress
  - [ ] average_speed
  - [ ] average_accuracy
  - [ ] rain_direction
  - [ ] rain_lives
  - [ ] rain_starting_speed
  - [ ] rain_speed_increase
  - [x] demojify
  - [x] debug_mode
  - [x] reset settings
  - [x] stop_on_error and confidence_mode can collide, fix it

## Internal (code related stuff)

- [x] Rewrite plugin
- [x] Add tests
- [ ] more tests
- [ ] more logging
- [x] move `lua/speedtyper/langs/` to `assets/languages`
- [x] Add vimdoc ci
- [x] create `health.lua` for dependencies
- [ ] avoid using `nil` for integer values (see hover and pace_cursor)
- [ ] rework `stats.lua`
- [x] get rid of magic constants
- [x] use `nvim_strwidth` instead of `#str` (because of non-ASCII characters)
- [x] avoid `closing` and `active` and just check if the buf/win is valid
- [x] use `vim.g` instead of `speedtyper.globals`
- [ ] use `vim.tbl_get()` to get values from tables (mainly for settings)
- [ ] move `util.notify()` to a separate module, and play sounds when notifying
