# frozen_string_literal: true

module BCDice
  module GameSystem
    class DeltaGreen < Base
      # ゲームシステムの識別子
      ID = "DeltaGreen"

      # ゲームシステム名
      NAME = "Detla Green"

      # ゲームシステム名の読みがな
      SORT_KEY = "国際化:English:DELTA GREEN"

      HELP_MESSAGE = <<~TEXT
        CC  Does a 1D100 roll
        ex) CC<=80  (Rolls using 80 as skill value)

        CCL Does a 1D100 lethality roll
        When failed, HP Damage for lithality roll is also printed.

        Ranges of Critical Success/Fumble rate for Delta Green are applied.#{'  '}
      TEXT

      register_prefix('CCL?')

      def eval_game_system_specific_command(command)
        case command
        when /^CCL/i
          dg_roll_lethality(command)
        when /^CC/i
          dg_roll(command)
        end
      end

      DOUBLEMATCH = [11, 22, 33, 44, 55, 66, 77, 88, 99].freeze

      def dg_roll(command)
        m = %r{^CC(?:<=([+-/*\d]+))?$}.match(command)
        unless m
          return nil
        end

        diff = ArithmeticEvaluator.eval(m[1])

        if diff.nil?
          diff = 0
        end

        if diff <= 0
          dice = @randomizer.roll_once(100)
          return Result.new("1D100 ＞ #{dice}")
        end

        dice = @randomizer.roll_once(100)

        result = dg_compare(dice, diff)
        result.text = "(1D100<=#{diff}) ＞ #{dice} ＞ #{result.text}"

        return result
      end

      def dg_roll_lethality(command)
        m = %r{^CCL<=([+-/*\d]+)?$}.match(command)
        unless m
          return nil
        end

        diff = ArithmeticEvaluator.eval(m[1])

        if diff.nil?
          diff = 0
        end

        if diff <= 0
          return nil
        end

        dice = @randomizer.roll_once(100)

        result = dg_compare_lithality(dice, diff)
        result.text = "(1D100<=#{diff}) ＞ #{dice} ＞ #{result.text}"

        return result
      end

      def dg_compare(dice, diff)
        if DOUBLEMATCH.include?(dice)
          if dice <= diff
            Result.critical("Critical Success")
          else
            Result.fumble("Fumble")
          end
        elsif dice == 1
          Result.critical("Critical Success")
        elsif dice == 100
          Result.fumble("Fumble")
        else
          if dice <= diff
            Result.success("Success")
          else
            Result.failure("Failure")
          end
        end
      end

      def dg_compare_lithality(dice, diff)
        if dice <= diff
          Result.success("Success")
        else
          dice_sum = dg_dice_sum(dice)
          Result.failure("Failure, #{dice_sum} HP Damage")
        end
      end

      def dg_dice_sum(dice)
        tens = (dice / 10).to_i
        if tens == 0
          tens = 10
        end

        ones = dice % 10
        if ones == 0
          ones = 10
        end

        sum = tens + ones

        return sum
      end
    end
  end
end
