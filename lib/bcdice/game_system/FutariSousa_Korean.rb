# frozen_string_literal: true

require "bcdice/game_system/FutariSousa"

module BCDice
  module GameSystem
    class FutariSousa_Korean < FutariSousa
      # ゲームシステムの識別子
      ID = 'FutariSousa:Korean'

      # ゲームシステム名
      NAME = '둘이서 수사(후타리소우사)'

      # ゲームシステム名の読みがな
      SORT_KEY = '国際化:Korean:둘이서 수사'

      # ダイスボットの使い方
      HELP_MESSAGE = <<~MESSAGETEXT
        ・판정용 커맨드
        탐정용：【DT】…10면체 주사위를 2개 굴려 판정합니다.『유리』라면【3DT】, 『불리』라면【1DT】를 사용합니다.
        조수용：【AS】…6면체 주사위를 2개 굴려 판정합니다. 『유리』라면【3AS】, 『불리』라면【1AS】를 사용합니다.
        ・각종표
        【조사】
        이상한 버릇 결정표 SHRD
        　지껄이다표  　SHFM／강압적인 수사표 　SHBT／시치미 떼기표　　　SHPI
        　사건에 몰두표 SHEG／파트너와……표　　SHWP／무언가 하고 있다표 SHDS
        　기상천외표　　SHFT／갑작스런 번뜩임표 SHIN／희노애락표 　　　　SHEM
        이벤트표
        　현장에서　 EVS／어째서?　EVW／협력자와 함께 EVN
        　상대쪽에서 EVC／VS용의자 EVV
        조사의 장애표 OBT　　변조표 ACT　　목격자표 EWT　　미제사건표 WMT
        【설정】
        배경표
        　탐정　운명의 혈통 　BGDD／천상의 재능 　BGDG／마니아 　　 BGDM
        　조수　정의로운 사람 BGAJ／정렬적인 사람 BGAP／말려든 사람 BGAI
        신장표 HT　　아지트표 BT　　관계표 GRT　　추억의 물건 결정표 MIT
        직업표A・B　　JBT66・JBT10　　패션 특징표A・B　　　　FST66・FST10
        감정표A・B　　FLT66・FLT10　　좋아하는 것／싫어하는 것표A・B　LDT66・LDT10
        호칭표A・B　NCT66・NCT10
      MESSAGETEXT

      register_prefix_from_super_class()

      def initialize(command)
        super(command)

        @locale = :ko_kr
      end

      TABLES = translate_tables(:ko_kr)
    end
  end
end
