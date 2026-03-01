# frozen_string_literal: true

require 'bcdice/game_system/MorkBorg'

module BCDice
  module GameSystem
    class MorkBorg_Korean < MorkBorg
      # ゲームシステムの識別子
      ID = 'MorkBorg:Korean'

      # ゲームシステム名
      NAME = '모크 보그(MÖRK BORG)'

      # ゲームシステム名の読みがな
      SORT_KEY = '国際化:Korean:모크 보그(MÖRK BORG)'

      # ダイスボットの使い方
      HELP_MESSAGE = <<~INFO_MESSAGETEXT
        ■판정　sDRt        s: 능력치(생략 시:0) t:목표값

        예)+3DR12: 능력치+3, DR12로 1d20을 굴려서 결과 표시(크리티컬·펌블도 표시)

        ■이니셔티브　sINS s: 능력치(생략 시:0. 개별 이니셔티브를 사용하는 경우)

        예)INS: 1d6을 굴려서 이니셔티브 결과 표시(PC 선공을 성공으로 표시)

        ■모럴　sMORt s: 능력치(생략 시:0) t:상대 크리처의 모럴 값

        예)MOR8: 2d6을 굴려서 모럴 판정 결과 표시(모럴 붕괴를 성공으로 표시)


        ■각종 표

        ・조우 반응표 Reaction (ERT)
        ・붕괴표 Broken (BRO)

      INFO_MESSAGETEXT

      def initialize(command)
        super(command)
        @locale = :ko_kr
      end

      TABLES = translate_tables(:ko_kr).freeze

      register_prefix_from_super_class()
    end
  end
end
