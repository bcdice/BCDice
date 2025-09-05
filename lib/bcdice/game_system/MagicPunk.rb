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
        m = /^(\d?)MP(\d+)([cC]?)(\d*)/.match(command)
        return nil unless m

        dices = m[1].size > 0 ? m[1].to_i : 1
        spec = m[2].to_i
        opt1 = m[3]
        arg1 = m[4].to_i

        challenge = ["c", "C"].include?(opt1) ? arg1 : 0

        dice_list = @randomizer.roll_barabara(dices, 20)

        check = dice_list.any?{|d| d <= spec && challenge <= d}
        is_jp = dice_list.any?{|d| d == spec}
        is_bb = dice_list.all?{|d| d == 1}

        result = if is_bb # 自動失敗優先
          "失敗(BB)"
        elsif is_jp
          "成功(JP)"
        elsif check
          max = dice_list.select{|d| d <= spec}.max
          "成功(#{max})"
        else
          "失敗"
        end

        return "(#{dices}MP#{spec}C#{arg1}) > [#{dice_list.join(',')}] > #{result}"

      end
    end
  end
end
