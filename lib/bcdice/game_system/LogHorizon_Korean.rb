# frozen_string_literal: true

require "bcdice/game_system/LogHorizon"

module BCDice
  module GameSystem
    class LogHorizon_Korean < LogHorizon
      # ゲームシステムの識別子
      ID = 'LogHorizon:Korean'

      # ゲームシステム名
      NAME = '로그 호라이즌'

      # ゲームシステム名の読みがな
      SORT_KEY = '国際化:Korean:로그 호라이즌'

      # ダイスボットの使い方
      HELP_MESSAGE = <<~MESSAGETEXT
        ■ 판정(xLH±y>=z)
        　xD6의 판정.크리티컬, 펌블의 자동 판정을 실시합니다.
        　x：x로 굴릴 주사위의 수를 입력합니다.
        　±y：y로 수정치를 입력합니다. ±의 계산에 대응하며 생략이 가능합니다.
          >=z：z로 목표값을 입력합니다. ±의 계산에 대응하며 생략이 가능합니다.
        　예시） 3LH　2LH>=8　3LH+1>=10

        ■ 소모표(tCTx±y$z)
        　PCT 체력／ECT 기력／GCT 물품／CCT 금전
        　x:CR을 지정합니다.
        　±y:수정치, ＋와 －의 계산에 대응하며 생략이 가능합니다.
        　$z：$를 붙이면 주사위 눈을 z고정합니다. 표의 특정 값 참조용으로 사용하며.생략 가능.
        　例） PCT1　ECT2+1　GCT3-1　CCT3$5

        ■ 消耗表ロール (CTx±y)
        　消耗表ロールを行い、出目を決定する。
        　x：CRを指定。指定できますが、無視されます。省略可能
        　±y：修正値。＋と－の計算に対応。省略可能。

        ■ 재물표(tTRSx±y$)
        　CTRS 금전／MTRS 마법소재／ITRS 환전 아이템／※HTRS 히로인／GTRS 고블린 재보표
        　x：CR을 지정합니다. 생략시에는 다이치 0고정으로 수정치의 표를 참조.《골드 핑거》사용 시 등.
        　±y：수정치, ＋와 －의 계산에 대응하며 생략이 가능합니다.
        　$：＄을 붙이면 재물표의 다이스를 7로 고정합니다.（1차 분량의 프라이즈 용도）생략이 가능합니다.
        　예시） CTRS1　MTRS2+1　ITRS3-1　ITRS+27　CTRS3$

        ■ 拡張ルール財宝表 (tTRSEx±y$)
        　LHZB2記載の財宝表
        　CTRSE 金銭／MTRSE 魔法素材／ITRSE 換金アイテム／OTRSE そのほか
        　記法は財宝表と同様

        ■ 財宝表ロール (TRSx±y)
        　財宝表ロールを行い、出目を決定する。
        　x：CRを指定。省略時はCR 0として扱う
        　±y：修正値。＋と－の計算に対応。省略可能。

        ■ 이스탈 탐색표 (ESTLx±y$z)
        　x：CRを指定。省略時はダイス値 0 固定で修正値の表参照。
        　±y：修正値。＋と－の計算に対応。省略可能。
        　$z：＄を付けるとダイス目を z 固定。特定CRの表参照用に。省略可能。
        　例） ESTL1　ESTL+15　ESTL2+1$5　ESTL2-1$5

        ■ 프리픽스드 매직아이템 효과 표(MGRx)
        　x는 MG를 지정합니다.

        ■ 악기 종류 표† (MIIx)
        　x는 악기의 종류를 지정합니다.(1~6를 지정) 생략이 가능합니다.
        　1 타악기1／2 건반악기／3 현악기1／4 현악기2／5 관악기1／6 관악기2

        ■ 특수 소모표☆ (tSCTx±y$z)
        　소모표와 마찬가지로 지정합니다. 다만 CR은 생략이 가능합니다.
        　ESCT 로데릭 연구소는 폭발했다!／CSCT 알브의 저주다!

        ■ 로데릭 연구소의 새로운 발명 랜덤 결정표※ (IATt)
          IATA 특징A(장점)／IATB 특징B(단점)／IATL 외형／IATT 종류
          t를 생략할 경우 모두 표시합니다. t에 A/B/L/T를 임의의 순서로 연결 할 수 있습니다.
          例）IAT　IATALT  IATABBLT  IATABL

        ■ 표
        　・퍼스널리티 태그 표 (PTAG)
        　・교우표 (KOYU)
        　・공격 명중 장소 랜덤 결정표※ (HLOC)
        　・PC명 랜덤 결정표※ (PCNM)
        　・아키바 거리에서 발생하는 문제 랜덤결정 표※ (TIAS)
        　・버려진 아이 랜덤 결정 표※ (ABDC)

        †표시와 ☆표시는「인투・더・셀덴시아 새로운 빌드의 날개짓(1)」에서、
        ☆표시는 셀덴시아・가제트「D 되기는 할까? 66」Vol.1에서、
        ※표시는「실록・칠면체공방 좌담회(여름의 장)」에서 참조했습니다. 이용법은 항목을 참조해주세요.
        ・D66다이스도 있습니다.

        ・역자의 말 : 「실록・칠면체공방 좌담회(여름의 장)」은 한국에서 발매하지 않습니다. 참고해주세요.
        ・이니티움님, 광황님, CoC방 여러분 감사합니다. by호흡도의식하면귀찮아
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
