# frozen_string_literal: true

module BCDice
  module GameSystem
    class Kutulu < Base
      # ゲームシステムの識別子
      ID = 'Kutulu'

      # ゲームシステム名
      NAME = 'Kutulu'

      # ゲームシステム名の読みがな
      SORT_KEY = 'くとうるう'

      # ダイスボットの使い方
      HELP_MESSAGE = <<~INFO_MESSAGETEXT
        ■判定　nKU        n: ダイス数

        例)3KU: ダイスを3個振って、その結果を表示(ギリギリでの成功も表示)

        ■対抗判定　nKR        n: ダイス数

        例)2KR: ダイスを2個振って、その結果を表示。対抗判定用の3桁の数字も出力。(大きい方が勝利)
      INFO_MESSAGETEXT

      register_prefix('\dK[UR]')

      def initialize(command)
        super(command)

        @sort_barabara_dice = true # バラバラロール（Bコマンド）でソート有
      end

      def eval_game_system_specific_command(command)
        resolute_action(command) || resolute_competition(command)
      end

      private

      # アクティヴ能力の判定
      # @param [String] command
      # @return [Result]
      def resolute_action(command)
        m = /(\d)KU/.match(command)
        return nil unless m

        num_dices = m[1].to_i

        dices = @randomizer.roll_barabara(num_dices, 6).sort
        dice_text = dices.join(",")

        output = "(#{num_dices}KU) ＞ #{dice_text}"

        success_num = dices.count { |val| val >= 4 }
        counts_4 = dices.count(4)
        if success_num > 0
          output += " ＞ 成功数#{success_num}"
          if success_num == 1 && counts_4 == 1
            output += " ＞ *ギリギリでの成功"
          end
          return Result.success(output)
        else
          output += " ＞ 失敗"
          return Result.failure(output)
        end
      end

      # 対抗判定用出力
      # @param [String] command
      # @return [Result]
      def resolute_competition(command)
        m = /(\d)KR/.match(command)
        return nil unless m

        num_dices = m[1].to_i

        dices = @randomizer.roll_barabara(num_dices, 6).sort
        dice_text = dices.join(",")

        counts_6 = dices.count(6)
        counts_5 = dices.count(5)
        success_num = dices.count { |val| val >= 4 }
        com_text = format("(%d%d%d)", success_num, counts_6, counts_5)

        output = "(#{num_dices}KR) ＞ #{dice_text} ＞ #{com_text}"

        if success_num > 0
          return Result.success(output)
        else
          return Result.failure(output)
        end
      end
    end
  end
end
