# frozen_string_literal: true

module BCDice
  module GameSystem
    class Arianrhod_Korean < Arianrhod
      # ゲームシステムの識別子
      ID = 'Arianrhod:Korean'

      # ゲームシステム名
      NAME = '아리안로드RPG'

      # ゲームシステム名の読みがな
      SORT_KEY = '国際化:Korean:아리안로드RPG'

      # ダイスボットの使い方
      HELP_MESSAGE = <<~INFO_MESSAGE_TEXT
        ・크리티컬, 펌블의 자동판정을 행합니다.(크리티컬 시의 추가 대미지도 표시됩니다)
        ・D66 다이스 있음
      INFO_MESSAGE_TEXT

      def initialize(command)
        super(command)

        @sort_add_dice = true
        @d66_sort_type = D66SortType::NO_SORT
      end

      def result_nd6(total, _dice_total, dice_list, cmp_op, target)
        n_max = dice_list.count(6)

        if dice_list.count(1) == dice_list.size
          # 全部１の目ならファンブル
          Result.fumble(translate("fumble"))
        elsif n_max >= 2
          # ２個以上６の目があったらクリティカル
          Result.critical(translate("Arianrhod.critical", dice: n_max))
        elsif cmp_op != :>= || target == '?'
          nil
        elsif total >= target
          Result.success(translate("success"))
        else
          Result.failure(translate("failure"))
        end
      end
    end
  end
end
