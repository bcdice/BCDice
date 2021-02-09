# frozen_string_literal: true

module BCDice
  module GameSystem
    class OrgaRain < Base
      # ゲームシステムの識別子
      ID = 'OrgaRain'

      # ゲームシステム名
      NAME = '在りて遍くオルガレイン'

      # ゲームシステム名の読みがな
      SORT_KEY = 'ありてあまねくおるかれいん'

      # ダイスボットの使い方
      HELP_MESSAGE = <<~MESSAGETEXT
        判定：[n]OR(count)

        []内のコマンドは省略可能。
        「n」でダイス数を指定。省略時は「1」。
        (count)で命数を指定。「3111」のように記述。最大6つ。順不同可。

        【書式例】
        ・5OR6042 → 5dで命数「0,2,4,6」の判定
        ・6OR33333 → 6dで命数「3,3,3,3,3」の判定。
      MESSAGETEXT

      def initialize(command)
        super(command)
        @sort_add_dice = true # ダイスのソート有
      end

      register_prefix(
        '(\d+)?OR(\d{0,6})?'
      )

      def eval_game_system_specific_command(command)
        m = command.match(/(\d+)?OR(\d{0,6})$/i)
        return nil unless m

        dice_count = (m[1] || 1).to_i
        count_no = (m[2] || "").each_char.map(&:to_i).sort
        return check_roll(dice_count, count_no)
      end

      def check_roll(dice_count, count_no)
        dice_array = @randomizer.roll_barabara(dice_count, 10).sort
        dice_text = dice_array.join(',')

        result_array = []
        success = 0
        dice_array.map { |x| x == 10 ? 0 : x }.each do |i|
          multiple = count_no.count(i)
          if multiple > 0
            result_array.push("#{i}(x#{multiple})")
            success += multiple
          else
            result_array.push("×")
          end
        end

        count_text = count_no.join(',')
        result_text = result_array.join(',')

        return "#{dice_count}D10(命数：#{count_text}) ＞ #{dice_text} ＞ #{result_text} ＞ 成功数：#{success}"
      end
    end
  end
end
