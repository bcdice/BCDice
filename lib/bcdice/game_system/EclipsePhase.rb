# frozen_string_literal: true

module BCDice
  module GameSystem
    class EclipsePhase < Base
      # ゲームシステムの識別子
      ID = 'EclipsePhase'

      # ゲームシステム名
      NAME = 'エクリプス・フェイズ'

      # ゲームシステム名の読みがな
      SORT_KEY = 'えくりふすふえいす'

      # ダイスボットの使い方
      HELP_MESSAGE =
        '1D100<=m 方式の判定で成否、クリティカル・ファンブルを自動判定'

      def result_1d100(total, _dice_total, cmp_op, target)
        return nil if target == '?'
        return nil unless cmp_op == :<=

        dice_value = total % 100 # 出目00は100ではなく00とする
        dice_ten_place = dice_value / 10
        dice_one_place = dice_value % 10

        if dice_ten_place == dice_one_place
          return Result.fumble('決定的失敗') if dice_value == 99
          return Result.critical('00 ＞ 決定的成功') if dice_value == 0
          return Result.critical('決定的成功') if total <= target

          return Result.fumble('決定的失敗')
        end

        diff_threshold = 30

        if total <= target
          if total >= diff_threshold
            Result.success('エクセレント')
          else
            Result.success('成功')
          end
        elsif (total - target) >= diff_threshold
          Result.failure('シビア')
        else
          Result.failure('失敗')
        end
      end
    end
  end
end
