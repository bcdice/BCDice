# frozen_string_literal: true

module BCDice
  module GameSystem
    class Ryutama < Base
      # ゲームシステムの識別子
      ID = 'Ryutama'

      # ゲームシステム名
      NAME = 'りゅうたま'

      # ゲームシステム名の読みがな
      SORT_KEY = 'りゆうたま'

      # ダイスボットの使い方
      HELP_MESSAGE = <<~INFO_MESSAGE_TEXT
        ・判定
        　Rx,y>=t（x,y：使用する能力値、t：目標値）
        　1ゾロ、クリティカルも含めて判定結果を表示します
        　能力値１つでの判定は Rx>=t で行えます
        例）R8,6>=13
      INFO_MESSAGE_TEXT

      register_prefix('R')

      def initialize(command)
        super(command)
        @valid_dice_types = [20, 12, 10, 8, 6, 4, 2]
      end

      def eval_game_system_specific_command(command)
        debug('eval_game_system_specific_command begin')

        unless command =~ /^R(\d+)(,(\d+))?([+\-\d]+)?(>=(\d+))?/
          debug('unmatched!')
          return ''
        end
        debug('matched')

        dice1 = Regexp.last_match(1).to_i
        dice2 = Regexp.last_match(3).to_i
        modify_string = Regexp.last_match(4)
        difficulty = Regexp.last_match(6)

        dice1, dice2 = get_dice_type(dice1, dice2)
        if dice1 == 0
          return ''
        end

        modify_string ||= ''
        modify = ArithmeticEvaluator.eval(modify_string)
        difficulty = get_difficulty(difficulty)

        value1 = get_roll_value(dice1)
        value2 = get_roll_value(dice2)
        total = value1 + value2 + modify

        result = get_result_text(value1, value2, dice1, dice2, difficulty, total)
        unless result.empty?
          result = " ＞ #{result}"
        end

        value1_text = "#{value1}(#{dice1})"
        value2_text = (value2 == 0 ? "" : "+#{value2}(#{dice2})")
        modify_text = get_modify_string(modify)

        base_text = get_base_text(dice1, dice2, modify, difficulty)
        output = "(#{base_text}) ＞ #{value1_text}#{value2_text}#{modify_text} ＞ #{total}#{result}"
        return output
      end

      def get_dice_type(dice1, dice2)
        debug('get_dice_type begin')

        if dice2 != 0
          if valid_dice_one?(dice1)
            return dice1, dice2
          else
            return 0, 0
          end
        end

        if valid_dice?(dice1, dice2)
          return dice1, dice2
        end

        dice_base = dice1

        dice1 = dice_base / 10
        dice2 = dice_base % 10

        if valid_dice?(dice1, dice2)
          return dice1, dice2
        end

        dice1 = dice_base / 100
        dice2 = dice_base % 100

        if valid_dice?(dice1, dice2)
          return dice1, dice2
        end

        if valid_dice_one?(dice_base)
          return dice_base, 0
        end

        return 0, 0
      end

      def valid_dice?(dice1, dice2)
        return valid_dice_one?(dice1) &&
               valid_dice_one?(dice2)
      end

      def valid_dice_one?(dice)
        @valid_dice_types.include?(dice)
      end

      def get_difficulty(difficulty)
        unless difficulty.nil?
          difficulty = difficulty.to_i
        end

        return difficulty
      end

      def get_roll_value(dice)
        return 0 if dice == 0

        value = @randomizer.roll_once(dice)
        return value
      end

      def get_result_text(value1, value2, dice1, dice2, difficulty, total)
        if famble?(value1, value2)
          return "１ゾロ【１ゾロポイント＋１】"
        end

        if critical?(value1, value2, dice1, dice2)
          return "クリティカル成功"
        end

        if difficulty.nil?
          return ''
        end

        if total >= difficulty
          return "成功"
        end

        return "失敗"
      end

      def famble?(value1, value2)
        return (value1 == 1) && (value2 == 1)
      end

      def critical?(value1, value2, dice1, dice2)
        return false if value2 == 0

        if (value1 == 6) && (value2 == 6)
          return true
        end

        if (value1 == dice1) && (value2 == dice2)
          return true
        end

        return false
      end

      def get_base_text(dice1, dice2, modify, difficulty)
        base_text = "R#{dice1}"

        if dice2 != 0
          base_text += ",#{dice2}"
        end

        base_text += get_modify_string(modify)

        unless difficulty.nil?
          base_text += ">=#{difficulty}"
        end

        return base_text
      end

      def get_modify_string(modify)
        if modify > 0
          return "+" + modify.to_s
        elsif modify < 0
          return modify.to_s
        end

        return ''
      end
    end
  end
end
