# frozen_string_literal: true

module BCDice
  module GameSystem
    class MagicPunk < Base
      # ゲームシステムの識別子
      ID = "MagicPunk"

      # ゲームシステム名
      NAME = "マジックパンクTRPG"

      # ゲームシステム名の読みがな
      SORT_KEY = "ましつくはんくTRPG"

      HELP_MESSAGE = <<~TEXT
        ■ 判定 (nMPm)
        nD20のダイスロールをして、m以下の目があれば成功。
        mと同じ目があればジャックポット(自動成功)。
        すべての目が1ならバッドビート(自動失敗)。
        ■ チャレンジ判定 (nMPmCx)
        通常の判定に加えてチャレンジ値x以上の目が必要になる。
        ■ ダイス数0 (0MPmCx)
        修正によりダイス数が0になった場合は2d20のダイスロールを行う。
        2つの目からより悪い結果になる方を採用する。
      TEXT

      register_prefix('^\d?MP\d+')

      def eval_game_system_specific_command(command)
        return roll_mp(command)
      end

      private

      def roll_mp(command)
        m = /^(\d?)MP(\d+)([cC]?)(\d*)/.match(command)
        return nil unless m

        dices = m[1].empty? ? 1 : m[1].to_i
        spec = m[2].to_i
        opt1 = m[3]
        arg1 = m[4].to_i

        is_zero = dices == 0
        times = is_zero ? 2 : dices
        challenge = ["c", "C"].include?(opt1) ? arg1 : 0

        dice_list = @randomizer.roll_barabara(times, 20)

        check_method = is_zero ? :all? : :any?
        fail_method = is_zero ? :any? : :all?

        check = dice_list.public_send(check_method) { |d| d <= spec && challenge <= d }
        is_jp = dice_list.public_send(check_method) { |d| d == spec }
        is_bb = dice_list.public_send(fail_method) { |d| d == 1 }

        result = if is_bb # 自動失敗優先
                   "失敗(BB)"
                 elsif is_jp
                   "成功(JP)"
                 elsif check
                   value_method = is_zero ? :min : :max
                   value = dice_list.select { |d| d <= spec }.public_send(value_method)
                   "成功(#{value})"
                 else
                   "失敗"
                 end

        return "(#{dices}MP#{spec}C#{challenge}) > [#{dice_list.join(',')}] > #{result}"
      end
    end
  end
end
