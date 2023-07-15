# BCDice

[![Action Status](https://github.com/bcdice/BCDice/workflows/Test/badge.svg?branch=master)](https://github.com/bcdice/BCDice/actions)
[![Gem Version](https://badge.fury.io/rb/bcdice.svg)](https://badge.fury.io/rb/bcdice)
[![YARD](https://img.shields.io/badge/yard-docs-blue.svg)](https://yard.bcdice.org/)
[![codecov](https://codecov.io/gh/bcdice/BCDice/branch/master/graph/badge.svg)](https://codecov.io/gh/bcdice/BCDice)
[![Discord](https://img.shields.io/discord/597133335243784192.svg?color=7289DA&logo=discord&logoColor=fff)][invite discord]

様々なTRPGシステムの判定に対応したオンセツール用ダイスコマンドエンジン


## Documents

- [BCDiceコマンドガイド](https://docs.bcdice.org/)
- [ロードマップ](ROADMAP.md)
- [ChangeLog](CHANGELOG.md)
- [ダイスボットの作り方](docs/how_to_make_dicebot.md)
- [Pull Requestを送る前に確認したいこと](https://github.com/bcdice/BCDice/wiki/Pull-Requestを送る前に確認したいこと)

## バグ報告や機能要望

BCDiceの問題を発見したり、機能の要望がある時に起こすアクションの一例は以下のようなものがあります。

1. Discordの [BCDice Offcial Chat][invite discord] にある各種チャンネルへ投稿する (迷ったらここ!)
2. Twitterで [@ysakasin](https://twitter.com/ysakasin) にメンションを送る
3. [問い合わせフォーム](https://forms.gle/yquupEAKbBTHzYF8A)から問い合わせる
4. GitHubの issue や Pull Request を作成する （GitとGitHubがわかる人向け）

## Quick Start

```ruby
require "bcdice"
require "bcdice/game_system" # 全ゲームシステムをロードする

cthulhu7th = BCDice.game_system_class("Cthulhu7th")
result = cthulhu7th.eval("CC<=25") #=> #<BCDice::Result>
result.text      #=> "(1D100<=25) ボーナス・ペナルティダイス[0] ＞ 1 ＞ 1 ＞ クリティカル"
result.success?  #=> true
result.critical? #=> true
```

```ruby
require "bcdice"
require "bcdice/user_defined_dice_table"

text = <<~TEXT
  飲み物表
  1D6
  1:水
  2:緑茶
  3:麦茶
  4:コーラ
  5:オレンジジュース
  6:選ばれし者の知的飲料
TEXT
result = BCDice::UserDefinedDiceTable.eval(text) #=> #<BCDice::Result>
result.text #=> "飲み物表(6) ＞ 選ばれし者の知的飲料"
```

## LICENSE

[BSD 3-Clause License](LICENSE)


[invite discord]:https://discord.gg/x5MMKWA
