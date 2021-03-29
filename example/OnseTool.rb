# frozen_string_literal: true

module BCDice
  module GameSystem
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
        - オンセツール表 (TOOLS)
      TEXT

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

      private

      def roll_ot(command)
        m = /^(\d)+OT>=(\d+)$/.match(command)
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
    end
  end
end
