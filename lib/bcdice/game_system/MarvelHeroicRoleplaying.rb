# frozen_string_literal: true

module BCDice
  module GameSystem
    class MarvelHeroicRoleplaying < Base
      # ゲームシステムの識別子
      ID = 'MarvelHeroicRoleplaying'

      # ゲームシステム名
      NAME = 'MarvelヒロイックRPG'

      # ゲームシステム名の読みがな
      SORT_KEY = 'まあへるひろいつくRPG'

      # ダイスボットの使い方
      HELP_MESSAGE = <<~INFO_MESSAGETEXT
        ■判定　MHRnDx[+nDx]        n: ダイス数 x:ダイスの面数

        例)MHR3D10+2D8+1D6: 10面ダイスを3個・8面ダイスを2個・6面ダイスを1個振って、その結果を表示(合計値,効果ダイス,チャンス)
           合計値を優先した場合と効果ダイスを優先した場合で結果が変わるケースでは双方を表示。

      INFO_MESSAGETEXT

      register_prefix('MHR')

      def initialize(command)
        super(command)

        @sort_barabara_dice = true # バラバラロール（Bコマンド）でソート有
      end

      def eval_game_system_specific_command(command)
        resolute_action(command)
      end

      private

      Dice_block = Struct.new(:counts, :sides)
      Dice_stats = Struct.new(:value, :sides, :used)

      # 判定
      # @param [String] command
      # @return [Result]
      def resolute_action(command)
        m = /MHR((\d+D\d+)(\+\d+D\d+)*)/.match(command)
        return nil unless m

        dice_str = m[1]
        dice_cmd_arr = dice_str.split("+")
        dice_block_arr = []

        dice_cmd_arr.each do |d|
          n = /(\d+)D(\d+)/.match(d)
          dice_block_arr.push(Dice_block.new(n[1].to_i, n[2].to_i))
        end
        dice_block_arr = dice_block_arr.group_by(&:sides)
                                       .map { |sides, group| Dice_block.new(group.sum(&:counts), sides) }
                                       .sort_by { |item| -item.sides }

        output = ""
        result_dice_stats_arr = []
        dice_block_arr.each do |db|
          dices = @randomizer.roll_barabara(db.counts, db.sides).sort.reverse
          dices.each do |n|
            result_dice_stats_arr.push(Dice_stats.new(n, db.sides, false))
          end
          dice_text = dices.join(",")
          output += ",D#{db.sides}[#{dice_text}]"
        end
        output.slice!(0)
        result_dice_stats_arr = result_dice_stats_arr.sort_by { |item| [-item.value, item.sides] }

        chance = result_dice_stats_arr.count { |item| item.value == 1 }
        result_dice_stats_arr.each { |item| item.used = true if item.value == 1 }

        add_dice, effect_die = result_prioritize_the_sum(result_dice_stats_arr)
        return nil if add_dice <= 0

        output_prioritize_the_sum = "合計値#{add_dice},効果ダイスD#{effect_die}"
        add_dice, effect_die = result_prioritize_effect_dice(result_dice_stats_arr)
        output_prioritize_effect_dice = "合計値#{add_dice},効果ダイスD#{effect_die}"
        if add_dice == 0 || output_prioritize_the_sum == output_prioritize_effect_dice
          output += " ＞ #{output_prioritize_the_sum}"
        else
          output += " ＞ #{output_prioritize_the_sum} or #{output_prioritize_effect_dice}"
        end

        if chance > 0
          output += " ＞ チャンス#{chance}"
          return Result.failure(output)
        else
          return Result.success(output)
        end
      end

      # 合計値優先
      def result_prioritize_the_sum(dice_stats_arr)
        result_dice_stats_arr = dice_stats_arr.map { |item| Dice_stats.new(*item.to_h.values) }

        if result_dice_stats_arr.length >= 2
          add_dice = result_dice_stats_arr[0].value + result_dice_stats_arr[1].value
          result_dice_stats_arr[0].used = true
          result_dice_stats_arr[1].used = true
        else
          return 0, 4
        end

        max_item = result_dice_stats_arr.reject(&:used)
                                        .max_by(&:sides)
        if max_item
          effect_die = max_item.sides
        else
          effect_die = 4
        end
        return add_dice, effect_die
      end

      # 効果ダイス優先
      def result_prioritize_effect_dice(dice_stats_arr)
        result_dice_stats_arr = dice_stats_arr.map { |item| Dice_stats.new(*item.to_h.values) }

        max_item = result_dice_stats_arr.reject(&:used)
                                        .min_by { |item| [-item.sides, item.value] }
        if max_item
          max_item.used = true
          effect_die = max_item.sides
        else
          effect_die = 4
        end

        result_dice_stats_arr2 = result_dice_stats_arr.reject(&:used)
        if result_dice_stats_arr2.length >= 2
          result_dice_stats_arr = result_dice_stats_arr2.sort_by { |item| [-item.value, item.sides] }
          add_dice = result_dice_stats_arr[0].value + result_dice_stats_arr[1].value
        else
          effect_die = 4
          add_dice = 0
        end

        return add_dice, effect_die
      end
    end
  end
end
