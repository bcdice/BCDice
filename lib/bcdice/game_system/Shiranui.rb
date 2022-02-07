# frozen_string_literal: true

module BCDice
  module GameSystem
    class Shiranui < Base
      # ゲームシステムの識別子
      ID = 'Shiranui'

      # ゲームシステム名
      NAME = '不知火'

      # ゲームシステム名の読みがな
      SORT_KEY = 'しらぬい'

      # ダイスボットの使い方
      HELP_MESSAGE = <<~HELP
        ■∞D66ダイスロール
        「 ∞D66 」または「 ID66 」
        （ ID は Infinite D の略です）

        □行動力や攻撃力の指定
        「 x+∞D66 」または「 x+ID66 」
        （ x は行動力や攻撃力）

        □鬼火の使用について
        鬼火を使用する∞D66は、ダイスボットでサポートしていません。
      HELP

      INFINITE_D66_ROLL_REG = /^((\d+)\+)?(∞|I)D66$/i.freeze
      register_prefix('(\d+\+)?(∞|I)D66')

      def initialize(command)
        super(command)

        @sort_barabara_dice = true
      end

      def eval_game_system_specific_command(command)
        if (m = INFINITE_D66_ROLL_REG.match(command))
          fixed_score = m[1].nil? ? nil : m[1].to_i
          roll_infinite_d66(fixed_score)
        end
      end

      def roll_infinite_d66(fixed_score)
        steps = []

        while steps.empty? || steps.last.to_continue_diceroll?
          # 個別の出目をあつかうので、 roll_d66 ではなく roll_barabara を使う
          dices = @randomizer.roll_barabara(2, 6).sort

          steps << InifiniteD66Step.new(dices)
        end

        is_failure = steps.first.score.zero? # 「しくじり」か？
        total = is_failure ? 0 : steps.sum(&:score) + fixed_score.to_i

        result_text = "(#{self.class.make_command_text(fixed_score)})"
        result_text += " ＞ " + steps.map(&:to_s).join(' ＞ ')
        if is_failure
          result_text += " ＞ しくじり"
        else
          result_text += " ＞ " + self.class.score_expression_text(steps, fixed_score) if steps.size > 1 || !fixed_score.nil?
          result_text += " ＞ " + total.to_s
        end

        Result.new(result_text).tap do |r|
          r.critical = steps.size > 1
          r.failure = is_failure
          r.fumble = is_failure
        end
      end

      def self.make_command_text(fixed_score)
        fixed_score.nil? ? "∞D66" : "#{fixed_score}+∞D66"
      end

      def self.score_expression_text(steps, fixed_score)
        text = steps.map(&:score).join('+')
        text = "#{fixed_score}+(#{text})" unless fixed_score.nil?
        text
      end

      class InifiniteD66Step
        def initialize(dices)
          @dices = dices.dup.freeze
        end

        def score
          if repdigit?
            # ゾロ目の場合

            digit = @dices.first

            if digit == 1
              # 1 のゾロ目なら 0 となる
              0
            else
              # 1 以外のゾロ目なら、数字の 10 倍となる
              digit * 10
            end
          else
            # ゾロ目でない場合は、 D66 様式で値を算出する
            @dices[0] * 10 + @dices[1]
          end
        end

        def repdigit?
          @dices[0] == @dices[1]
        end

        # ダイスロールを継続する必要があるか？
        def to_continue_diceroll?
          repdigit? && @dices[0] != 1
        end

        def to_s
          "[#{@dices[0]},#{@dices[1]}]"
        end
      end
    end
  end
end
