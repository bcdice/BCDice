# frozen_string_literal: true

module BCDice
  module GameSystem
    class TalesFromTheLoop < Base
      # ゲームシステムの識別子
      ID = "TalesFromTheLoop"

      # ゲームシステム名
      NAME = "ザ・ループTRPG"

      # ゲームシステム名の読みがな
      SORT_KEY = "さるうふTRPG"

      HELP_MESSAGE = <<~TEXT
        ■ 判定コマンド(nTFLx-x+x or nTFLx+x-x)
          (必要成功数)TFL(判定ダイス数)-(修正ダイス数1)+(修正ダイス数2)
          (必要成功数)TFL(判定ダイス数)+(修正ダイス数1)-(修正ダイス数2)

        ※ 必要成功数と修正ダイス数は省略可能

        例1) 必要成功数1、判定ダイスは能力値3
              1TFL3

        例2）必要成功数不明、あるいはダイスボットの成功判定を使わない、判定ダイスは能力値3+技能1で4、アイテムの修正+1
              TFL4+1

        例3）必要成功数1、判定ダイスは能力値2+技能1で3、コンディションにチェックが2つ、アイテムの修正+1
              1TFL3-2+1
             あるいは以下のようにカッコ書きで内訳を詳細に記述することも可能。
              1TFL(2+1)-(1+1)+1
             修正ダイスのプラスとマイナスは逆でもよい。
              1TFL(2+1)+1-(1+1)
      TEXT

      COMMAND_NAME = "TFL" # コマンド名

      DIFFICULTY_INDEX = 1 # 難易度のインデックス
      DICE_POOL_INDEX = 3 # 判定値ダイスのインデックス
      ADJUSTED_SIGNED_INDEX_1 =  5 # 修正値ダイス符号のインデックス
      ADJUSTED_INDEX_1        =  6 # 修正値ダイスのインデックス
      ADJUSTED_SIGNED_INDEX_2 =  8 # 修正値ダイス符号のインデックス
      ADJUSTED_INDEX_2        =  9 # 修正値ダイスのインデックス

      register_prefix('(\d+)?(TFL)')

      def eval_game_system_specific_command(command)
        m = /\A(\d+)?(#{COMMAND_NAME})(\d+)((\+|-)(\d+))?((\+|-)(\d+))?/.match(command)
        unless m
          return ''
        end

        difficulty = m[DIFFICULTY_INDEX].to_i

        dice_pool = m[DICE_POOL_INDEX].to_i

        if m[ADJUSTED_INDEX_1]
          dice_pool = get_adjust_count(dice_pool, m[ADJUSTED_INDEX_1], m[ADJUSTED_SIGNED_INDEX_1])
        end
        if m[ADJUSTED_INDEX_1]
          dice_pool = get_adjust_count(dice_pool, m[ADJUSTED_INDEX_2], m[ADJUSTED_SIGNED_INDEX_2])
        end
        if dice_pool <= 0
          dice_pool = 1
        end

        ability_dice_text, success_dice = make_dice_roll(dice_pool)

        return make_dice_roll_text(difficulty, dice_pool, ability_dice_text, success_dice)
      end

      private

      def get_adjust_count(dice_pool, adjust_dice, adjust_signed)
        if adjust_signed == '-'
          dice_pool -= adjust_dice.to_i
        else
          dice_pool += adjust_dice.to_i
        end
        return dice_pool
      end

      def make_dice_roll_text(difficulty, dice_pool, ability_dice_text, success_dice)
        dice_count_text = "(#{dice_pool}D6) ＞ #{ability_dice_text} 成功数:#{success_dice}"
        push_dice = (dice_pool - success_dice)

        if push_dice > 0
          dice_count_text = "#{dice_count_text} 振り直し可能:#{push_dice}"
          reroll_command = "\n振り直しコマンド: #{COMMAND_NAME}#{push_dice}"
        end

        if difficulty > 0
          if success_dice >= difficulty
            return Result.success("#{dice_count_text} 成功！#{reroll_command}")
          else
            return Result.failure("#{dice_count_text} 失敗！#{reroll_command}")
          end
        end

        return "#{dice_count_text}#{reroll_command}"
      end

      def make_dice_roll(dice_pool)
        dice_list = @randomizer.roll_barabara(dice_pool, 6)
        success_dice = dice_list.count(6)

        return "[#{dice_list.join(',')}]", success_dice
      end
    end
  end
end
