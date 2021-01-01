# frozen_string_literal: true

require "bcdice/common_command/upper_dice/parser"

module BCDice
  module CommonCommand
    # 上方無限ロール
    #
    # ダイスを1つ振る、その出目が閾値より大きければダイスを振り足すのを閾値未満の出目が出るまで繰り返す。
    # これを指定したダイス数だけおこない、それぞれのダイスの合計値を求める。
    # それらと目標値を比較し、成功した数を表示する。
    #
    # フォーマットは以下の通り
    # 2U4+1U6[4]>=6
    # 2U4+1U6>=6@4
    #
    # 閾値は角カッコで指定するか、コマンドの末尾に @6 のように指定する。
    # 閾値の指定が重複した場合、角カッコが優先される。
    # この時、出目が
    #   "2U4" -> 3[3], 10[4,4,2]
    #   "1U6" -> 6[4,2]
    # だとすると、 >=6 に該当するダイスは2つなので成功数2となる。
    #
    # 2U4[4]+10>=6 のように修正値を指定できる。修正値は全てのダイスに補正を加え、以下のようになる。
    #   "2U4" -> 3[3]+10=13, 10[4,4,2]+10=20
    #
    # 比較演算子が書かれていない場合、ダイスの最大値と全ダイスの合計値が出力される。
    # 全ダイスの合計値には補正値が1回だけ適用される
    # 2U4[4]+10
    #   "2U4" -> 3[3]+10=13, 10[4,4,2]+10=20
    #   最大値：20
    #   合計値：23 = 3[3]+10[4,4,2]+10
    module UpperDice
      PREFIX_PATTERN = /\d+U\d+/.freeze

      class << self
        # @param command [String]
        # @param game_system [BCDice::Base]
        # @param randomizer [BCDice::Randomizer]
        # @return [UpperDice, nil]
        def eval(command, game_system, randomizer)
          cmd = Parser.parse(command)
          cmd&.eval(game_system, randomizer)
        end
      end
    end
  end
end
