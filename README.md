# Eikana.spoon

> A [cmd-eikana](https://github.com/iMasanari/cmd-eikana) like Hammerspoon spoon plugin.

## What's that?

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
})

-- Or with custom mapping

spoon.SpoonInstall:andUse("Eikana", {
  repo = "Eikana",
  config = {
    userMapping = {
      rightalt = "Pinyin - Simplified"
    }
  }
})

```

## License

MIT
