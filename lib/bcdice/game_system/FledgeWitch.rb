# frozen_string_literal: true

module BCDice
  module GameSystem
    class FledgeWitch < Base
      # ゲームシステムの識別子
      ID = 'FledgeWitch'

      # ゲームシステム名
      NAME = 'フレッジウィッチ'

      # ゲームシステム名の読みがな
      SORT_KEY = 'ふれつしういつち'

      # ダイスボットの使い方
      HELP_MESSAGE = <<~HELP
        ■判定（ xB6>=y#z または xFW>=y#z ）
        x: ダイス数
        y: 成功ライン
        z: 必要な成功数

        □成功ラインを省略（ xB6#z または xFW#z ）
        成功ラインは 4 となる。

        □必要な成功数を省略（ xB6>=y または xFW>=y ）
        最終的な成功・失敗は表示されない。

        □成功ラインと必要な成功数を省略（ xFW ）
        成功ラインは 4 となり、最終的な成功・失敗は表示されない。
      HELP

      def initialize(command)
        super(command)

        @sort_barabara_dice = true
      end

      JUDGE_ROLL_REG = /^(\d+)(B6?|FW)((>=|=>)(\d+))?(#(\d+))?$/i.freeze
      register_prefix('(\d+)(B6?|FW)((>=|=>)(\d+))?(#(\d+))?')

      def eval_game_system_specific_command(command)
        if (m = JUDGE_ROLL_REG.match(command))
          dice_count_expression, keyword, _, _, success_line_expression, _, required_success_count_expression = m.captures

          # 汎用コマンドの xB6 と完全に同じ書式なら、判定コマンドとして扱わない.
          return nil if success_line_expression.nil? && required_success_count_expression.nil? && keyword != 'FW'

          roll_judge(dice_count_expression, success_line_expression, required_success_count_expression)
        end
      end

      private

      def roll_judge(dice_count_expression, success_line_expression, required_success_count_expression)
        dice_count = dice_count_expression.to_i
        success_line = success_line_expression ? success_line_expression.to_i : 4
        required_success_count = required_success_count_expression ? required_success_count_expression.to_i : nil

        return 'ダイス数は 1 個以上でなければなりません' if dice_count < 1

        command_text = make_command_text(dice_count, success_line, required_success_count)

        dices = @randomizer.roll_barabara(dice_count, 6).sort

        success_count = dices.sum do |dice|
          if dice >= success_line
            if dice == 6
              2 # 「６」の目なら成功数ふたつ分（ p29 ）
            else
              1
            end
          else
            0
          end
        end

        is_special = dices.count { |dice| dice == 6 } >= 2 # 「６」の目がふたつ以上なら「スペシャル」（ p30 ）
        is_success = is_special || success_count >= required_success_count if is_special || required_success_count

        message_elements = []
        message_elements << command_text
        message_elements << "[#{dices.join(',')}]"
        message_elements << "成功数: #{success_count}"
        if is_special
          message_elements << "スペシャル"
        elsif required_success_count
          message_elements << (is_success ? "成功" : "失敗")
        end

        Result.new(message_elements.join(' ＞ ')).tap do |r|
          r.condition = is_success if is_special || required_success_count
          r.critical = is_special
        end
      end

      def make_command_text(dice_count, success_line, required_success_count)
        command = "#{dice_count}B6"
        command = "#{command}>=#{success_line}"
        command = "#{command}\##{required_success_count}" unless required_success_count.nil?
        "(#{command})"
      end
    end
  end
end
