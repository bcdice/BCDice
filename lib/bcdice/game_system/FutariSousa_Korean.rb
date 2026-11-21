# frozen_string_literal: true

require "bcdice/game_system/FutariSousa"

module BCDice
  module GameSystem
    class FutariSousa_Korean < FutariSousa
      # ゲームシステムの識別子
      ID = 'FutariSousa:Korean'

      # ゲームシステム名
      NAME = '둘이서 수사'

      # ゲームシステム名の読みがな
      SORT_KEY = '国際化:Korean:둘이서 수사'

      # ダイスボットの使い方
      HELP_MESSAGE = <<~MESSAGETEXT
        ・판정용 커맨드
        탐정용：【DT】…10면체 주사위를 2개 굴려 판정합니다.『유리함』이라면【3DT】, 『불리함』이라면【1DT】를 사용합니다.
        　　　　【DT6】…6면체 주사위를 2개 굴려 판정합니다.『유리함』이라면【3DT6】,『불리함』이라면【1DT6】를 사용합니다.
        조수용：【AS】…6면체 주사위를 2개 굴려 판정합니다. 『유리함』이라면【3AS】, 『불리함』이라면【1AS】를 사용합니다.
        　　　　【AS10】…10면체 주사위를 2개 굴려 판정합니다.『유리함』이라면【3AS10】,『불리함』이라면【1AS10】를 사용합니다.
        　
        ・목표값 변경　(>=x)
        명령어 뒤에 ">=목표값"를 붙이면, 성공으로 판정되는 주사위 눈의 기준을 변경할 수 있습니다.
        >=2라고 지정하면, 주사위 눈이 2 이상일 때 성공으로 판정합니다.
        　예시）DT>=2　　　3AS10>=3

        ・스페셜 값 추가　([x])
        명령어 뒤에 "[스페셜 값]"을 붙이면, 일반적인 스페셜(주사위 눈 6)외에도 지정한 숫자가 나왔을 때 스페셜이 발생합니다.
        쉼표(,)로 구분해서 입력하면 여러 개의 숫자를 스페셜 값으로 지정할 수 있습니다.
        목표값 변경（>=）과 스페셜 값 추가를 동시에 사용할 때는, 반드시 목표값을 먼저 적고 그 뒤에 스페셜 값을 이어서 입력해 주세요.
        　예시）DT[5]　　　AS[5,7]　　　DT>=2[5,7]

        ・각종표
        【세션 시】
        기벽 결정 표 SHRD／신 기벽 결정 표　　 SHND
        평범한? 기벽 결정 표 SHAD／형사 기벽 결정 표　 SHKD
        규격 외 탐정용 기벽 결정 표　　 SHLD
        　발언 표　　　　　　 SHFM／수사 강행 표　　　　  SHBT／시치미 표　　　　　　 SHPI
        　사건에 몰두 표 　　 SHEG／파트너와…… 표　　　　 SHWP／뭔가 하고 있다 표　　 SHDS
        　기상천외 표　　　　 SHFT／갑작스런 영감 표 　　 SHIN／희노애락 표　　　　　 SHEM
        　인간 모방 표 　　　 SHHE／인간 모방 실패 표　　 SHHF／파트너를 향한 장난 표 SHMP
        　의미 있어 보이는 언동 표　 SHSB／애가 타다 표　　　　　　 SHFR／갑자기 왜그래 표　SHIS
        　억지 요구를 하다 표　　　  SHSE／멀쩡해 보이는 언동 표 　 SHLM／질투의 화신 표 　 SHJS
        　오만한 태도 표　　  SHAR／비교적 가벼운 기벽 표 SHRM／즉각 행동 표　　　　　  SHNT
        　수사 방식 표　　　  SHIM／귀족 표　　　　　　　  SHNO／설명하지 않는다 표　　  SHNE
        　형사 특유의 습관 표 SHHD／유명한 탐정 표　　　　 SHGD／엄청나게 굉장해 표　　 SHSA
        　규격 외 사건에 몰두 표　　 SHEP／규격 외 파트너와……표　　 SHXP
        　
        이벤트 표
        　현장에서 EVS／왜? EVW／협력자와 함께 EVN
        　알아서 찾아온 단서 EVC／VS용의자 EVV
        　폐쇄 공간 EVE
        　탐정 혼자 수사 EVD／조수 혼자 수사 EVA／관광 수사 EVT
        　예상치 못한 힌트 EVH／실험을 해보자 EVX／게스트 수사 EVG
        　형사 탐문 수사 EVQ／형사 대규모 수사 EVM／비밀스러운 정보 교환 EVP
        　동료들과 함께 수사 EVO／단골 가게 시추에이션 EVF／하드B 형사 액션  EVB
        　탐정을 얌전하게 만드는 수사 EVL／전통적 수사 EVZ／원시적 수사 EVR
        　규격 외 탐정 조사　　　　　 EV6S／신속조사　　　　　　　　　  EV6F
        　
        감정 표
        　감정 표A／B　　 FLT66・FLT10
        　마음에 드는 점　 FLTL66　／마음에 안 드는 점　 FLTD66
        　무작위 감정 결정 표（당친법）　 FLTRA
        　얼굴 부위　　　　　　 FLTF66／신체 부위　　　　　 FLTB66／생활 습관　　　 FLTH66
        　마음이 들뜨는 감각　　 FLTS66／타인에 대한 태도　 FLTA66／헤비 웨이트　　 FLTW66
        　동료　　　　　　　　　 FLTC66／부하　　　　　　　 FLTU66／상사　　　　 FLTO66
        　수사 방식 FLTI66
        조사 방해 요인 표 OBT　　상태 이상 표 ACT　　목격자 표 EWT　　미제 사건 표 WMT
        추억의 물품 결정 표 MIT　　에피소드가 있는 추억의 물품 표 MITE　　
        호칭 표A・B　 NCT66・NCT10
        　
        【설정】
        배경 표
        　탐정　운명의 혈통　 BGDD／천성적인 재능　 BGDG／마니아　　  BGDM
        　조수　정의로운 사람 BGAJ／정열적인 사람　 BGAP／말려든 사람 BGAI
        신장 표 HT　　아지트 표 BT　　관계 표 GRT
        직업 표A・B　　JBT66・JBT10　　패션 특징 표A・B　　FST66・FST10
        호불호 표A・B　　LDT66・LDT10
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
