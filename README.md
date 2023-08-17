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

- FEATURE 1
- FEATURE ..
- FEATURE N

## 📋 Installation

[lazy](https://github.com/folke/lazy.nvim):

```lua
{
    "speedtyper.nvim",
    branch = "main",
    opts = {
    -- your config
    }
}
```

[packer](https://github.com/wbthomason/packer.nvim):

```lua
use {
    "speedtyper.nvim",
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

## 🎭 Inspiration

* [monkeytype](https://monkeytype.com/)
