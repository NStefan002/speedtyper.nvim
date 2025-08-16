# speedtyper.nvim

Practice typing in Neovim!

## 📜 Table of Contents

- [🔥 Features](#-features)
- [📦 Installation](#-installation)
- [💻 Commands](#-commands)
- [🔧 Settings](#-settings)
- [🤝 Contributing](#-contributing)
- [🎭 Credits](#-credits)
- [👀 See Also](#-see-also)

## 🔥 Features

- Multiple modes
  - `time` - type as many words as you can in a given time
  - `words` - type a given number of words as fast as possible
  - `custom` - paste your own text and type it
  - `rain` - coming soon
- Vast amount of settings (see [settings](#-settings))
- Sounds when typing or making mistakes
- Customizable colors (see [contributing](#-contributing) if you want to submit your own colorscheme)
- Customizable keybindings
- Lots of different languages to choose from (both natural and programming languages)
- Support for utf-8 characters

## 📦 Installation

<!-- prettier-ignore -->
> [!NOTE]
> Neovim version 0.10.4 or higher is required.
>
> Nerd Fonts are optional, run `:SpeedtyperSettings demojify on` if you don't have them installed.

[lazy](https://github.com/folke/lazy.nvim):

```lua
return {
    "NStefan002/speedtyper.nvim",
    branch = "v2",
    lazy = false,
}
```

<!-- prettier-ignore -->
> [!NOTE]
> No need to lazy load this plugin, it lazy loads by default.

<!-- prettier-ignore -->
> [!NOTE]
> There is no `setup` function, all configuration is done via
> `:SpeedtyperSettings` command (see below).

## 💻 Commands

- `:Speedtyper` - toggles the speedtyper window
- `:SpeedtyperSettings <option> [value]` - change settings
- `:SpeedtyperLog` - for debugging, opens the log file, **NOTE:** logging functionality is active only if `debug_mode`
  is active

## 🔧 Settings

Settings are changed via the `:SpeedtyperSettings` command. To make this process easy and fun to use, there is built-in
autocompletion for options and values. Use `:SpeedtyperSettings info <option>` to get information about a specific
option. If you don't provide a value for an option, the current value will be shown.

<details>
<summary>See completion in action</summary>

![04 02 2025 01:24](https://github.com/user-attachments/assets/ac309c4d-0a03-4b39-97b5-363dae143f8a)

---

![04 02 2025 01:25](https://github.com/user-attachments/assets/742ccf37-87a1-44bc-a937-eddffcbedc61)

---

![04 02 2025 01:26](https://github.com/user-attachments/assets/bdcdb365-3ac7-478f-b6c3-3c2e2cbdf2f8)

</details>

## 🤝 Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).

## 🎭 Credits

- [Sounds](https://www.kenney.nl/assets/interface-sounds)
- [Languages](https://monkeytype.com)

## 👀 See Also

- [typr](https://github.com/nvzone/typr)
