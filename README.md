# ⌨️ Speedtyper

> Practise typing while bored.

## 📺 Showcase

<h4 align="center">⌛ Countdown game mode</h4>

[speedtyper_countdown_showcase.webm](https://github.com/NStefan002/speedtyper.nvim/assets/100767853/767464b2-96d6-4ea9-9486-4aa98135d0ae)

<br>

<h4 align="center">🌧️ Rain game mode</h4>

https://github.com/NStefan002/speedtyper.nvim/assets/100767853/e84e05e9-d3f1-4fd1-91d9-4d31b5bef7e7

## ⚡️ Features

- **Different game modes:**

  - _Countdown_ :
    - **Objective:** Type as much words as possible before the time runs out.
    - **Customize Game Duration**
    - **Feedback**: Receive instant updates on your words per minute (WPM) and accuracy.
  - _Stopwatch_ :
    - **Objective:** Type an entire page of text as fast and as accurate as possible.
    - **Feedback**: Receive instant updates on your words per minute (WPM) and accuracy.
  - _Rain_ :
    - **Objective:** Words fall from the top of the screen, type them before they hit the bottom.
    - **Choose the number of lives**
    - **Customize rain speed**

  **Coming soon:** _code snippets_: Enhance your coding speed and accuracy by typing various code snippets.

- **Languages**: Currently only supports English and Serbian. There is also an option to provide a file with your prefered text.
- **Play Offline**: No need to connect to the internet. <!-- **_Coming soon:_** Online mode with a larger variety of words. -->
- **Distraction-Free Typing**: Temporarily disable [cmp](https://github.com/hrsh7th/nvim-cmp) to focus on the game.

## ✨ Recommended

- [dressing.nvim](https://github.com/stevearc/dressing.nvim)
- [nvim-notify](https://github.com/rcarriga/nvim-notify)
- patched font

## 📋 Installation

[lazy](https://github.com/folke/lazy.nvim):

```lua
{
    "NStefan002/speedtyper.nvim",
    cmd = "Speedtyper",
    opts = {
    -- your config
    }
}
```

[packer](https://github.com/wbthomason/packer.nvim):

```lua
use({
    "NStefan002/speedtyper.nvim",
    config = function()
        require("speedtyper").setup({
            -- your config
        })
    end,
})
```

## ⚙ Default configuration

<details>
<summary>Full list of options with their default values</summary>

```lua
{
    window = {
        height = 5, -- integer >= 5 | float in range (0, 1)
        width = 0.55, -- integer | float in range (0, 1)
        border = "rounded", -- "none" | "single" | "double" | "rounded" | "shadow" | "solid"
    },
    language = "en", -- "en" | "sr" currently only only supports English and Serbian
    sentence_mode = false, -- if true, whole sentences will be used
    custom_text_file = nil, -- provide a path to file that contains your custom text (if this is not nil, language option will be ignored)
    randomize = false, -- randomize words from custom_text_file
    final_words_typed_wpm = false, -- if set to true calculate wpm using the final words typed
    -- if set to false WPM is estimated by dividing the number of typed characters by 5
    game_modes = { -- prefered settings for different game modes
        -- type until time expires
        countdown = {
            time = 30,
        },
        -- type until you complete one page
        stopwatch = {
            hide_time = true, -- hide time while typing
        },
        -- NOTE: the window height will become the same as the window width
        rain = {
            initial_speed = 1.5, -- words fall down by one line every x seconds
            throttle = 7, -- increase speed every x seconds (set to -1 for constant speed)
            lives = 3,
        },
    },
    -- specify highlight group for each component
    highlights = {
        untyped_text = "Comment",
        typo = "ErrorMsg",
        clock = "ErrorMsg",
        falling_word_typed = "DiagnosticOk",
        falling_word = "Normal",
        falling_word_warning1 = "WarningMsg",
        falling_word_warning2 = "ErrorMsg",
    },
    -- this values will be restored to your prefered settings after the game ends
    vim_opt = {
        -- only applies to insert mode, while playing the game
        guicursor = nil, -- "ver25" | "hor20" | "block" | nil means do not change
    },
}
```

</details>

## 🧰 Commands

| Command       | Description                             |
| ------------- | --------------------------------------- |
| `:Speedtyper` | Select the game mode and enjoy playing! |

## 🤝 Contributing

PRs and issues are always welcome.

## ✅☑️ TODO

See _[this](https://github.com/NStefan002/speedtyper.nvim/blob/main/TODO.md)_.

## 🎭 Inspiration

- [monkeytype](https://monkeytype.com/)

## 👀 Checkout similar projects

- **Neovim based:**
  - [duckytype.nvim](https://github.com/kwakzalver/duckytype.nvim)
- **Other:**
  - [SpeedTyper.dev](https://www.speedtyper.dev/) Somehow I didn't know about this one until the day I made speedtyper.nvim public... My bad 😅
  - [toipe](https://github.com/Samyak2/toipe)
