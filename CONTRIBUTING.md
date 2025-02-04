# Contributing guide

Thank you for considering contributing to speedtyper.nvim! We welcome all
contributions, whether it's fixing bugs, adding new features, improving
documentation, or creating new color schemes.

## Table of contents

- [Getting started](#getting-started)
- [Commit messages / PR title](#commit-messages--pr-title)
- [CI](#ci)
- [Development](#development)
  - [Formatting](#formatting)
  - [Linting](#linting)
  - [Static type checking](#static-type-checking)
  - [Running tests](#running-tests)
  - [Manual testing](#manual-testing)
- [Creating new Color Schemes](#creating-new-color-schemes)
- [General tips when writing code](#general-tips-when-writing-code)
- [Thank you](#thank-you)

## Getting started

If you want to contribute to `speedtyper.nvim`, and you don't have a specific idea in mind, you can check the
[TODO](TODO.md) list for some ideas.

## Commit messages / PR title

Please ensure your pull request title conforms to [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/).

## CI

GitHub Actions will run the following checks on your PR:

- `busted` tests
- `luacheck` linting for lua files
- `markdownlint` linting for markdown files
- `stylua` formatting - checks if the lua files are formatted correctly

If any CI check fails, review the logs, correct any issues in your code, and
push the changes. If you're unsure, feel free to ask for assistance in the
discussions or open an issue for guidance.

## Development

We use the following tools:

### Formatting

- [`.editorconfig`](https://editorconfig.org/)
- [`stylua`](https://github.com/JohnnyMorganz/StyLua)

### Linting

- [`luacheck`](https://github.com/mpeterv/luacheck) for lua files
- [`markdownlint`](https://github.com/DavidAnson/markdownlint) for markdown files

### Static type checking

- [`lua-language-server`](https://luals.github.io/wiki/)

### Running tests

We use [`busted`](https://lunarmodules.github.io/busted/) for testing,
but with Neovim as the Lua interpreter.

You can run the test suite using `luarocks test` or `busted`. For more
information on how to set up Neovim as a Lua interpreter, see
[`nlua`](https://github.com/mfussenegger/nlua).

### Manual testing

If you want to test your contributions to `speedtyper.nvim` manually,
we recommend you set [`NVIM_APPNAME`](https://neovim.io/doc/user/starting.html#%24NVIM_APPNAME)
to something other than `nvim`, so that your test environment
doesn't interfere with your regular Neovim installation or the plugins you use.

## Creating new color schemes

Create a file in the `lua/speedtyper/themes/` directory and name it `<your_theme>.lua`.
That lua file should return a function that returns an object with type `speedtyper.hl_group`.

<details>
<summary>Here's how it's done in the `default.lua` (yours can be much more complex).</summary>

```lua
---@return speedtyper.hl_group
return function()
    return {
        ["speedtyper.hl.bg"] = { bg = "#07080d", fg = "#9b9ea4" },
        ["speedtyper.hl.cursor"] = { fg = "#a6dbff", bg = "#a6dbff" },
        ["speedtyper.hl.error"] = { fg = "#ffc0b9", underline = true },
        ["speedtyper.hl.main"] = { fg = "#a6dbff" },
        ["speedtyper.hl.sub"] = { fg = "#9b9ea4" },
        ["speedtyper.hl.text"] = { fg = "#e0e2ea" },
    }
end
```

</details>

<details>
<summary>See what each of the highlight groups colors.</summary>

![speedtyper_highlights_info](https://github.com/user-attachments/assets/5ecd6643-6e88-4f20-8e7b-47e909cd2e0a)

- - -

![speedtyper_highlights_info2](https://github.com/user-attachments/assets/22686ba5-3abd-4f63-b285-ebc87e18c9a3)

</details>

## General tips when writing code

- try to keep the codebase consistent with the existing code
- use `---@param`, `---@return`, `---@type`, etc. annotations for functions/variables
- keep functions small and focused on a single task
- write comments for complex code
- write tests for your code (if you don't know how, or if it's too complex, ask for help)

## Thank you

We appreciate your time and effort in contributing to `speedtyper.nvim`! Thank you!
