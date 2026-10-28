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
- 推荐：如果要切换到日文以外的输入法，请安装 [macism](https://github.com/laishulu/macism) 4.0 或更高版本。详见[切换到输入法](#切换到输入法)。

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

## 切换到输入法

Hammerspoon 这类在后台运行的 App 用 macOS 的 `TISSelectInputSource` API 切换到中文、日文、韩文、越南文输入法时，经常不生效：菜单栏已经显示新的输入法，但正在输入的 App 仍然使用原来的输入法。为了避免这个问题，Eikana 会根据目标选择不同的切换方式：

| 目标 | Eikana 的切换方式 |
| --- | --- |
| 键盘布局（`com.apple.keylayout.*`） | `TISSelectInputSource`，对键盘布局是可靠的 |
| 日文（`com.apple.inputmethod.Kotoeri.*.Japanese`） | 像 JIS 键盘一样发送 `Kana` 键 |
| 其他输入法 | 安装了 [macism](https://github.com/laishulu/macism) 时使用 macism，否则使用 `TISSelectInputSource` |

macism 4.0 及以上版本会像菜单栏里的输入法菜单一样，请当前拥有焦点的 App 自己切换。更早的版本改为弹出一个临时窗口，会短暂抢走焦点，切换后马上输入的头几个字符可能还会进入之前的输入法。可以从 [GitHub Releases](https://github.com/laishulu/macism/releases) 下载，或者执行 `brew install laishulu/homebrew/macism` 安装。用 `macism --version` 确认版本后，重新加载 Hammerspoon。

Eikana 会在 `/opt/homebrew/bin` 和 `/usr/local/bin` 中查找 macism。找不到时，Eikana 会在启动时向 Hammerspoon Console 输出警告。如果 macism 在其他位置，或者不想使用 macism，请在 `spoon.Eikana:start()` 之前设置 `macismPath`：

```lua
spoon.Eikana.macismPath = "/path/to/macism" -- 或 false
```

## 输入源 ID

自定义映射必须使用输入源 ID，而不是本地化后的输入法名称。

在 macOS 中，输入源既可以是 ABC、U.S. 这类键盘布局，也可以是日文、五笔画这类输入法。键盘布局会直接输出字符，输入法会经过转换引擎。Eikana 可以通过 source ID 切换这两类输入源。

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
| 英文 - ABC | `com.apple.keylayout.ABC` |
| 英文 - U.S. | `com.apple.keylayout.US` |
| 日文 - 平假名 | `com.apple.inputmethod.Kotoeri.RomajiTyping.Japanese` |
| 日文 - 假名输入 | `com.apple.inputmethod.Kotoeri.KanaTyping.Japanese` |
| 中文 - 拼音键盘布局 | `com.apple.keylayout.PinyinKeyboard` |
| 中文 - 五笔画简体 | `com.apple.inputmethod.SCIM.WBX` |
| 中文 - 注音 | `com.apple.inputmethod.TCIM.Zhuyin` |

ID 可能随 macOS 版本和安装的输入法变化。建议使用 `spoon.Eikana:listInputSources()` 获取你机器上的准确值。

## 许可证

Eikana.spoon 基于 [MIT License](LICENSE) 发布。
