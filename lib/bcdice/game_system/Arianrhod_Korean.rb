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

        @locale = :ko_kr
      end

      register_prefix_from_super_class()
    end
  end
end
