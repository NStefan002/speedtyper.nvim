<p align="center">
    <h1 align="center">speedtyper.nvim</h2>
</p>

<p align="center">
    Practise typing while bored.
</p>

<div align="center">
    > Drag your video (<10MB) here to host it for free on GitHub.
</div>

<div align="center">

_[GIF version of the showcase video for Github mobile users](SHOWCASE_GIF_LINK)_

</div>

## ⚡️ Features

- FEATURE 1
- FEATURE ..
- FEATURE N

## 📋 Installation

<div align="center">
<table>
<thead>
<tr>
<th>Package manager</th>
<th>Snippet</th>
</tr>
</thead>
<tbody>
<tr>
<td>

[wbthomason/packer.nvim](https://github.com/wbthomason/packer.nvim)

</td>
<td>

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

</td>
</tr>
<tr>
<td>

[folke/lazy.nvim](https://github.com/folke/lazy.nvim)

</td>
<td>

```lua
{
    "speedtyper.nvim",
    branch = "main",
    opts = {
        -- your config
    }
}
```

</td>
</tr>
</tbody>
</table>
</div>

<!-- ## ☄ Getting started -->
<!--  -->
<!-- > Describe how to use the plugin the simplest way -->

## ⚙ Default configuration

<details>
<summary>Full list of options with their default values</summary>

> **Note**: The options are also available in Neovim by calling `:h speedtyper.default_opts`

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

## ⌨ Contributing

PRs and issues are always welcome.

## 🗞 Wiki

Coming soon...

## 🎭 Inspiration

* [monkeytype](https://monkeytype.com/)
