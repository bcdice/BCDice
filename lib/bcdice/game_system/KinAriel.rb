# frozen_string_literal: true

module BCDice
  module GameSystem
    class KinAriel < Base
      # ゲームシステムの識別子
      ID = 'KinAriel'

      # ゲームシステム名
      NAME = 'キナリエル'

      # ゲームシステム名の読みがな
      SORT_KEY = 'きなりえる'

      # ダイスボットの使い方
      HELP_MESSAGE = <<~INFO_MESSAGETEXT
        ■判定　KA<=t            t: 目標値

        例)KA<=50: 目標値50で結果を表示(クリティカル、ファンブル、成功、失敗)

        ■対抗判定　VS<=t        t: 目標値

        例)VS<=50: 目標値50で最大5回振って、その結果を表示。
      INFO_MESSAGETEXT

      register_prefix('KA', 'VS')

      def eval_game_system_specific_command(command)
        resolute_action(command) || resolute_competition(command)
      end

      private

      # 通常判定
      # @param [String] command
      # @return [Result]
      def resolute_action(command)
        m = /KA<=(\d+)/.match(command)
        return nil unless m

        target = m[1].to_i
        dice = @randomizer.roll_once(100)

        output = "(KA<=#{target}) ＞ [#{dice}]"

        if dice <= target
          if dice <= 5
            output += " ＞ クリティカル"
            return Result.critical(output)
          else
            output += " ＞ 成功"
            return Result.success(output)
          end
        else
          if dice >= 96
            output += " ＞ ファンブル"
            return Result.fumble(output)
          else
            output += " ＞ 失敗"
            return Result.failure(output)
          end
        end
      end

      # 対抗判定用出力
      # @param [String] command
      # @return [Result]
      def resolute_competition(command)
        m = /VS<=(\d+)/.match(command)
        return nil unless m

        target = m[1].to_i
        output = "(VS<=#{target}) ＞ "
        dice_arr = []
        result = Result.new

        5.times do
          dice = @randomizer.roll_once(100)
          dice_arr.push(dice)
          result = get_roll_result(dice, target)
          if result.critical?
            output += '[' + dice_arr.join(",") + "] ＞ #{dice_arr.length}回目でクリティカル"
            result.text = output
            return result
          elsif result.fumble?
            output += '[' + dice_arr.join(",") + "] ＞ #{dice_arr.length}回目でファンブル"
            result.text = output
            return result
          elsif result.failure?
            output += '[' + dice_arr.join(",") + "] ＞ #{dice_arr.length}回目で失敗"
            result.text = output
            return result
          end
        end
        output += '[' + dice_arr.join(",") + "] ＞ #{dice_arr.length}回成功"
        result.text = output
        return result
      end

      def get_roll_result(dice, target)
        if dice <= target
          if dice <= 5
            return Result.critical("")
          else
            return Result.success("")
          end
        else
          if dice >= 96
            return Result.fumble("")
          else
            return Result.failure("")
          end
        end
      end
    end
  end
end
