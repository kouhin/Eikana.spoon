# Eikana.spoon

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

[English](README.md) | 日本語 | [简体中文](README.zh-CN.md)

修飾キーを単独で押すだけで macOS の入力メソッドを切り替える [Hammerspoon](https://www.hammerspoon.org/) Spoon です。[cmd-eikana](https://github.com/iMasanari/cmd-eikana) に影響を受けています。

デフォルトの動作:

| キー | 動作 |
| --- | --- |
| 左 Command | `Romaji` に切り替え |
| 右 Command | `Hiragana` に切り替え |

`cmd`、`rightcmd`、`alt`、`rightalt`、`shift`、`rightshift`、`ctrl`、`rightctrl` を、macOS で有効化済みのほかの入力メソッドにも割り当てられます。

## 必要なもの

- macOS
- [Hammerspoon](https://www.hammerspoon.org/)
- 切り替え先の入力メソッドが macOS のシステム設定で有効化されていること

## インストール

[Releases](https://github.com/kouhin/Eikana.spoon/releases/latest) から `Eikana.spoon.zip` をダウンロードし、`Eikana.spoon` を `~/.hammerspoon/Spoons` に展開します。

次の設定を Hammerspoon の設定ファイル `~/.hammerspoon/init.lua` に追加します。

```lua
hs.loadSpoon("Eikana")
spoon.Eikana:start()
```

Hammerspoon をリロードすると、左 Command で Romaji、右 Command で Hiragana に切り替えられます。

## 設定

Eikana の設定は `~/.hammerspoon/init.lua` に書きます。設定項目は `spoon.Eikana:start()` より前に配置してください。

### カスタム割り当てを追加する

`userMapping` で割り当てを追加したり、個別のデフォルト割り当てを上書きしたりできます。

```lua
hs.loadSpoon("Eikana")

spoon.Eikana.userMapping = {
  rightcmd = "Pinyin – Simplified",
  rightalt = "Wubi – Simplified",
}

spoon.Eikana:start()
```

### デフォルト割り当てをすべて置き換える

組み込みの左右 Command 割り当てを使わない場合は、`override = true` を設定します。

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

[SpoonInstall](https://www.hammerspoon.org/Spoons/SpoonInstall.html) を使う場合は、次の内容を `~/.hammerspoon/init.lua` に書きます。SpoonInstall は `start = true` を呼ぶ前に `config` テーブルを適用します。

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

## 入力メソッド名

カスタム割り当てには、Hammerspoon が返す正確な入力メソッド名を使う必要があります。

1. Hammerspoon Console を開きます。
2. 次のコマンドを入力します。ただし、まだ実行しないでください。

```lua
hs.keycodes.currentMethod()
```

3. macOS 側で割り当てたい入力メソッドに切り替えます。
4. Hammerspoon Console でコマンドを実行します。
5. 返された文字列を `userMapping` で使います。

## ライセンス

Eikana.spoon は [MIT License](LICENSE) のもとで公開されています。
