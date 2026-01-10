# frozen_string_literal: true

require "bcdice/game_system/DungeonsAndDragons5"

module BCDice
  module GameSystem
    class DungeonsAndDragons5_Korean < DungeonsAndDragons5
      # ゲームシステムの識別子
      ID = 'DungeonsAndDragons5:Korean'

      # ゲームシステム名
      NAME = '던전 앤 드래곤 5판'

      # ゲームシステム名の読みがな
      SORT_KEY = '国際化:Korean:던전 앤 드래곤 5판'

      # ダイスボットの使い方
      HELP_MESSAGE = <<~INFO_MESSAGE_TEXT
        ・명중 굴림　AT[x][@c][>=t][y]
        　x: +- 수정치 (생략 가능)
        　c: 크리티컬 수치 (생략 가능)
        　t: 목표 AC (>= 포함, 생략 가능)
        　y: 유리(A), 불리(D) (생략 가능)
        　펌블／실패／성공／크리티컬을 자동으로 판정합니다.
        　예시）AT AT>=10 AT+5>=18 AT-3>=16 ATA AT>=10A AT+3>=18A AT-3>=16 ATD AT>=10D AT+5>=18D AT-5>=16D
        　    AT@19 AT+5@18 AT-2@19>=15
        ・능력 판정　AR[x][>=t][y]
        　명중 굴림과 동일. 실패／성공을 자동 판정합니다.
        　예시）AR AR>=10 AR+5>=18 AR-3>=16 ARA AR>=10A AR+3>=18A AR-3>=16 ARD AR>=10D AR+5>=18D AR-5>=16D
        ・대형 무기 전투술 대미지 계산(베이직 룰북 32p)　2HnDx[m]
        　n: 주사위 개수
        　x: 주사위 면수(1d6의 6, 1d8의 8 등)
        　m: +- 수정치 (생략 가능)
        　팔라딘과 파이터의 무기를 양손으로 사용할 경우, 대미지 주사위에서 1 또는 2가 나오면 다시 굴립니다.
        　예시)2H3D6 2H1D10+3 2H2D8-1
      INFO_MESSAGE_TEXT

      register_prefix_from_super_class()

      def initialize(command)
        super(command)

        @locale = :ko_kr # i18n ko_kr 참조
      end
    end
  end
end
