# frozen_string_literal: true

module BCDice
  module GameSystem
    class MarvelHeroicRoleplaying < Base
      # ゲームシステムの識別子
      ID = 'MarvelHeroicRoleplaying'

      # ゲームシステム名
      NAME = 'MarvelヒロイックRPG'

      # ゲームシステム名の読みがな
      SORT_KEY = 'まあへるひろいつくろうるぷれいんく'

      # ダイスボットの使い方
      HELP_MESSAGE = <<~INFO_MESSAGETEXT
        ■判定　MHRnDx[+nDx]        n: ダイス数 x:ダイスの面数

        例)MHR3D10+2D8+1D6: 10面ダイスを3個・8面ダイスを2個・6面ダイスを1個振って、その結果を表示(合計値,効果ダイス,チャンス)

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

      # 判定
      # @param [String] command
      # @return [Result]
      def resolute_action(command)
        m = /MHR((\d+D\d+)(\+\d+D\d+)*)/.match(command)
        return nil unless m

        dice_str = m[1]
        dice_cmd_arr = dice_str.split("+")
        dice_block = Struct.new(:counts, :sides)
        dice_stats = Struct.new(:value, :sides, :used)
        dice_block_arr = []

        dice_cmd_arr.each do |d|
          n = /(\d+)D(\d+)/.match(d)
          dice_block_arr.push(dice_block.new(n[1].to_i, n[2].to_i))
        end
        dice_block_arr = dice_block_arr
          .group_by(&:sides)
          .map { |sides, group| dice_block.new(group.sum(&:counts), sides) }
          .sort_by { |item| -item.sides }

        output = ""
        result_dice_stats_arr = []
        dice_block_arr.each do |db|
          dices = @randomizer.roll_barabara(db.counts, db.sides).sort.reverse
          dices.each do |n|
            result_dice_stats_arr.push(dice_stats.new(n, db.sides, false))
          end
          dice_text = dices.join(",")
          output += ",D#{db.sides}[#{dice_text}]"
        end
        output.slice!(0)
        result_dice_stats_arr = result_dice_stats_arr.sort_by { |item| [-item.value, item.sides] }

        chance = result_dice_stats_arr.count { |item| item.value == 1}
        result_dice_stats_arr.each { |item| item.used = true if item.value == 1}
        add_dice = result_dice_stats_arr[0].value + result_dice_stats_arr[1].value
        result_dice_stats_arr[0].used = true
        result_dice_stats_arr[1].used = true
        max_item = result_dice_stats_arr.select { |item| !item.used }
                                        .max_by { |item| item.sides }
        if max_item
          effect_die = max_item.sides
        else
          effect_die = 4
        end

        output += " ＞ 合計値#{add_dice},効果ダイスD#{effect_die}"

        if chance > 0
          output += ",チャンス#{chance}"
          return Result.failure(output)
        else
          return Result.success(output)
        end
      end
    end
  end
end
