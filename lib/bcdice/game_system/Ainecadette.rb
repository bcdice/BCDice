# frozen_string_literal: true

module BCDice
  module GameSystem
    class Ainecadette < Base
      # ゲームシステムの識別子
      ID = "Ainecadette"

      # ゲームシステム名
      NAME = "エネカデット"

      # ゲームシステム名の読みがな
      SORT_KEY = "えねかてつと"

      # ダイスボットの使い方
      HELP_MESSAGE = <<~MESSAGETEXT
        ■ 判定
        - 先輩 (AI) 10面ダイスを2つ振って判定します。『有利』なら【3AI】、『不利』なら【1AI】を使います。
        - 後輩 (CA) 6面ダイスを2つ振って判定します。『有利』なら【3CA】、『不利』なら【1CA】を使います。
      MESSAGETEXT

      register_prefix('(\d+)?AI', '(\d+)?CA')

      def eval_game_system_specific_command(command)
        roll_action(command)
      end

      private

      # 成功の目標値
      SUCCESS_THRESHOLD = 4

      # スペシャルとなる出目
      SPECIAL_DICE = 6

      def roll_action(command)
        m = /^(\d+)?(AI|CA)$/.match(command)
        return nil unless m

        is_senpai = m[2] == "AI"

        times = m[1]&.to_i || 2
        sides = is_senpai ? 10 : 6
        return nil if times <= 0

        dice_list = @randomizer.roll_barabara(times, sides)
        max = dice_list.max

        result =
          if max <= 1
            Result.fumble("ファンブル（もやもやカウンターを2個獲得）")
          elsif dice_list.include?(6)
            me = is_senpai ? "先輩" : "後輩"
            target = is_senpai ? "後輩" : "先輩"
            Result.critical("スペシャル（絆カウンターを1個獲得し、#{target}は#{me}への感情を1つ獲得）")
          elsif max >= SUCCESS_THRESHOLD
            Result.success("成功")
          else
            Result.failure("失敗")
          end

        result.text = "(#{command}) ＞ [#{dice_list.join(',')}] ＞ #{result.text}"

        return result
      end
    end
  end
end
