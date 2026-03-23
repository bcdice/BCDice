# frozen_string_literal: true

require "bcdice/game_system/Dracurouge"

module BCDice
  module GameSystem
    class Dracurouge_Korean < Dracurouge
      # ゲームシステムの識別子
      ID = 'Dracurouge:Korean'

      # ゲームシステム名
      NAME = '드라크루주'

      # ゲームシステム名の読みがな
      SORT_KEY = '国際化:Korean:드라크루주'

      # ダイスボットの使い方
      HELP_MESSAGE = <<~MESSAGETEXT
        ・행동판정（DRx+y）
        　x：굴리는 주사위의 수（생략시４）, y：갈증수정（생략시０）
        　예） DR　DR6　DR+1　DR5+2

        ・저항판정（DRRx）
        　x：굴리는 주사위의 수
        　예） DRR3

        ・원풍경 표（ST）, 서훈 표（CO）, 서훈 후 표（CA）, 아득한 과거 표（EP）
        　원죄 표（OS）, 수난 표（PN）, 근황 표（RS）, 평화로운 과거 표（PP）
        ・타락표（CTx） x：갈증（예） CT3
        ・타락의 전조표（CS）, 확장·타락의 조짐 표（ECS）
        ・인연 내용 결정표（BT）

        ・반응표（RTxy）x：혈통, y：길　xy생략으로 일괄표시
        　　혈통　D：드라크, R：로젠부르크, H：헬스가르드, M：더스트하임,
        　　　　　A：아발롬　N：노스페라스
        　　길　　F：영주, G：근위, R：방랑, W：현자, J：사냥꾼, N：야수
        　　　　　E：장군, B：승정(주교), H：공구(환기수), K：선장, L：총동(미동), V：중립, U：기사(공예사), D：박사
        　　　　　S：성독(별읽기), G2：후견
        　예）RT（일괄표시）, RTDF（드라크 영주）, RTAN（아발롬 야수）

        ・이단의 반응 표（HRTxy）x：혈통, y：길　xy생략으로 일괄표시
        　혈통　L：이단경, V：브루콜락, N：나흐체러, K：카른슈타인
        　　　　G：그리말킨, S：스트리가, M：멜뤼진, F：판
        　　　　H：호문클루스, E：에나멜룸, S2：생귀나리에, A：알브
        　　　　V2：뷔블, L2：루갈루, A2：알라우네, F2：프리가
        　길　W：야복(야인), N：유랑, S：밀사, H：마녀, F：검사, X：검체(실험체)
        ・D66 주사위 있음
      MESSAGETEXT

      def initialize(command)
        super(command)

        @locale = :ko_kr
      end

      TABLES = translate_tables(:ko_kr).freeze

      register_prefix_from_super_class()
    end
  end
end
