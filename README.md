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

## Input Source IDs

Custom mappings must use input source IDs, not localized input method names.

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
| ABC | `com.apple.keylayout.ABC` |
| U.S. | `com.apple.keylayout.US` |
| Pinyin keyboard layout | `com.apple.keylayout.PinyinKeyboard` |
| Japanese - Hiragana | `com.apple.inputmethod.Kotoeri.RomajiTyping.Japanese` |
| Japanese - Kana | `com.apple.inputmethod.Kotoeri.KanaTyping.Japanese` |
| Wubi - Simplified | `com.apple.inputmethod.SCIM.WBX` |
| Pinyin - Traditional | `com.apple.inputmethod.TCIM.Pinyin` |

These IDs can vary by macOS version and installed input method. Prefer `spoon.Eikana:listInputSources()` for the exact values on your Mac.

## License

Eikana.spoon is released under the [MIT License](LICENSE).
