# frozen_string_literal: true

require 'bcdice/game_system/BlackJacket'

module BCDice
  module GameSystem
    class BlackJacket_Korean < BlackJacket
      # ゲームシステムの識別子
      ID = 'BlackJacket:Korean'

      # ゲームシステム名
      NAME = '블랙재킷RPG'

      # ゲームシステム名の読みがな
      SORT_KEY = '国際化:Korean:블랙재킷RPG'

      # ダイスボットの使い方
      HELP_MESSAGE = <<~INFO_MESSAGE_TEXT
        ・행위 판정（BJx）
        　x：성공률
        　예）BJ80
        　크리티컬,펌블 여부는 자동으로 판정합니다.
        　「BJ50+20-30」처럼 값을 가감하여 기재할 수 있습니다.
        　성공률의 상한은 100％, 하한은 ０％ 입니다.
        ・데스 차트 (DCxY)
        　x：차트 종류. 육체：DCL, 정신：DCS, 환경：DCC
        　Y=마이너스 값
        　예）DCL5：라이프 마이너스 값 5 + 1D10 판정
        　　　DCS3：새니티 마이너스 값 3 + 1D10 판정
        　　　DCC0：크레딧 마이너스 값 0 + 1D10 판정
        ・챌린지・패널티 차트（CPC）
        ・사이드 트랙 차트（STC）
      INFO_MESSAGE_TEXT

      register_prefix_from_super_class()

      def initialize(command)
        super(command)
        @locale = :ko_kr
      end

      TABLES       = translate_tables(:ko_kr).freeze
      DEATH_CHARTS = translate_death_charts(:ko_kr).freeze
    end
  end
end
