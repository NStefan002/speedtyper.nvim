# ⌨️ Speedtyper

>Practise typing while bored.

## 📺 Showcase

https://github.com/NStefan002/speedtyper.nvim/assets/100767853/b42ed6ee-648d-4fd8-be4a-e3f3611319ef


_[GIF version of the showcase video for Github mobile users](https://github.com/NStefan002/speedtyper.nvim/assets/100767853/207f0573-86f4-4d27-bf58-90d62a1a1b3e)_


## ⚡️ Features

- **Languages**: Currently only supports English and Serbian.
- **Customized Game Duration**: Set the time limit for the game.
- **Feedback**: Receive instant updates on your words per minute (WPM) and accuracy.
- **Play Offline**: No need to connect to the internet. <!-- **_Coming soon:_** Online mode with a larger variety of words. -->
- **Distraction-Free Typing**: Temporarily disable [cmp](https://github.com/hrsh7th/nvim-cmp) to focus on the game.
- **Different game modes:**
    * _countdown_ - Type as much words as possible before the time runs out.
    * _stopwatch_ - Type an entire page of text as fast and as accurate as possible.

    **Coming soon:** _code snippets_: Enhance your coding speed and accuracy by typing various code snippets.


## 📋 Installation

[lazy](https://github.com/folke/lazy.nvim):

```lua
{
    "NStefan002/speedtyper.nvim",
    branch = "main",
    cmd = "Speedtyper",
    opts = {
    -- your config
    }
}
```

[packer](https://github.com/wbthomason/packer.nvim):

```lua
use {
    "NStefan002/speedtyper.nvim",
    branch = "main",
    config = function()
        require('speedtyper').setup({
            -- your config
        })
    end
}
```

## ⚙ Default configuration

<details>
<summary>Full list of options with their default values</summary>

```lua
{
    window = {
        height = 5,         -- integer >= 5 | float in range (0, 1)
        width = 0.55,       -- integer | float in range (0, 1)
        border = "rounded", -- "none" | "single" | "double" | "rounded" | "shadow" | "solid"
    },
    language = "en",        -- "en" | "sr" currently only only supports English and Serbian
    game_modes = {          -- prefered settings for different game modes
        -- type until time expires
        countdown = {
            time = 30,
        },
        -- type until you complete one page
        stopwatch = {
            hide_time = true, -- hide time while typing
        },
    },
    -- MORE COMING SOON
}
```

</details>

## 🧰 Commands

|   Command   |         Description        |
|-------------|----------------------------|
|  `:Speedtyper`  | Select the game mode and enjoy playing! |

## 🤝 Contributing

PRs and issues are always welcome.

## ✅☑️ TODO
See _[this](https://github.com/NStefan002/speedtyper.nvim/blob/main/TODO.md)_.

## 🎭 Inspiration

* [monkeytype](https://monkeytype.com/)

## 👀 Checkout similar projects

* **Neovim based:**
    - [duckytype.nvim](https://github.com/kwakzalver/duckytype.nvim)
* **Other:**
    - [SpeedTyper.dev](https://www.speedtyper.dev/)  Somehow I didn't know about this one until the day I made speedtyper.nvim public... My bad 😅
    - [toipe](https://github.com/Samyak2/toipe)
