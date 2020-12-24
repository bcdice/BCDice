# frozen_string_literal: true

require "bcdice"

module BCDice
  module GameSystem
    class AlchemiaStruggle < Base
      ID = "AlchemiaStruggle"
      NAME = "アルケミア・ストラグル"
      SORT_KEY = "あるけみあすとらくる"

      HELP_MESSAGE = <<~MESSAGETEXT
        ■ ダイスロール（ XAS ）
          ＸＤをロールします。
          例） 5AS
        
        ■ ダイスロール＆最大になるようにピック（ XASY ）
          ＸＤをロールし、そこから最大になるようにＹ個をピックします。
          例） 4AS3
      MESSAGETEXT

      ROLL_REG = /^(\d+)AS(\d+)?$/i.freeze

      register_prefix('\\d+AS')

      def eval_game_system_specific_command(command)
        try_roll_alchemia(command)
      end

      def try_roll_alchemia(command)
        if command.match? ROLL_REG
          match = ROLL_REG.match command

          roll_dice_count = match[1].to_i

          if match[2].nil?
            # ロールのみ（ピックなし）:

            result = roll_alchemia(roll_dice_count)
            return make_roll_text(result)
          else
            # ロールして最大値をピック:

            pick_dice_count = match[2].to_i

            result = roll_alchemia_and_pick(roll_dice_count, pick_dice_count)
            return make_roll_and_pick_text(result[:rolled_dices], pick_dice_count, result[:picked_dices])
          end
        end
      end

      def roll_alchemia(roll_dice_count)
        @randomizer.roll_barabara(roll_dice_count, 6)
      end

      def roll_alchemia_and_pick(roll_dice_count, pick_dice_count)
        rolled_dice_list = roll_alchemia(roll_dice_count)

        return {
          rolled_dices: rolled_dice_list,
          picked_dices: pick_maximum(rolled_dice_list, pick_dice_count),
        }
      end

      def pick_maximum(dice_list, pick_dice_count)
        if dice_list.size <= pick_dice_count
          dice_list
        else
          dice_list.sort[-pick_dice_count..-1]
        end
      end

      def make_roll_text(rolled_dice_list)
        "(#{rolled_dice_list.size}D) ＞ #{make_dice_text(rolled_dice_list)}"
      end

      # 実際にピックできた数と要求されたピック数は一致しないケースが（ルール上）あるため、 pick_dice_count はパラメータとして受ける必要がある。
      def make_roll_and_pick_text(rolled_dice_list, pick_dice_count, picked_dice_list)
        "(#{rolled_dice_list.size}D>>#{pick_dice_count}D) ＞ #{make_dice_text(rolled_dice_list)} >> #{make_dice_text(picked_dice_list)} ＞ #{picked_dice_list.sum}"
      end

      def make_dice_text(dice_list)
        "[#{dice_list.sort.join ', '}]"
      end
    end
  end
end
