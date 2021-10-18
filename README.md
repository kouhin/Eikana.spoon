# Eikana.spoon

> A [cmd-eikana](https://github.com/iMasanari/cmd-eikana) like Hammerspoon spoon plugin.

## What's that?

Eikana is a hammerspoon plugin that can be used to switch between alphanumeric/kana mode by pressing left / right command key only. Inspired by [cmd-eikana](https://github.com/iMasanari/cmd-eikana).

And it can also be used to switch between input methods by only pressing modifier keys (`cmd` / `rightcmd` / `alt` / `rightalt` / `shift` / `rightshift` / `ctrl` / `rightctrl`).

## Installation

Install [Hammerspoon](http://www.hammerspoon.org) and extract [Eikana.spoon.zip](https://github.com/kouhin/Eikana.spoon/releases/latest) to `~/.hammerspoon/Spoons`.

## Usage and Configuration

Load, configure, and start the plugin in `~/.hammerspoon/init.lua`:

```lua
hs.loadSpoon('Eikana')                 -- initialize the plugin
spoon.Eikana:start()                   -- enable keyboard shortcuts
```

You can bind other modifier keys with you own input methods, and even override the default key binding.

```lua
hs.loadSpoon('Eikana')                 -- initialize the plugin
spoon.Eikana.userMapping = {
  rightcmd = 'Pinyin - Simplified',
  rightalt = 'Wubi - Simplified'
}
-- Uncomment the following line to override default mapping (cmd: Eisuu, rightcmd: Kana)
-- spoon.Eikana.override = true
spoon.Eikana:start()                   -- enable keyboard shortcuts

```

## Alternative Installation

Alternatively, you can use [SpoonInstall](https://www.hammerspoon.org/Spoons/SpoonInstall.html).

``` lua
hs.loadSpoon("SpoonInstall")

spoon.SpoonInstall.repos.Eikana = {
   url = "https://github.com/kouhin/Eikana.spoon",
   desc = "Eikana spoon repository",
   branch = "main",
}

spoon.SpoonInstall:andUse("Eikana", {
  repo = "Eikana",
  start = true
})

-- Or with custom mapping

spoon.SpoonInstall:andUse("Eikana", {
  repo = "Eikana",
  config = {
    -- Uncomment the following line to override default mapping (cmd: Eisuu, rightcmd: Kana)
    -- override = true,
    userMapping = {
      rightalt = "Pinyin - Simplified"
    }
  },
  start = true
})

```

## How to get the name of the input method?

1. Open `Console` from hammperspoon menu.
2. Enter this command without executing it yet:`hs.keycodes.currentMethod()`.
3. Switch to desired input method
4. Run command

## License

MIT
