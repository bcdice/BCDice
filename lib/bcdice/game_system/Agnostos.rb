# frozen_string_literal: true

module BCDice
  module GameSystem
    class Agnostos < Base
      # ゲームシステムの識別子
      ID = "Agnostos"

      # ゲームシステム名
      NAME = "アグノストス"

      # ゲームシステム名の読みがな
      SORT_KEY = "あくのすとす"

      # ダイスボットの使い方
      HELP_MESSAGE = <<~MESSAGETEXT
        ■ 行為判定
          CDx>=t
          x: コンディションレベル（A~E もしくは 5~1)
          t: 目標値
          の成否とコンディションの変動量を判定します。

        ■ 心拍のコンディションチェック
          HCDx
          x: コンディションレベル（C+, B+, A, B-, C-, もしくは 5~1）
          酸素の消費量、コンディションの変動量、気絶したかを判定します。

        ■ 必殺技
          xSPy
          x: メインコンディション（A~E もしくは 5~1)
          y: サブコンディション（A~E もしくは 5~1)
          必殺技のダメージ量を判定します。
      MESSAGETEXT

      register_prefix('CD', 'HCD', '[A-E1-5]SP[A-E1-5]')

      def eval_game_system_specific_command(command)
        condition_roll(command) || heart_condition_roll(command) || special_roll(command)
      end

      private

      # コンディションチェック
      def condition_roll(command)
        parser = Command::Parser.new(/CD[A-E1-5]/, round_type: @round_type).disable_modifier.restrict_cmp_op_to(:>=)
        parsed = parser.parse(command)
        unless parsed
          return nil
        end

        condition_level = to_condition_level(parsed.command[-1])
        sides = to_sides(condition_level)
        value = @randomizer.roll_once(sides)

        Result.new.tap do |r|
          r.critical = critical?(sides, value)
          r.fumble = fumble?(sides, value)
          r.condition = value >= parsed.target_number

          r.text = [
            "(CD#{condition_level}>=#{parsed.target_number})",
            "(1D#{sides}>=#{parsed.target_number})",
            value.to_s(),
            r.success? ? "成功" : "失敗",
            condition_change(sides, value),
          ].join(" ＞ ")
        end
      end

      def to_condition_level(char)
        case char
        when "5"
          "A"
        when "4"
          "B"
        when "3"
          "C"
        when "2"
          "D"
        when "1"
          "E"
        else
          char
        end
      end

      def to_sides(condition)
        case condition
        when "A"
          12
        when "B"
          10
        when "C"
          8
        when "D"
          6
        else # "E"
          4
        end
      end

      def condition_change(sides, value)
        if critical?(sides, value)
          "コンディション：2段階上昇（クリティカル）"
        elsif fumble?(sides, value)
          "コンディション：2段階下降（ファンブル）"
        elsif sides != 12 && sides - value <= 1
          "コンディション：1段階上昇"
        elsif sides == 12 && value <= 6
          "コンディション：1段階下降"
        elsif sides == 10 && value <= 3
          "コンディション：1段階下降"
        elsif sides == 8 && value <= 2
          "コンディション：1段階下降"
        else
          "コンディション：変動なし"
        end
      end

      def critical?(sides, value)
        sides != 12 && sides == value
      end

      def fumble?(sides, value)
        sides != 4 && value == 1
      end

      # 心拍のコンディションチェック
      def heart_condition_roll(command)
        m = /^HCD([A1-5]|[BC][+-])$/.match(command)
        unless m
          return nil
        end

        suffix = m[1]
        condition_level = to_heart_condition_level(suffix)
        sides = to_heart_sides(condition_level)
        value = @randomizer.roll_once(sides)

        Result.new.tap do |r|
          r.critical = critical?(sides, value)
          r.fumble = fumble?(sides, value)

          r.text = [
            "(HCD#{condition_level})",
            "(1D#{sides})",
            value.to_s(),
            heart_condition_change(sides, value),
          ].join(" ＞ ")
        end
      end

      def to_heart_condition_level(char)
        case char
        when "5"
          "C+"
        when "4"
          "B+"
        when "3"
          "A"
        when "2"
          "B-"
        when "1"
          "C-"
        else
          char
        end
      end

      def to_heart_sides(condition)
        case condition
        when "C+"
          12
        when "B+"
          10
        when "A"
          8
        when "B-"
          6
        else # "C-"
          4
        end
      end

      def fainted?(sides, value)
        case sides
        when 12
          value >= 7
        when 10
          value >= 10
        when 8
          false
        when 6
          value <= 1
        else # 4
          value <= 2
        end
      end

      def heart_condition_change(sides, value)
        if fainted?(sides, value)
          "気絶"
        else
          condition_change(sides, value)
        end
      end

      # 必殺技
      def special_roll(command)
        m = /^([A-E1-5])SP([A-E1-5])$/.match(command)
        unless m
          return nil
        end

        times_conditon_level = to_condition_level(m[1])
        sides_conditon_level = to_condition_level(m[2])

        times = to_times(times_conditon_level)
        sides = to_sides(sides_conditon_level)

        dice_list = @randomizer.roll_barabara(times, sides)
        value = dice_list.sum()

        return [
          "(#{times_conditon_level}SP#{sides_conditon_level})",
          "(#{times}D#{sides})",
          "#{value}[#{dice_list.join(',')}]",
          value.to_s(),
        ].join(" ＞ ")
      end

      def to_times(condition)
        case condition
        when "A"
          5
        when "B"
          4
        when "C"
          3
        when "D"
          2
        else # "E"
          1
        end
      end
    end
  end
end
