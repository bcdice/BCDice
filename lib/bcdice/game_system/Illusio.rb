# frozen_string_literal: true

module BCDice
  module GameSystem
    class Illusio < Base
      # ゲームシステムの識別子
      ID = 'Illusio'

      # ゲームシステム名
      NAME = '晃天のイルージオ'

      # ゲームシステム名の読みがな
      SORT_KEY = 'こうてんのいるうしお'

      # ダイスボットの使い方
      HELP_MESSAGE = <<~MESSAGETEXT
        判定：[n]IL(BNo)[P]

        []内のコマンドは省略可能。
        「n」でダイス数を指定。省略時は「1」。
        (BNo)でブロックナンバーを指定。「236」のように記述。順不同可。
        コマンド末に「P」を指定で、(BNo)のパリィ判定。（一応、複数指定可）

        【書式例】
        ・6IL236 → 6dでブロックナンバー「2,3,6」の判定。
        ・IL4512 → 1dでブロックナンバー「1,2,4,5」の判定。
        ・2IL1P → 2dでパリィナンバー「1」の判定。
      MESSAGETEXT

      def initialize(command)
        super(command)
        @sort_add_dice = true # ダイスのソート有
      end

      register_prefix(
        '(\d+)?IL([1-6]{0,6})(P)?'
      )

      def eval_game_system_specific_command(command)
        m = command.match(/(\d+)?IL([1-6]{0,6})(P)?$/i)
        return nil unless m

        dice_count = (m[1] || 1).to_i
        block_no = (m[2] || "").each_char.map(&:to_i).uniq.sort
        is_parry = !m[3].nil?

        return check_roll(dice_count, block_no, is_parry)
      end

      def check_roll(dice_count, block_no, is_parry)
        dice_array = @randomizer.roll_barabara(dice_count, 6).sort
        dice_text = dice_array.join(',')

        result_array = []
        success = 0
        dice_array.each do |i|
          if block_no.count(i) > 0
            result_array.push("×")
          else
            result_array.push(i)
            success += 1
          end
        end

        block_text = block_no.join(',')
        block_text2 = is_parry ? "Parry" : "Block"
        result_text = result_array.join(',')

        result = "#{dice_count}D6(#{block_text2}:#{block_text}) ＞ #{dice_text} ＞ #{result_text} ＞ "
        return "#{result}成功数：#{success}" unless is_parry

        if success < dice_count
          "#{result}パリィ成立！　次の非ダメージ2倍。"
        else
          "#{result}成功数：#{success}　パリィ失敗"
        end
      end
    end
  end
end
