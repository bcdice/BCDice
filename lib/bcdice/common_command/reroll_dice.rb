# frozen_string_literal: true

require "bcdice/normalize"
require "bcdice/format"
require "bcdice/common_command/reroll_dice/parser"

module BCDice
  module CommonCommand
    # 個数振り足しダイス
    #
    # ダイスを振り、条件を満たした出目の個数だけダイスを振り足す。振り足しがなくなるまでこれを繰り返す。
    # 成功条件を満たす出目の個数を調べ、成功数を表示する。
    #
    # 例
    #   2R6+1R10[>3]>=5
    #   2R6+1R10>=5@>3
    #
    # 振り足し条件は角カッコかコマンド末尾の @ で指定する。
    # [>3] の場合、3より大きい出目が出たら振り足す。
    # [3] のように数値のみ指定されている場合、成功条件の比較演算子を流用する。
    # 上記の例の時、出目が
    #   "2R6"  -> [5,6] [5,4] [1,3]
    #   "1R10" -> [9] [1]
    # だとすると、 >=5 に該当するダイスは5つなので成功数5となる。
    #
    # 成功条件が書かれていない場合、成功数0として扱う。
    # 振り足し条件が数値のみ指定されている場合、比較演算子は >= が指定されたとして振舞う。
    module RerollDice
      PREFIX_PATTERN = /\d+R\d+/.freeze
      REROLL_LIMIT = 10000

      class << self
        def eval(command, game_system, randomizer)
          cmd = Parser.parse(command)
          cmd&.eval(game_system, randomizer)
        end
      end
    end
  end
end
