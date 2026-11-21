# frozen_string_literal: true

require "bcdice/game_system/MonotoneMuseum"

module BCDice
  module GameSystem
    class MonotoneMuseum_Korean < MonotoneMuseum
      # ゲームシステムの識別子
      ID = 'MonotoneMuseum:Korean'

      # ゲームシステム名
      NAME = '모노톤 뮤지엄'

      # ゲームシステム名の読みがな
      SORT_KEY = '国際化:Korean:모노톤 뮤지엄'

      # ダイスボットの使い方
      HELP_MESSAGE = <<~INFO_MESSAGE_TEXT
        ・판정
        　・통상판정　　　　　　2D6+m>=t[c,f]
        　　수정치m,목표치t,크리티컬치c,펌블치f로 판정 굴림을 행합니다.
        　　크리티컬, 펌블치는 생략가능합니다. ([]자체를 생략가능)
        　　자동성공, 자동실패, 성공, 실패를 자동표기합니다.
        ・각종표
        　・감정표　ET／감정표 2.0　ET2／개정판 감정표 MET
        　・징조표　OT／징조표ver2.0　OT2／징조표ver3.0　OT3 / 개정판 전투 징조표 MBOT / 개정판 비전투 징조표 MNOT
        　・일그러짐표　DT／일그러짐표ver2.0　DT2／일그러짐표(야외)　DTO／일그러짐표(바다)　DTS／일그러짐표(저택・성)　DTM
        　・세계왜곡표　　WDT／세계왜곡표2.0　WDT2／개정판 왜곡표 MDT／개정판 세계왜곡표 MWDT
        　・영구소실표　EDT／개정판 영구소실표 MEDT
        ・D66다이스 있음
      INFO_MESSAGE_TEXT

      register_prefix_from_super_class()

      def initialize(command)
        super(command)

        @locale = :ko_kr
      end

      TABLES = translate_tables(:ko_kr).freeze
    end
  end
end
