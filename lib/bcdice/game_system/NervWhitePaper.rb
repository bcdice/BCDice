# frozen_string_literal: true

module BCDice
  module GameSystem
    class NervWhitePaper < Base
      # ゲームシステムの識別子
      ID = 'NervWhitePaper'

      # ゲームシステム名
      NAME = '新世紀エヴァンゲリオンRPG NERV白書/使徒降臨'

      # ゲームシステム名の読みがな
      SORT_KEY = 'しんせいきえうあんけりおんああるひいしいねるふはくしよしとこおりん'

      # ダイスボットの使い方
      HELP_MESSAGE = <<~INFO_MESSAGETEXT
        ■通常ロール(NR)：成功、失敗、絶対成功、絶対失敗を表示します。
        例) NR

        ■長所ロール(NA)：成功、失敗、絶対成功、絶対失敗を表示します。
        例) NA

        ■短所ロール(ND)：成功、失敗、絶対成功、絶対失敗を表示します。
        例) ND

      INFO_MESSAGETEXT

      register_prefix('N[RAD]')

      def eval_game_system_specific_command(command)
        resolute_regular_action(command) ||
          resolute_advantage_action(command) ||
          resolute_disadvantage_action(command)
      end

      private

      # 通常ロールによる判定
      # @param [String] command
      # @return [Result]
      def resolute_regular_action(command)
        m = /NR/.match(command)
        return nil unless m

        dices = @randomizer.roll_barabara(2, 6)
        dice_text = dices.join(",")
        dice_add = dices.sum

        output = "(NR) ＞ #{dice_text}"

        if dice_add == 7
          output += " ＞ 絶対成功"
          return Result.critical(output)
        elsif dice_add == 2
          output += " ＞ 絶対失敗"
          return Result.fumble(output)
        elsif dice_add == 12
          output += " ＞ 絶対失敗"
          return Result.fumble(output)
        elsif dice_add.modulo(2) == 0
          output += " ＞ 失敗"
          return Result.failure(output)
        else
          output += " ＞ 成功"
          return Result.success(output)
        end
      end

      # 長所ロールによる判定
      # @param [String] command
      # @return [Result]
      def resolute_advantage_action(command)
        m = /NA/.match(command)
        return nil unless m

        dices = @randomizer.roll_barabara(2, 6)
        dice_text = dices.join(",")
        dice_add = dices.sum

        output = "(NA) ＞ #{dice_text}"

        if dice_add == 7
          output += " ＞ 絶対成功"
          return Result.critical(output)
        elsif dice_add == 2
          output += " ＞ 絶対失敗"
          return Result.fumble(output)
        elsif dice_add == 12
          output += " ＞ 絶対失敗"
          return Result.fumble(output)
        elsif dices[0] == dices[1]
          output += " ＞ 失敗"
          return Result.failure(output)
        else
          output += " ＞ 成功"
          return Result.success(output)
        end
      end

      # 短所ロールによる判定
      # @param [String] command
      # @return [Result]
      def resolute_disadvantage_action(command)
        m = /ND/.match(command)
        return nil unless m

        dices = @randomizer.roll_barabara(2, 6)
        dice_text = dices.join(",")
        dice_add = dices.sum

        output = "(ND) ＞ #{dice_text}"

        if dice_add == 7
          output += " ＞ 絶対成功"
          return Result.critical(output)
        elsif dice_add == 2
          output += " ＞ 絶対失敗"
          return Result.fumble(output)
        elsif dice_add == 12
          output += " ＞ 絶対失敗"
          return Result.fumble(output)
        elsif dice_add != 7
          output += " ＞ 失敗"
          return Result.failure(output)
        end
      end
    end
  end
end
