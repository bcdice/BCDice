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
          (必要成功数)TFL(判定ダイス数)+/-(修正ダイス数)

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

      register_prefix('(\d+)?(TFL)')

      def eval_game_system_specific_command(command)
        parser = Command::Parser.new(/\d*TFL\d+/)

        parsed = parser.parse(command)
        return nil unless parsed

        difficulty, dice_pool = parsed.command.split("TFL", 2).map(&:to_i)
        dice_pool += parsed.modify_number
        if dice_pool <= 0
          dice_pool = 1
        end

        ability_dice_text, success_dice = make_dice_roll(dice_pool)

        return make_dice_roll_text(difficulty, dice_pool, ability_dice_text, success_dice)
      end

      private

      def make_dice_roll_text(difficulty, dice_pool, ability_dice_text, success_dice)
        dice_count_text = "(#{dice_pool}D6) ＞ #{ability_dice_text} 成功数:#{success_dice}"
        push_dice = (dice_pool - success_dice)

        if push_dice > 0
          dice_count_text = "#{dice_count_text} 振り直し可能:#{push_dice}"
          reroll_command = "\n振り直しコマンド: TFL#{push_dice}"
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
