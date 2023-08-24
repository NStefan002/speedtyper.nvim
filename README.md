# ⌨️ Speedtyper

>Practise typing while bored.

<!-- <div align="center"> -->
<!--     > Drag your video (<10MB) here to host it for free on GitHub. -->
<!-- </div> -->
<!--  -->
<!-- <div align="center"> -->
<!--  -->
<!-- _[GIF version of the showcase video for Github mobile users](SHOWCASE_GIF_LINK)_ -->

</div>

## ⚡️ Features

- **Languages**: Currently only supports English.
- **Customized Game Duration**: Set the time limit for the game.
- **Feedback**: Receive instant updates on your words per minute (WPM) and accuracy.
- **Play Offline**: No need to connect to the internet. **_Coming soon:_** Online mode with a larger variety of words.
- **Distraction-Free Typing**: Temporarily disable [cmp](https://github.com/hrsh7th/nvim-cmp) to focus on the game.
<!-- - **Play Online and Offline**: Enjoy a broader word selection online, and still practice offline. -->

## 📋 Installation

[lazy](https://github.com/folke/lazy.nvim):

```lua
{
    "NStefan002/speedtyper.nvim",
    branch = "main",
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

<!-- ## ☄ Getting started -->
<!--  -->
<!-- > Describe how to use the plugin the simplest way -->

## ⚙ Default configuration

<details>
<summary>Full list of options with their default values</summary>

```lua
{
    time = 30,
    window = {
        height = 0.15, -- integer grater than 0 or float in range (0, 1)
        width = 0.55, -- integer grater than 0 or float in range (0, 1)
        border = "rounded", -- "none" | "single" | "double" | "rounded" | "shadow" | "solid"
    }
    language = "en" -- currently only only supports English
}
```

</details>

## 🧰 Commands

|   Command   |         Description        |
|-------------|----------------------------|
|  `:Speedtyper <time>`  |     Runs typing test with `<time>` seconds on the clock.    |
|  `:Speedtyper`  |     Runs typing test with default time setting on the clock.    |

## 🤝 Contributing

PRs and issues are always welcome.

## ✅☑️ TODO

- [ ] Add more options
- [ ] Add support for more languages
- [x] Display current game stats
- [ ] Add stats tracking

## 🎭 Inspiration

* [monkeytype](https://monkeytype.com/)
