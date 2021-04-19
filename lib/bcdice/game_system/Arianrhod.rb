# frozen_string_literal: true

module BCDice
  module GameSystem
    class Arianrhod < Base
      # ゲームシステムの識別子
      ID = 'Arianrhod'

      # ゲームシステム名
      NAME = 'アリアンロッドRPG'

      # ゲームシステム名の読みがな
      SORT_KEY = 'ありあんろつとRPG'

      # ダイスボットの使い方
      HELP_MESSAGE = <<~INFO_MESSAGE_TEXT
        ・クリティカル、ファンブルの自動判定を行います。(クリティカル時の追加ダメージも表示されます)
        ・D66ダイスあり
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
          Result.fumble("ファンブル")
        elsif n_max >= 2
          # ２個以上６の目があったらクリティカル
          Result.critical("クリティカル(+#{n_max}D6)")
        elsif cmp_op != :>= || target == '?'
          nil
        elsif total >= target
          Result.success("成功")
        else
          Result.failure("失敗")
        end
      end
    end
  end
end
