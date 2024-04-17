# frozen_string_literal: true

require "bcdice/game_system/Insane"

module BCDice
  module GameSystem
    class Insane_Korean < Insane
      # ゲームシステムの識別子
      ID = 'Insane:Korean'

      # ゲームシステム名
      NAME = '인세인'

      # ゲームシステム名の読みがな
      SORT_KEY = '国際化:Korean:인세인'

      # ダイスボットの使い方
      HELP_MESSAGE = <<~INFO_MESSAGE_TEXT
        ・판정
        스페셜／펌블／성공／실패를 판정
        ・각종표
        장면표　　　ST
        　사실은 무서운 현대 일본 장면표 HJST／광란의 20년대 장면표 MTST
        　빅토리아의 어둠 장면표 DVST
        형용표　　　　DT
        　본체표 BT／부위표 PT
        감정표　　　　　　FT
        직업표　　　　　　JT
        배드엔드표　　BET
        랜덤 특기 결정표　RTT
        지정특기(폭력)표　　(TVT)
        지정특기(정서)표　　(TET)
        지정특기(지각)표　　(TPT)
        지정특기(기술)표　　(TST)
        지정특기(지식)표　　(TKT)
        지정특기(괴이)표　　(TMT)
        회화 중에 생겨나는 공포표(CHT)
        거리에서 마주치는 공포표(VHT)
        갑자기 찾아오는 공포표(IHT)
        폐허에서 마주치는 공포표(RHT)
        야외에서 마주치는 공포표(MHT)
        정보 속에 숨어있는 공포표(LHT)
        조우표　도시　(ECT)　산림　(EMT)　해변　(EAT)/반응표　RET
        야근 호러 스케이프　OHT/야근 전화표　OPT/야근 장면표　OWT
        회사명 결정표1　CNT1/회사명 결정표2　CNT2/회사명 결정표3　CNT3
        ・D66 다이스 있음.
      INFO_MESSAGE_TEXT

      register_prefix_from_super_class()

      def initialize(command)
        super(command)

        @locale = :ko_kr
      end

      TABLES = translate_tables(:ko_kr)
      RTT = translate_rtt(:ko_kr)
    end
  end
end
