# frozen_string_literal: true

module BCDice
  module GameSystem
    class LostRecord < Base
      # ゲームシステムの識別子
      ID = 'LostRecord'

      # ゲームシステム名
      NAME = 'ロストレコード'

      # ゲームシステム名の読みがな
      SORT_KEY = 'ろすとれこおと'

      # ダイスボットの使い方
      HELP_MESSAGE = <<~MESSAGETEXT
        ※このダイスボットは部屋のシステム名表示用となります。
        D66を振った時、小さい目が十の位になります。
      MESSAGETEXT

      def initialize(command)
        super(command)

        # D66は昇順に
        @enabled_d66 = true
        @d66_sort_type = D66SortType::ASC
      end
    end
  end
end
