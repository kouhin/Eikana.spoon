# Eikana.spoon

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

English | [日本語](README.ja.md) | [简体中文](README.zh-CN.md)

A [Hammerspoon](https://www.hammerspoon.org/) Spoon that lets you switch macOS input sources by pressing a modifier key by itself. Inspired by [cmd-eikana](https://github.com/iMasanari/cmd-eikana).

Eikana is useful in two common setups:

- US keyboard users who type Japanese can get JIS-style one-key English/Japanese switching with the left and right Command keys.
- JIS keyboard users who do not primarily type Japanese can remap the `Eisuu` and `Kana` keys to switch to their own input sources.

By default:

| Key | Action |
| --- | --- |
| Left Command | Switch to English (ABC) |
| Right Command | Switch to Japanese |

You can also map `cmd`, `rightcmd`, `alt`, `rightalt`, `shift`, `rightshift`, `ctrl`, `rightctrl`, `eisuu`, and `kana` to other enabled macOS input source IDs.

## Requirements

- macOS
- [Hammerspoon](https://www.hammerspoon.org/)
- The target input sources must already be enabled in macOS System Settings.
- Optional: [macism](https://github.com/laishulu/macism), if you experience input-method switching problems.

## Installation

Download `Eikana.spoon.zip` from [Releases](https://github.com/kouhin/Eikana.spoon/releases/latest), then extract `Eikana.spoon` into `~/.hammerspoon/Spoons`.

Add the following to your Hammerspoon config file, `~/.hammerspoon/init.lua`:

```lua
hs.loadSpoon("Eikana")
spoon.Eikana:start()
```

Reload Hammerspoon. You can now press left Command for ABC and right Command for Japanese.

### Improve input switching (optional)

If the menu bar shows your chosen input method but typing still produces English letters, you can install [macism](https://github.com/laishulu/macism) to help with this problem.

Install it with Homebrew:

```sh
brew tap laishulu/homebrew
brew install macism
```

Then reload your Hammerspoon configuration. Eikana automatically uses macism when it is installed; your existing key mappings need no changes. You can also use Eikana without macism.

After installing or removing macism, reload Hammerspoon again. If switching still does not work, open the Hammerspoon Console to check whether macism was detected and look for any error messages.

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
