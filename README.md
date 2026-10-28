# Eikana.spoon

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

English | [日本語](README.ja.md) | [简体中文](README.zh-CN.md)

A [Hammerspoon](https://www.hammerspoon.org/) Spoon for switching macOS input sources by source ID when you press a modifier key by itself. Inspired by [cmd-eikana](https://github.com/iMasanari/cmd-eikana).

Eikana is useful in two common setups:

- US keyboard users who type Japanese can get JIS-style one-key English/Japanese switching with the left and right Command keys.
- JIS keyboard users who do not primarily type Japanese can remap the `Eisuu` and `Kana` keys to switch to their own input sources.

By default:

| Key | Action |
| --- | --- |
| Left Command | Switch to `com.apple.keylayout.ABC` |
| Right Command | Switch to `com.apple.inputmethod.Kotoeri.RomajiTyping.Japanese` |

You can also map `cmd`, `rightcmd`, `alt`, `rightalt`, `shift`, `rightshift`, `ctrl`, `rightctrl`, `eisuu`, and `kana` to other enabled macOS input source IDs.

## Requirements

- macOS
- [Hammerspoon](https://www.hammerspoon.org/)
- The target input sources must already be enabled in macOS System Settings.
- Recommended: [macism](https://github.com/laishulu/macism) 4.0 or later, if you switch to input methods other than Japanese. See [Switching to Input Methods](#switching-to-input-methods).

## Installation

Download `Eikana.spoon.zip` from [Releases](https://github.com/kouhin/Eikana.spoon/releases/latest), then extract `Eikana.spoon` into `~/.hammerspoon/Spoons`.

Add the following to your Hammerspoon config file, `~/.hammerspoon/init.lua`:

```lua
hs.loadSpoon("Eikana")
spoon.Eikana:start()
```

Reload Hammerspoon. You can now press left Command for ABC and right Command for Japanese.

## Configuration

Add Eikana configuration to `~/.hammerspoon/init.lua`. Configuration options must be set before `spoon.Eikana:start()`.

### Add Custom Mappings

`userMapping` adds new mappings or overrides individual default mappings. Values are macOS input source IDs. `eisuu` and `kana` are only intercepted when you configure them explicitly.

```lua
hs.loadSpoon("Eikana")

spoon.Eikana.userMapping = {
  rightcmd = "com.apple.inputmethod.Kotoeri.RomajiTyping.Japanese",
  rightalt = "com.apple.inputmethod.SCIM.WBX",
  kana = "com.apple.inputmethod.SCIM.WBX",
}

spoon.Eikana:start()
```

### Replace All Defaults

Set `override = true` if you do not want the built-in left/right Command mappings.

```lua
hs.loadSpoon("Eikana")

spoon.Eikana.override = true
spoon.Eikana.userMapping = {
  cmd = "com.apple.keylayout.ABC",
  rightcmd = "com.apple.inputmethod.Kotoeri.RomajiTyping.Japanese",
  rightalt = "com.apple.inputmethod.SCIM.WBX",
  kana = "com.apple.inputmethod.SCIM.WBX",
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
      rightalt = "com.apple.inputmethod.SCIM.WBX",
      kana = "com.apple.inputmethod.SCIM.WBX",
    },
  },
  start = true,
})
```

## Switching to Input Methods

When an app running in the background, such as Hammerspoon, selects a Chinese, Japanese, Korean, or Vietnamese input method with the macOS `TISSelectInputSource` API, the switch often does not take effect: the menu bar shows the new input method, but the app you are typing in keeps using the old one. To avoid this, Eikana switches differently depending on the target:

| Target | How Eikana switches |
| --- | --- |
| Keyboard layouts (`com.apple.keylayout.*`) | `TISSelectInputSource`, which is reliable for keyboard layouts |
| Japanese (`com.apple.inputmethod.Kotoeri.*.Japanese`) | Posts the `Kana` key, as a JIS keyboard does |
| Other input methods | [macism](https://github.com/laishulu/macism) when installed, otherwise `TISSelectInputSource` |

macism 4.0 and later ask the focused app to switch, the same way the Input menu in the menu bar does. Earlier versions show a temporary window instead, which briefly takes focus and can let the first characters you type go to the previous input method. Install macism from [GitHub Releases](https://github.com/laishulu/macism/releases) or with `brew install laishulu/homebrew/macism`, check the version with `macism --version`, and then reload Hammerspoon.

Eikana looks for macism in `/opt/homebrew/bin` and `/usr/local/bin`. If it is not found, Eikana logs a warning in the Hammerspoon Console at startup. To use another location, or to never use macism, set `macismPath` before `spoon.Eikana:start()`:

```lua
spoon.Eikana.macismPath = "/path/to/macism" -- or false
```

## Input Source IDs

Custom mappings must use input source IDs, not localized input method names.

In macOS, an input source can be either a keyboard layout, such as ABC or U.S., or an input method, such as Japanese or Wubi. Keyboard layouts output characters directly, while input methods use a conversion engine. Eikana can switch both kinds by source ID.

To print all enabled input source names and IDs, open the Hammerspoon Console and run:

```lua
spoon.Eikana:listInputSources()
```

To inspect the current input source ID directly:

```lua
hs.keycodes.currentSourceID()
```

Common IDs include:

| Input source | Source ID |
| --- | --- |
| English - ABC | `com.apple.keylayout.ABC` |
| English - U.S. | `com.apple.keylayout.US` |
| Japanese - Hiragana | `com.apple.inputmethod.Kotoeri.RomajiTyping.Japanese` |
| Japanese - Kana | `com.apple.inputmethod.Kotoeri.KanaTyping.Japanese` |
| Chinese - Pinyin keyboard layout | `com.apple.keylayout.PinyinKeyboard` |
| Chinese - Wubi Simplified | `com.apple.inputmethod.SCIM.WBX` |
| Chinese - Zhuyin | `com.apple.inputmethod.TCIM.Zhuyin` |

These IDs can vary by macOS version and installed input method. Prefer `spoon.Eikana:listInputSources()` for the exact values on your Mac.

## License

Eikana.spoon is released under the [MIT License](LICENSE).
