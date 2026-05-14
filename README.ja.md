# Eikana.spoon

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

[English](README.md) | 日本語 | [简体中文](README.zh-CN.md)

修飾キーを単独で押すだけで、macOS の入力ソースを source ID で切り替える [Hammerspoon](https://www.hammerspoon.org/) Spoon です。[cmd-eikana](https://github.com/iMasanari/cmd-eikana) に影響を受けています。

Eikana は、主に次のような使い方に向いています。

- US キーボードで日本語を入力するユーザーが、左右 Command キーで JIS キーボードのように英数/かなを一発で切り替える。
- JIS キーボードを使う非日本語ユーザーが、`Eisuu` / `Kana` キーを自分の入力ソース切り替えキーとして使う。

デフォルトの動作:

| キー | 動作 |
| --- | --- |
| 左 Command | `com.apple.keylayout.ABC` に切り替え |
| 右 Command | `com.apple.inputmethod.Kotoeri.RomajiTyping.Japanese` に切り替え |

`cmd`、`rightcmd`、`alt`、`rightalt`、`shift`、`rightshift`、`ctrl`、`rightctrl`、`eisuu`、`kana` を、macOS で有効化済みのほかの入力ソース ID に割り当てられます。

## 必要なもの

- macOS
- [Hammerspoon](https://www.hammerspoon.org/)
- 切り替え先の入力ソースが macOS のシステム設定で有効化されていること

## インストール

[Releases](https://github.com/kouhin/Eikana.spoon/releases/latest) から `Eikana.spoon.zip` をダウンロードし、`Eikana.spoon` を `~/.hammerspoon/Spoons` に展開します。

次の設定を Hammerspoon の設定ファイル `~/.hammerspoon/init.lua` に追加します。

```lua
hs.loadSpoon("Eikana")
spoon.Eikana:start()
```

Hammerspoon をリロードすると、左 Command で ABC、右 Command で日本語入力に切り替えられます。

## 設定

Eikana の設定は `~/.hammerspoon/init.lua` に書きます。設定項目は `spoon.Eikana:start()` より前に配置してください。

### カスタム割り当てを追加する

`userMapping` で割り当てを追加したり、個別のデフォルト割り当てを上書きしたりできます。値には macOS の入力ソース ID を指定します。`eisuu` と `kana` は、明示的に設定した場合だけ Eikana が元のキー動作を引き受けます。

```lua
hs.loadSpoon("Eikana")

spoon.Eikana.userMapping = {
  rightcmd = "com.apple.inputmethod.Kotoeri.RomajiTyping.Japanese",
  rightalt = "com.apple.inputmethod.SCIM.WBX",
  kana = "com.apple.inputmethod.SCIM.WBX",
}

spoon.Eikana:start()
```

### デフォルト割り当てをすべて置き換える

組み込みの左右 Command 割り当てを使わない場合は、`override = true` を設定します。

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
      rightalt = "com.apple.inputmethod.SCIM.WBX",
      kana = "com.apple.inputmethod.SCIM.WBX",
    },
  },
  start = true,
})
```

## 入力ソース ID

カスタム割り当てには、ローカライズされた入力メソッド名ではなく、入力ソース ID を使います。

macOS の入力ソースには、ABC や U.S. のようなキーボードレイアウトと、日本語や五筆画のような入力メソッドがあります。キーボードレイアウトは文字を直接入力し、入力メソッドは変換エンジンを使います。Eikana はどちらも source ID で切り替えられます。

有効化済みの入力ソース名と ID を表示するには、Hammerspoon Console で次を実行します。

```lua
spoon.Eikana:listInputSources()
```

現在の入力ソース ID だけを確認するには、次を実行します。

```lua
hs.keycodes.currentSourceID()
```

よく使われる ID:

| 入力ソース | Source ID |
| --- | --- |
| 英語 - ABC | `com.apple.keylayout.ABC` |
| 英語 - U.S. | `com.apple.keylayout.US` |
| 日本語 - ひらがな | `com.apple.inputmethod.Kotoeri.RomajiTyping.Japanese` |
| 日本語 - かな入力 | `com.apple.inputmethod.Kotoeri.KanaTyping.Japanese` |
| 中国語 - 拼音キーボードレイアウト | `com.apple.keylayout.PinyinKeyboard` |
| 中国語 - 五筆画 簡体字 | `com.apple.inputmethod.SCIM.WBX` |
| 中国語 - 注音 | `com.apple.inputmethod.TCIM.Zhuyin` |

ID は macOS のバージョンやインストール済み入力メソッドによって異なる場合があります。自分の Mac の正確な値は `spoon.Eikana:listInputSources()` で確認してください。

## ライセンス

Eikana.spoon は [MIT License](LICENSE) のもとで公開されています。
