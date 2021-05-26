# ダイスボットのつくりかた

## 概要

BCDiceではプログラミングを行うことで、今まで対応していなかったゲームシステムに対応したり、新たなコマンドを作成したりすることができます。
このドキュメントではBCDiceに新しいダイスボットを追加する方法をレクチャーします。


## 「ダイスボット」とは

BCDiceでは特定のTRPGに向けて作られたコマンド群を実装したプログラムのことを「ダイスボット」と呼んでいます。

もともと、「ダイスボット」という名前はテキストチャットでダイスロールができるようにするためのチャットボットのことを指しています。
「ダイス + ボット」が組み合わさって「ダイスボット」というわけですね。
BCDiceは元々IRCというテキストチャットの上で動作するチャットボットのプログラムだったため、その名残で「ダイスボット」と呼んでいます。


## BCDiceが動く環境を用意する

ダイスボットを作成するにはBCDiceが動作する環境が必要です。
Wikiにある[開発の始め方](https://github.com/bcdice/BCDice/wiki/開発の始め方)を参照して、作業環境を用意しましょう。


## 実現するダイスボットの機能を整理する

プログラミングを始める前にどんな機能を実現するのかを整理しましょう。
このドキュメントでは例として、以下のようなダイスボットを追加してみようと思います。
コマンドの機能を整理する際には、他のダイスボットのヘルプメッセージを参考にしてみてください。

- タイトル
  - オンセツールTRPG
- ID
  - OnseTool
- コマンド
  - nOT>=x
    - `nD6` のダイスロールをして、その合計が `x` を超えていたら成功。出目6が2個以上あればクリティカル。出目が全て1ならファンブル。それ以外なら失敗。
  - TOOLS
    - `1D6` のダイスロールをしてオンセツールを決定する「オンセツール決定表」を実行する。

この仕様を元に、ヘルプメッセージはこのようにしてみます。

```
■ 判定 (nOT>=x)
  nD6のダイスロールをして、その合計が x を超えていたら成功。
  出目6が2個以上あればクリティカル。出目が全て1ならファンブル。

■ 表
- オンセツール決定表 (TOOLS)
```

## プログラムの雛形を用意する

ダイスボットの作成用にプログラムのテンプレート[`example/Template.rb`](../example/Template.rb)を用意してあります。
このファイルを元に今回のファイルを作成しましょう。
例ではIDを `OnseTool` にしたので、その名前を用いて `lib/bcdice/game_system/OnseTool.rb` にファイルをコピーします。

ファイルを作成したら中身を変更していきます。

以下のように書かれているのを

```ruby
    class Template < Base
      # ゲームシステムの識別子
      ID = "Template"

      # ゲームシステム名
      NAME = "ゲームシステム名"

      # ゲームシステム名の読みがな
      SORT_KEY = "けえむしすてむめい"

      HELP_MESSAGE = <<~TEXT
        ここにヘルプメッセージを記述します。
        このように改行も含めることができます。
      TEXT
```

このように書き換えます。

```ruby
    class OnseTool < Base
      # ゲームシステムの識別子
      ID = "OnseTool"

      # ゲームシステム名
      NAME = "オンセツールTRPG"

      # ゲームシステム名の読みがな
      SORT_KEY = "おんせつうるTRPG"

      HELP_MESSAGE = <<~TEXT
        ■ 判定 (nOT>=x)
          nD6のダイスロールをして、その合計が x を超えていたら成功。
          出目6が2個以上あればクリティカル。出目が全て1ならファンブル。

        ■ 表
        - オンセツール決定表 (TOOLS)
      TEXT
```

`ID` ではファイル名と同じ英文字でのファイル名と同じ英文字での型名を、`NAME` では日本語のゲーム名を定義しています。
また、`SORT_KEY` ではゲーム名の読みがなのようなもの定義します。詳細なルールが定められているので、「[ゲームシステム名の読みがなの設定方法](./dicebot_sort_key.md)」を参照してください。


最後に、ダイスボットの一覧にこのダイスボットを加えます。[`lib/bcdice/game_system.rb`](../lib/bcdice/game_system.rb)に以下の行を追加してください。
このファイルにはアルファベット順にダイスボットが記載されているので、該当する位置に行を追加しましょう。

```ruby
require "bcdice/game_system/OnseTool"
```

ここまですれば、BCDiceでOnseToolというダイスボットを選択できるようになりました。
まだ目的のコマンドは作成していませんが、 `1D6` などの共通のコマンドは実行できるようになっています。


## 動作テストを先に用意する

BCDiceでは、ダイスボットの品質保証のために動作テスト用の仕組みを用意しています。一般には「ユニットテスト」と呼ばれます。
[`test/`](../test/)にはテストに用いるプログラムやテストのデータが入っています。
特に、[`test/data/`](../test/data/)以下にあるファイルは全てダイスボットのテストに用いるデータです。

例として[`test/data/Cthulhu.toml`](../test/data/Cthulhu.toml)を見てみましょう。抜粋を以下に示します。

```toml
[[ test ]]
game_system = "Cthulhu"
input = "CC<=60 ファンブル"
output = "(1D100<=60) ＞ 100 ＞ 致命的失敗"
failure = true
fumble = true
rands = [
  { sides = 100, value = 100 },
]

[[ test ]]
game_system = "Cthulhu"
input = "CC<=60 ファンブルは100のみ"
output = "(1D100<=60) ＞ 99 ＞ 失敗"
failure = true
rands = [
  { sides = 100, value = 99 },
]
```

テストデータにはどのような入力をして、どのような出目だった時に、どんなテキストが出力されるのが正しいか、という対応が羅列されています。
BCDiceはこのデータを解釈し、これにあった実行をしてみて出力が想定したものになっているか確かめます。
このデータは [TOML](https://toml.io/ja/v1.0.0-rc.2) という形式で記述します。
テストデータの作成にTOMLの詳細を知る必要はありませんが、記述に問題が発生したら仕様を確認してみてください。


### テストを一つ設置してみる

では例にある判定コマンド `nOT>=x` のテストを書いてみます。
2個以上の出目が6だった場合にクリティカルであるというテストデータは以下のように書いてみました。

```toml
[[ test ]]
game_system = "OnseTool"
input = "3OT>=10"
output = "(3OT>=10) ＞ 13[6,6,1] ＞ クリティカル"
rands = [
  { sides = 6, value = 6 },
  { sides = 6, value = 6 },
  { sides = 6, value = 1 },
]
```

このようにして記述したテストデータのファイルを所定の場所に作成します。
`test/data/OnseTool.toml` を作成して、クリティカルの例をファイルに書きます。

ファイルを設置したら以下のコマンドでテストを実行してみましょう。

```
bundle exec rake test:dicebots target=OnseTool
```

実行結果は以下の様になるはずです。

```
Loaded suite /Users/ysakasin/.rbenv/versions/2.5.8/lib/ruby/gems/2.5.0/gems/rake-13.0.3/lib/rake/rake_test_loader
Started
F
========================================================================================================================
     74:     result = game_system.eval()
     75:
     76:     if result.nil?
  => 77:       assert_nil(data[:output])
     78:       return
     79:     end
     80:
/Users/ysakasin/src/BCDice/test/test_game_system_commands.rb:77:in `test_diceroll'
Failure: test_diceroll[OnseTool:1:3OT>=10](TestGameSystemCommands): <"(3OT>=10) ＞ 13[6,6,1] ＞ クリティカル"> was expected to be nil.
========================================================================================================================

Finished in 0.005146 seconds.
------------------------------------------------------------------------------------------------------------------------
1 tests, 1 assertions, 1 failures, 0 errors, 0 pendings, 0 omissions, 0 notifications
0% passed
------------------------------------------------------------------------------------------------------------------------
194.33 tests/s, 194.33 assertions/s
rake aborted!
Command failed with status (1)
/Users/ysakasin/.rbenv/versions/2.5.8/bin/bundle:23:in `load'
/Users/ysakasin/.rbenv/versions/2.5.8/bin/bundle:23:in `<main>'
Tasks: TOP => test:dicebots
(See full trace by running task with --trace)
```

`1 failures` と表示されている様に、追加したテストケース１件が失敗しています。
ダイスボットの雛形を用意しただけで、まだコマンドを実装していないのでテストが通過しないわけですね。

テストを追加できたので、ここからプログラミングを進めてコマンドの処理を実装します。
実装をしたら再度テストを実行して求める挙動になっているか確認します。

テストを先に記述して、テスト → 実装 → テスト → 実装 → テストと進めていきます。
このようにテストを軸に開発を進めていく手法を「テスト駆動開発」といいます。


### テストデータの書式

先ほど書いたテストデータの書式を翻訳するとこのようになります。

```
[[ test ]]
game_system = "（ダイスボットのID）"
input = "（テストしたいコマンドのテキスト）"
output = "（出力される値）"
rands = [
  { sides = （ダイスの面数）, value = （ダイスの出目） },
  { sides = （ダイスの面数）, value = （ダイスの出目） },
  { sides = （ダイスの面数）, value = （ダイスの出目） },
]
```

`game_system` はテスト対象となるダイスボットのIDを書きます。
`input` はテストしたいコマンドを書き、それに対応する出力を `output` に記述します。
`rands` は内部で発生するダイスロールの面数と出目と順番を示しています。上から順番に使用されることになります。ダイスの数に応じて行数を調整してください。

一つのファイルにテストデータを複数書くには、上記の書式を以下のようにファイル中に列挙してください。

```
[[ test ]]
game_system = "（ダイスボットのID）"
input = "（テストしたいコマンドのテキスト）"
output = "（出力される値）"
rands = [
  { sides = （ダイスの面数）, value = （ダイスの出目） },
]

[[ test ]]
game_system = "（ダイスボットのID）"
input = "（テストしたいコマンドのテキスト）"
output = "（出力される値）"
rands = [
  { sides = （ダイスの面数）, value = （ダイスの出目） },
]

[[ test ]]
game_system = "（ダイスボットのID）"
input = "（テストしたいコマンドのテキスト）"
output = "（出力される値）"
rands = [
  { sides = （ダイスの面数）, value = （ダイスの出目） },
]
```

### テストデータをどのくらい用意したらよいか？

テストデータは少なすぎると重要な部分が漏れてしまいますし、多すぎると記述が大変で実行にも時間がかかってしまいます。
ですから、テストデータの数は少なすぎず多すぎずにしたいところです。

テストデータを書くべきポイントは「ルールブックにあるルール上の規則や細則をテストケースにする」ことです。
より具体的に言うなら、「おおよその出力パターンを網羅できているか」と「特殊なケースを網羅できているか」の２点です。
`nOT>=x` を例に考えてみましょう。
まず、このコマンドはダイスの数を制御できるため、全てのダイスのパターンを網羅することは不可能です。
しかし、このコマンドにはいくつかの出力パターンがあります。
「クリティカル」「ファンブル」「成功」「失敗」の4パターンです。
最低限この4パターンのテストがあれば、「おおよその出力パターンを網羅した」と言っていいでしょう。

ここで、 ダイスの数に1が指定された時を考えてみます。出目が6のみの場合、全ての出目が6ではありますが、クリティカルの条件「出目6が2個以上あれば」に該当しません。
このようなケースではクリティカルではない、ということを確認するテストケースがあれば「特殊なケースを記述した」と言っていいでしょう。
ゲームシステムによっては、クリティカルとファンブルの条件が同時に満たされることがあります。
このような特殊な条件下でどちらの処理が優先され、どのような出力になるのか、というのもテストデータを記述しておく必要があります。


## 判定コマンドの実装をする

最初に `nOT>=x` の実装をしましょう。

まずはダイスボットにどのような形式のコマンドがあるかを登録をする必要があります。 `register_prefix` を以下のように修正しましょう。

```ruby
      register_prefix('\d+OT>=\d+')
```

`register_prefix` というメソッドを使い、 `'\d+OT>=\d+'` を登録しました。
この文字列は正規表現相当の文字列を登録します。正規表現で `\d+` は数字を1文字以上を表しています。正規表現の詳しい記述は[Rubyリファレンスマニュアル](https://docs.ruby-lang.org/ja/latest/doc/spec=2fregexp.html)を参照してください。

つぎに実際の処理を書いていきます。
BCDiceは入力された文字列にたいして様々な前処理を行った後に、ダイスボットの `eval_game_system_specific_command` を呼び出して処理を実行させます。
そのため、ダイスボット固有のコマンドの処理はメソッド `eval_game_system_specific_command` に記述します。

```ruby
      def eval_game_system_specific_command(command)
        return roll_ot(command)
      end

      private

      def roll_ot(command)
        m = /^(\d+)OT>=(\d+)$/.match(command)
        return nil unless m

        times = m[1].to_i
        target = m[2].to_i

        dice_list = @randomizer.roll_barabara(times, 6)
        total = dice_list.sum

        result =
          if dice_list.count(6) >= 2
            "クリティカル"
          elsif dice_list.count(1) == times
            "ファンブル"
          elsif total >= target
            "成功"
          else
            "失敗"
          end

        return "(#{command}) ＞ #{total}[#{dice_list.join(',')}] ＞ #{result}"
      end
```

OTコマンドの処理を `roll_ot` に記述し、 `eval_game_system_specific_command` で呼び出すように記述しています。
一見無駄のように見えますが、このダイスボットではOTコマンド以外に表も実装します。
全部の処理が `eval_game_system_specific_command` に書かれているとメソッドの記述が長くなり、読みづらくなってしまいます。
そこでこの例のようにコマンドごとにメソッドを分けて、 `eval_game_system_specific_command` ではそれを呼び出すようにするのが良い方法です。

乱数の生成には `@randomizer` を用います。これは[`BCDice::Randomizer`](https://yard.bcdice.org/BCDice/Randomizer.html)のインスタンスです。
この例では各ダイスの出目が欲しいのでメソッド `roll_barabara` を用いています。出目一覧がいらない場合には、出目の合計値を返すメソッド `roll_sum` を使ってください。

`eval_game_system_specific_command` や `roll_ot` に対して処理できないコマンドが渡された場合には `nil` を返すことで次のメソッドに処理を移譲します。

さて、テストを再度実行してみましょう。コマンドは以下の通りです。

```
bundle exec rake test:dicebots target=OnseTool
```

今度は以下のように表示されるはずです。

```
/Users/ysakasin/src/BCDice/lib/bcdice/game_system/OnseTool.rb:37: warning: assigned but unused variable - target_value
Loaded suite /Users/ysakasin/.rbenv/versions/2.5.8/lib/ruby/gems/2.5.0/gems/rake-13.0.3/lib/rake/rake_test_loader
Started
.
Finished in 0.001021 seconds.
------------------------------------------------------------------------------------------------------------------------
1 tests, 6 assertions, 0 failures, 0 errors, 0 pendings, 0 omissions, 0 notifications
100% passed
------------------------------------------------------------------------------------------------------------------------
979.43 tests/s, 5876.59 assertions/s
```

`100% passed` とあるように、記述してテストデータに適合する結果がえられました。これでOTコマンドの実装は完了です。


### 前処理の内容

`eval_game_system_specific_command` には前処理がされた状態の文字列が引数として渡されます。
前処理は[`BCDice::Preprocessor`](../lib/bcdice/preprocessor.rb)などで以下の処理を行います。

- 一行目の半角スペースより前だけにする
- カッコ書きの数式を事前計算する
- アルファベットを大文字にする


## ダイス表の実装をする

次はオンセツール決定表を実装してみましょう。
ダイスロールして表を参照するダイス表はBCDiceはで頻出の処理です。
そのため、BCDiceはダイス表の処理を行うクラス `DiceTable::Table` を用意しています。

`eval_game_system_specific_command` の周辺を以下のように変更してみてください。

```ruby
      TABLES = {
        "TOOLS" => DiceTable::Table.new(
          "オンセツール決定表",
          "1D6",
          [
            "ココフォリア",
            "ユドナリウム",
            "TRPGスタジオ",
            "Quoridorn",
            "FoundryVTT",
            "ゆとチャadv.",
          ]
        ),
      }.freeze

      register_prefix('\d+OT>=\d+', TABLES.keys)

      def eval_game_system_specific_command(command)
        return roll_ot(command) || roll_tables(command, TABLES)
      end
```

こうすると `TOOLS` でオンセツール決定表が実行できるようになります。
定数 `TABLES` にはキーをコマンド、値を `DiceTable::Table` 関連のインスタンスを設定したハッシュを代入します。
これを `roll_tables(command, TABLES)` と実行すると `TABLES` の中に適合するものがあれば自動でダイス表を実行してくれます。

`DiceTable::Table` には表の名前、ダイスロールの記法（`nDx`のみ）、表の内容を渡すことでダイス表を定義できます。
このほかにも `DiceTable::D66Table` のように頻出の処理が [`lib/bcdice/dice_table/`](../lib/bcdice/dice_table/)ディレクトリに用意してあります。是非活用してください。


## まとめ

架空のTRPGシステム「オンセツールTRPG」への対応を例に、ダイスボットの作成方法をレクチャーしました。
ここで作成したプログラムを [`example/OnseTool.rb`](../example/OnseTool.rb) に記載していますのでぜひ活用してください。
また、[`example/OnseTool.toml`](../example/OnseTool.toml) にテストデータの作成例もあります。

このドキュメントで記述した方法は、作り方のほんの一部です。
より高度なコマンドを作成するための手がかりを以下に列挙します。

- 他のダイスボットのコードをみる
  - 最近追加されたゲームシステムは良いお手本になります。[更新履歴](https://github.com/bcdice/BCDice/blob/master/CHANGELOG.md)を見て新しいコードを探すと良いでしょう。
  - 昔からあるゲームシステムは、記述が古いこと多いので気をつけてください
- [クラス一覧](https://yard.bcdice.org/)を参照する
- [`BCDice::Command::Parser`](https://yard.bcdice.org/BCDice/Command/Parser.html) や [`BCDice::Arithmetic`](https://yard.bcdice.org/BCDice/Arithmetic.html) を活用する。
- [`BCDice::Base#initialize`](https://github.com/bcdice/BCDice/blob/master/lib/bcdice/base.rb#L77-L94) にあるようなコンストラクタによる設定の初期化を活用する。
- プログラミング言語Rubyを学ぶ

ダイスボットを作成していてわからないことがあれば、 [BCDiceのDiscordサーバー](https://discord.gg/MEcN5eP)に質問してみてください。
いままでダイスボットの作成に携わった人たちが相談に乗ってくれるはずです。
