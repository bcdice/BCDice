# frozen_string_literal: true

module BCDice
  module GameSystem
    class Aoharubaan < Base
      # ゲームシステムの識別子
      ID = 'Aoharubaan'

      # ゲームシステム名
      NAME = 'あおはるばーんっ'

      # ゲームシステム名の読みがな
      SORT_KEY = 'あおはるはあんつ'

      # ダイスボットの使い方
      HELP_MESSAGE = <<~HELP
        カレカノ反応表（ KR, KReaction ）
      HELP

      JUDGE_ROLL_REG = /^(1d6?|d6)(\+\d+)?(>=|=>)(\d+)$/i.freeze
      register_prefix('(1d6?|d6)(\+\d+)?(>=|=>)(\d+)')

      def eval_game_system_specific_command(command)
        command = ALIAS[command] || command

        if (m = JUDGE_ROLL_REG.match(command))
          roll_judge(m[2], m[4])
        else
          roll_tables(command, TABLES)
        end
      end

      private

      def roll_judge(modifier_expression, border_expression)
        modifier = modifier_expression ? Arithmetic.eval(modifier_expression, RoundType::FLOOR) : nil
        border = border_expression.to_i

        command_text = make_command_text(modifier, border)

        dice = @randomizer.roll_once(6)
        score = dice + modifier.to_i

        is_success = score >= border # 「成功」か？
        is_right = is_success && score == border # 「ピタリ賞」か？
        is_excellent = is_success && score >= 7 # 「限界突破」か？

        result_elements = []
        result_elements << (is_success ? '成功' : '失敗')
        result_elements << "ピタリ賞" if is_right
        result_elements << "限界突破" if is_excellent

        message_elements = []
        message_elements << command_text
        message_elements << "#{dice}+#{modifier}" if modifier
        message_elements << score
        message_elements << result_elements.join(" ＆ ")

        Result.new(message_elements.join(' ＞ ')).tap do |r|
          r.condition = is_success
          r.critical = is_right || is_excellent
        end
      end

      def make_command_text(modifier, border)
        command = "1D6"
        command = "#{command}+#{modifier}" if modifier
        command = "#{command}>=#{border}"
        "(#{command})"
      end

      ALIAS = {
        "KR" => "KReaction",
      }.transform_keys(&:upcase).transform_values(&:upcase).freeze

      TABLES = {
        "KReaction" => DiceTable::RangeTable.new(
          "カレカノ反応表",
          "1D6",
          [
            [1..2, "何となく素っ気ない気がする。"],
            [3..4, "いつもと変わらない安心感。"],
            [5..6, "何故だかすごくデレてきた！　嬉しくて〈テンション〉１回復。"],
          ]
        ),
      }.transform_keys(&:upcase).freeze

      register_prefix(ALIAS.keys, TABLES.keys)
    end
  end
end
