# frozen_string_literal: true

module BCDice
  module GameSystem
    class BeginningIdol < Base
      module BadStatusTable
        ITEMS = [
          "「不穏な空気」　PCの【メンタル】が減少するとき、減少する数値が1点上昇する",
          "「微妙な距離感」　【理解度】が上昇しなくなる",
          "「ガラスの心」　PCのファンブル値が1点上昇する",
          "「怪我」　幕間のとき、プロデューサーは「回想」しか行えない",
          "「信じきれない」　PC全員の【理解度】を1点低いものとして扱う",
          "「すれ違い」　PCはアイテムの使用と、リザルトフェイズに「おねがい」をすることができなくなる",
        ].freeze

        module_function

        def roll_command(randomizer, command)
          m = /^BT(\d+)?$/.match(command)
          unless m
            return nil
          end

          roll_counts = m[1]&.to_i || 1
          return roll(randomizer, roll_counts)
        end

        # @param randomizer [BCDice::Randomizer]
        # @param counts [Integer]
        def roll(randomizer, roll_counts = 1)
          if roll_counts <= 0
            return nil
          end

          dice_list = randomizer.roll_barabara(roll_counts, 6).sort
          index_list = dice_list.uniq

          result_prefix = "以下の#{index_list.size}つが発生する。\n" if index_list.size > 1
          result_text = index_list.map { |i| ITEMS[i - 1] }.join("\n")

          return "変調 ＞ [#{dice_list.join(',')}] ＞ #{result_prefix}#{result_text}"
        end
      end
    end
  end
end
