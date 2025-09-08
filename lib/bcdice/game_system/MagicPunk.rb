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

      register_prefix('^\d*MP\d+')

      def eval_game_system_specific_command(command)
        return roll_mp(command)
      end

      private

      def roll_mp(command)
        m = /^(\d*)MP(\d+)(C?)(\d*)$/.match(command)
        return nil unless m

        # 構文解析
        dices = m[1].empty? ? 1 : m[1].to_i
        spec = m[2].to_i
        opt1 = m[3]
        arg1 = m[4].to_i

        # ダイス数0モードフラグ
        is_zero = dices == 0
        # チャレンジ値
        challenge = opt1 == "C" ? arg1 : 0

        # ダイスロール
        dice_list = @randomizer.roll_barabara(is_zero ? 2 : dices, 20)

        # 通常は1つ成功なら成功、0ダイス時はすべて成功したとき成功
        check_method = is_zero ? :all? : :any?
        # 通常はすべて失敗なら失敗、0ダイス時は1つ失敗したら失敗
        fail_method = is_zero ? :any? : :all?

        check = dice_list.public_send(check_method) { |d| d <= spec && challenge <= d } # 通常判定
        is_jp = dice_list.public_send(check_method) { |d| d == spec } # ジャックポット判定
        is_bb = dice_list.public_send(fail_method) { |d| d == 1 } # バッドビート判定

        result = if is_bb # 自動失敗優先
                   is_jp = false
                   check = false
                   "失敗(BB)"
                 elsif is_jp
                   check = true
                   "成功(JP)"
                 elsif check
                   value_method = is_zero ? :min : :max
                   value = dice_list.select { |d| d <= spec }.public_send(value_method)
                   "成功(#{value})"
                 else
                   "失敗"
                 end

        return Result.new.tap do |r|
          r.fumble = is_bb
          r.critical = is_jp
          r.condition = check
          r.text = "(#{dices}MP#{spec}C#{challenge}) > [#{dice_list.join(',')}] > #{result}"
        end
      end
    end
  end
end
