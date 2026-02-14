# frozen_string_literal: true

module BCDice
  module GameSystem
    class MagicPunk_Korean < MagicPunk
      # ゲームシステムの識別子
      ID = "MagicPunk:Korean"

      # ゲームシステム名
      NAME = "매직펑크TRPG"

      # ゲームシステム名の読みがな
      SORT_KEY = "国際化:Korean:매직펑크TRPG"

      HELP_MESSAGE = <<~TEXT
        ■ 판정 (nMPm)
        nD20을 굴려, m 이하의 눈이 있으면 성공.
        m과 같은 눈이 있으면 잭팟(자동 성공).
        모든 눈이 1이면 배드 비트(자동 실패).

        ■ 챌린지 판정 (nMPmCx)
        통상 판정에 더해, 챌린지 값 x 이상의 눈이 필요.

        ■ 다이스 수 0개 (0MPmCx)
        수정치 등으로 다이스 수가 0개가 된 경우 2d20을 굴림.
        두 개의 눈 중 더 나쁜 쪽의 결과를 적용.
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
                   "실패(BB)"
                 elsif is_jp
                   check = true
                   "성공(JP)"
                 elsif check
                   value_method = is_zero ? :min : :max
                   value = dice_list.select { |d| d <= spec }.public_send(value_method)
                   "성공(#{value})"
                 else
                   "실패"
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
