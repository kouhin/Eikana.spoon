# Eikana.spoon

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

English | [日本語](README.ja.md) | [简体中文](README.zh-CN.md)

A [Hammerspoon](https://www.hammerspoon.org/) Spoon for switching macOS input methods by pressing a modifier key by itself. Inspired by [cmd-eikana](https://github.com/iMasanari/cmd-eikana).

By default:

| Key | Action |
| --- | --- |
| Left Command | Switch to `Romaji` |
| Right Command | Switch to `Hiragana` |

You can also map `cmd`, `rightcmd`, `alt`, `rightalt`, `shift`, `rightshift`, `ctrl`, and `rightctrl` to other enabled macOS input methods.

## Requirements

- macOS
- [Hammerspoon](https://www.hammerspoon.org/)
- The target input methods must already be enabled in macOS System Settings.

## Installation

Download `Eikana.spoon.zip` from [Releases](https://github.com/kouhin/Eikana.spoon/releases/latest), then extract `Eikana.spoon` into `~/.hammerspoon/Spoons`.

Add the following to your Hammerspoon config file, `~/.hammerspoon/init.lua`:

```lua
hs.loadSpoon("Eikana")
spoon.Eikana:start()
```

Reload Hammerspoon. You can now press left Command for Romaji and right Command for Hiragana.

## Configuration

Add Eikana configuration to `~/.hammerspoon/init.lua`. Configuration options must be set before `spoon.Eikana:start()`.

### Add Custom Mappings

`userMapping` adds new mappings or overrides individual default mappings.

```lua
hs.loadSpoon("Eikana")

spoon.Eikana.userMapping = {
  rightcmd = "Pinyin – Simplified",
  rightalt = "Wubi – Simplified",
}

spoon.Eikana:start()
```

### Replace All Defaults

Set `override = true` if you do not want the built-in left/right Command mappings.

```lua
hs.loadSpoon("Eikana")

spoon.Eikana.override = true
spoon.Eikana.userMapping = {
  cmd = "Romaji",
  rightcmd = "Hiragana",
  rightalt = "Pinyin – Simplified",
}

spoon.Eikana:start()
```

### SpoonInstall

If you use [SpoonInstall](https://www.hammerspoon.org/Spoons/SpoonInstall.html), put this in `~/.hammerspoon/init.lua`. SpoonInstall applies the `config` table before calling `start = true`.

```lua
hs.loadSpoon("SpoonInstall")

spoon.SpoonInstall.repos.Eikana = {
  url = "https://github.com/kouhin/Eikana.spoon",
  desc = "Eikana spoon repository",
  branch = "main",
}

spoon.SpoonInstall:andUse("Eikana", {
  repo = "Eikana",
  config = {
    userMapping = {
      rightalt = "Pinyin – Simplified",
    },
  },
  start = true,
})
```

## Input Method Names

Custom mappings must use the exact input method name reported by Hammerspoon.

1. Open the Hammerspoon Console.
2. Type this command, but do not run it yet:

```lua
hs.keycodes.currentMethod()
```

3. Switch macOS to the input method you want to map.
4. Run the command in the Hammerspoon Console.
5. Use the returned string in `userMapping`.

## License

Eikana.spoon is released under the [MIT License](LICENSE).
