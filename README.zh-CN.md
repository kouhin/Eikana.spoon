# Eikana.spoon

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

[English](README.md) | [日本語](README.ja.md) | 简体中文

一个通过单独按下修饰键，并使用 source ID 切换 macOS 输入源的 [Hammerspoon](https://www.hammerspoon.org/) Spoon。灵感来自 [cmd-eikana](https://github.com/iMasanari/cmd-eikana)。

Eikana 主要适合两类使用场景：

- 使用 US 键盘输入日文的用户，可以用左右 Command 键获得类似 JIS 键盘「英数/かな」的一键英文/日文切换体验。
- 使用 JIS 键盘但主要输入非日文的用户，可以把 `Eisuu` / `Kana` 键改造成自己的输入源切换键。

默认行为：

| 按键 | 动作 |
| --- | --- |
| 左 Command | 切换到 `com.apple.keylayout.ABC` |
| 右 Command | 切换到 `com.apple.inputmethod.Kotoeri.RomajiTyping.Japanese` |

你也可以把 `cmd`、`rightcmd`、`alt`、`rightalt`、`shift`、`rightshift`、`ctrl`、`rightctrl`、`eisuu`、`kana` 映射到其他已启用的 macOS 输入源 ID。

## 依赖

- macOS
- [Hammerspoon](https://www.hammerspoon.org/)
- 目标输入源必须已在 macOS 系统设置中启用。

## 安装

从 [Releases](https://github.com/kouhin/Eikana.spoon/releases/latest) 下载 `Eikana.spoon.zip`，然后将 `Eikana.spoon` 解压到 `~/.hammerspoon/Spoons`。

把下面的配置写入 Hammerspoon 配置文件 `~/.hammerspoon/init.lua`：

```lua
hs.loadSpoon("Eikana")
spoon.Eikana:start()
```

重新加载 Hammerspoon 后，就可以用左 Command 切换到 ABC，用右 Command 切换到日文输入。

## 配置

Eikana 的配置写在 `~/.hammerspoon/init.lua` 中。配置项必须放在 `spoon.Eikana:start()` 之前。

### 添加自定义映射

`userMapping` 可以添加新的映射，也可以覆盖单个默认映射。值必须是 macOS 输入源 ID。`eisuu` 和 `kana` 只有在显式配置时才会被 Eikana 接管原始按键行为。

```lua
hs.loadSpoon("Eikana")

spoon.Eikana.userMapping = {
  rightcmd = "com.apple.inputmethod.Kotoeri.RomajiTyping.Japanese",
  rightalt = "com.apple.inputmethod.SCIM.WBX",
  kana = "com.apple.inputmethod.SCIM.WBX",
}

spoon.Eikana:start()
```

### 替换全部默认映射

如果不想使用内置的左右 Command 映射，设置 `override = true`。

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
      rightalt = "com.apple.inputmethod.SCIM.WBX",
      kana = "com.apple.inputmethod.SCIM.WBX",
    },
  },
  start = true,
})
```

## 输入源 ID

自定义映射必须使用输入源 ID，而不是本地化后的输入法名称。

打开 Hammerspoon Console，运行下面的命令可以列出所有已启用输入源的名称和 ID：

```lua
spoon.Eikana:listInputSources()
```

只查看当前输入源 ID：

```lua
hs.keycodes.currentSourceID()
```

常见 ID：

| 输入源 | Source ID |
| --- | --- |
| ABC | `com.apple.keylayout.ABC` |
| U.S. | `com.apple.keylayout.US` |
| 拼音键盘布局 | `com.apple.keylayout.PinyinKeyboard` |
| 日文 - 平假名 | `com.apple.inputmethod.Kotoeri.RomajiTyping.Japanese` |
| 日文 - 假名输入 | `com.apple.inputmethod.Kotoeri.KanaTyping.Japanese` |
| 五笔画 - 简体 | `com.apple.inputmethod.SCIM.WBX` |
| 拼音 - 繁体 | `com.apple.inputmethod.TCIM.Pinyin` |

ID 可能随 macOS 版本和安装的输入法变化。建议使用 `spoon.Eikana:listInputSources()` 获取你机器上的准确值。

## 许可证

Eikana.spoon 基于 [MIT License](LICENSE) 发布。
