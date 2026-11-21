# frozen_string_literal: true

require "bcdice/dice_table/chain_table"
require "bcdice/dice_table/sai_fic_skill_table"
require "bcdice/dice_table/table"
require "bcdice/format"
require "bcdice/game_system/StarryDolls"

module BCDice
  module GameSystem
    class StarryDolls_Korean < StarryDolls
      # ゲームシステムの識別子
      ID = "StarryDolls:Korean"

      # ゲームシステム名
      NAME = "스타리돌"

      # ゲームシステム名の読みがな
      SORT_KEY = "国際化:Korean:스타리돌"

      # ダイスボットの使い方
      HELP_MESSAGE = <<~INFO_MESSAGE_TEXT
        ・행위판정 nD6±m@s>=t
        　nD6의 행위판정을 실행합니다. 스페셜／펌블／성공／실패를 판정합니다.
        　　n: 주사위 수
        　　m: 수정치 (생략 가능)
        　　s: 스페셜값 (생략 시 12)
        　　t: 목표치 (?지정 가능)
        ・각종 표
        　・랜덤 특기 결정표 RTTn (n：분야 번호, 생략 가능)
        　　　1소원 2원소 3별다루기 4동작 5소환 6인간성
        　・랜덤 분야표 RCT
        　・랜덤 별자리표 HOR
        　　　랜덤 별자리표A HORA／랜덤 별자리표B HORB
        　・주인 관계표 MRT／관계 속성표 RAT
        　・종자 관계표 SRT
        　・기적표 MIR
        　・전과표 BRT
        　・사건표 TRO
        　・숲 사건표 TROF
        　・정원 사건표 TROG
        　・성내 사건표 TROC
        　・도시 사건표 TROT
        　・도서관 사건표 TROL
        　・역 사건표 TROS
        　・종자 트러블표 TRS
        　・리액션표 - 충성 RAL
        　・리액션표 - 냉정 RAC
        　・리액션표 - 모성 RAM
        　・리액션표 - 연장자 RAO
        　・리액션표 - 천진난만 RAI
        　・리액션표 - 장로 RAE
        　・조우표 ENC
        　・치명상 표 FWT
        　・카타스트로피 표 CAT
        　・회상표
        　　　〈마술사의 정원〉 회상표 JDSRT／〈세븐스 헤븐〉 회상표 SHRT
        　　　／〈축복의 종〉 회상표 BCRT／〈오메가 탐정사〉 회상표 ODRT
        　・출장표
        　　　〈마술사의 정원〉 출장표 JDSBT／〈세븐스 헤븐〉 출장표 SHBT
        　　　／〈축복의 종〉 출장표 BCBT／〈오메가 탐정사〉 출장표 ODBT
        　　　／〈은하수 상점가〉 출장표 ASBT／〈폴라리스 성학원〉 출장표 PABT
        　　　／〈인형 기사단〉 출장표 SCBT／〈인형 기사단〉으로의 출장표 TOSCBT
        ・D66 다이스 있음
      INFO_MESSAGE_TEXT

      register_prefix_from_super_class()

      def initialize(command)
        super(command)

        @d66_sort_type = D66SortType::ASC
        @locale = :ko_kr
      end

      TABLES = translate_tables(:ko_kr).freeze
      RTT = translate_rtt(:ko_kr)
    end
  end
end
