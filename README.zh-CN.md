# Eikana.spoon

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

[English](README.md) | [日本語](README.ja.md) | 简体中文

一个通过单独按下修饰键来切换 macOS 输入法的 [Hammerspoon](https://www.hammerspoon.org/) Spoon。灵感来自 [cmd-eikana](https://github.com/iMasanari/cmd-eikana)。

默认行为：

| 按键 | 动作 |
| --- | --- |
| 左 Command | 切换到 `Romaji` |
| 右 Command | 切换到 `Hiragana` |

你也可以把 `cmd`、`rightcmd`、`alt`、`rightalt`、`shift`、`rightshift`、`ctrl`、`rightctrl` 映射到其他已启用的 macOS 输入法。

## 依赖

- macOS
- [Hammerspoon](https://www.hammerspoon.org/)
- 目标输入法必须已在 macOS 系统设置中启用。

## 安装

从 [Releases](https://github.com/kouhin/Eikana.spoon/releases/latest) 下载 `Eikana.spoon.zip`，然后将 `Eikana.spoon` 解压到 `~/.hammerspoon/Spoons`。

把下面的配置写入 Hammerspoon 配置文件 `~/.hammerspoon/init.lua`：

```lua
hs.loadSpoon("Eikana")
spoon.Eikana:start()
```

重新加载 Hammerspoon 后，就可以用左 Command 切换到 Romaji，用右 Command 切换到 Hiragana。

## 配置

Eikana 的配置写在 `~/.hammerspoon/init.lua` 中。配置项必须放在 `spoon.Eikana:start()` 之前。

### 添加自定义映射

`userMapping` 可以添加新的映射，也可以覆盖单个默认映射。

```lua
hs.loadSpoon("Eikana")

spoon.Eikana.userMapping = {
  rightcmd = "Pinyin – Simplified",
  rightalt = "Wubi – Simplified",
}

spoon.Eikana:start()
```

### 替换全部默认映射

如果不想使用内置的左右 Command 映射，设置 `override = true`。

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

如果使用 [SpoonInstall](https://www.hammerspoon.org/Spoons/SpoonInstall.html)，把下面的内容写入 `~/.hammerspoon/init.lua`。SpoonInstall 会先应用 `config` 表，再执行 `start = true`。

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

## 输入法名称

自定义映射必须使用 Hammerspoon 返回的准确输入法名称。

1. 打开 Hammerspoon Console。
2. 输入下面的命令，但先不要执行：

```lua
hs.keycodes.currentMethod()
```

3. 在 macOS 中切换到你想映射的输入法。
4. 在 Hammerspoon Console 中执行该命令。
5. 将返回的字符串用于 `userMapping`。

## 许可证

Eikana.spoon 基于 [MIT License](LICENSE) 发布。
