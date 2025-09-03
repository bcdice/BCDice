# frozen_string_literal: true

module BCDice
  module GameSystem
    class MagicPunk < Base
      # ゲームシステムの識別子
      ID = "MagicPunk"

      # ゲームシステム名
      NAME = "マジックパンクTRPG"

      # ゲームシステム名の読みがな
      SORT_KEY = "まじっくぱんくTRPG"

      HELP_MESSAGE = <<~TEXT
        ■ 判定 (nMPm)
        nD20のダイスロールをして、m以下の目があれば成功。
        mと同じ目があればジャックポット(自動成功)。
        すべての目が1ならバッドビート(自動失敗)。
        ■ チャレンジ判定 (nMPm>=x、nMPmCx)
        通常の判定に加えてチャレンジ値x以上の目が必要になる。
      TEXT

      register_prefix('^\d?MP\d+')

      def eval_game_system_specific_command(command)
        return roll_mp(command)
      end
      private
      def roll_mp(command)
        m = /^(\d?)MP(\d+)$/.match(command)
        return nil unless m

        times = m[1].size > 0 ? m[1].to_i : 1
        spec = m[2].to_i

        dice_list = @randomizer.roll_barabara(times, 20)

        check = dice_list.count{|d| d <= spec} > 0
        is_bb = dice_list.all?{|d| d == 1}
        if is_bb
          check = false
        end

        result = if check
          max = dice_list.select{|d| d <= spec}.max
          if max == spec
            "JP"
          else
            "成功(#{max})"
          end
        else
          if is_bb
            "BB"
          else
            "失敗"
          end
        end

        return "(#{times}MP#{spec}) > [#{dice_list.join(',')}] > #{result}"

      end
    end
  end
end
