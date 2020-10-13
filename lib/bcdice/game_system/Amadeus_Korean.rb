# frozen_string_literal: true

require "bcdice/game_system/Amadeus"

module BCDice
  module GameSystem
    class Amadeus_Korean < Amadeus
      # ゲームシステムの識別子
      ID = 'Amadeus:Korean'

      # ゲームシステム名
      NAME = '아마데우스'

      # ゲームシステム名の読みがな
      SORT_KEY = '国際化:Korean:아마데우스'

      # ダイスボットの使い方
      HELP_MESSAGE = <<~INFO_MESSAGE_TEXT
        ・판정(Rx±y@z>=t)
        　다이스별로 성공, 실패의 판정을 합니다.
        　x：x에 랭크(S,A～D)를 입력.
        　y：y에 수정치를 입력. ±의 계산에 대응. 생략가능.
        　z：z에 스페셜이 되는 주사위 눈의 최저치를 입력.
        　생략한 경우, 6의 값만 스페셜이 됩니다.
        　t：t에 목표치를 입력. ±의 계산에 대응. 생략가능.
        　목표치를 생략한 경우, 목표치는 4로 계산됩니다.
        　예） RA　RB-1　RC>=5　RD+2　RS-1@5>=6
        　※ RB++ 나 RA- 같은, 플러스 마이너스만의 표기로는 계산되지 않습니다.
        　"달성치"_"판정결과"["주사위 눈""대응하는 인과"]와 같이 출력됩니다.
        　단, C.D랭크에서는 대응하는 인과가 출력되지 않습니다.
        　출력예)　1_펌블！[1흑] / 3_실패[3청]
        ・각종표
        　　조우표　ECT／관계표　RT／부모마음표　PRT／전장표　BST／휴식표　BT／
        　　펌블표　FT／치명상표　FWT／전과표 BRT／랜덤아이템표　RIT／
        　　손상표　WT／악몽표　NMT／목표표　TGT／制約表 CST／
        　　ランダムギフト表 RGT／決戦戦果表 FBT／
        　　店内雰囲気表 SAT／特殊メニュー表 SMT
        ・試練表（～VT）
        　ギリシャ神群 GCVT／ヤマト神群 YCVT／エジプト神群 ECVT／
        　クトゥルフ神群 CCVT／北欧神群 NCVT／中華神群 CHVT／
          ラストクロニクル神群 LCVT／ケルト神群 KCVT／ダンジョン DGVT／日常 DAVT
        ・挑戦テーマ表（～CT）
        　武勇 PRCT／技術 TCCT／頭脳 INCT／霊力 PSCT／愛 LVCT／日常 DACT
      INFO_MESSAGE_TEXT

      def initialize(command)
        super(command)

        @locale = :ko_kr
      end

      register_prefix_from_super_class()

      TABLES = translate_tables(:ko_kr)
    end
  end
end
