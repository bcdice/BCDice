# frozen_string_literal: true

require "bcdice/game_system/BeginningIdol"

module BCDice
  module GameSystem
    class BeginningIdol_Korean < BeginningIdol
      # ゲームシステムの識別子
      ID = 'BeginningIdol:Korean'

      # ゲームシステム名
      NAME = '비기닝 아이돌'

      # ゲームシステム名の読みがな
      SORT_KEY = '国際化:Korean:비기닝 아이돌'

      # ダイスボットの使い方
      HELP_MESSAGE = <<~INFO_MESSAGE_TEXT
        ・퍼포먼스　[r]PDn[+m/-m](r：남은 주사위 눈　n：굴릴 갯수　m：수정치)
        ・월드세팅 업무표　BWT：대형 연예 프로덕션　LWT：약소 연예 프로덕션
        　TWT：라이브 시어터　CWT：아이돌 부　LO[n]：로컬 아이돌(n：찬스)
        　SU：열정의 여름　WI：온기의 겨울　NA：대자연　GA：女学園　BA：アカデミー
        ・업무표　WT　VA：버라이어티　MU：음악 관련　DR：드라마 관련
        　VI：비주얼 관련　SP：스포츠　CHR：크리스마스　PAR：파트너 관련
        ・특기 리스트　AN：動物　MOV：映画　FA：ファンタジー
        ・ハプニング表　HA
        ・特技リスト　AT[n](n：分野No.)
        ・아이돌 스킬 습득표　SGT：챌린지 걸즈　RS：로드 투 프린스
        ・변조　BT[n](n：주사위눈)
        ・아이템　IT[n](n：보유 갯수)
        ・アクセサリー　ACT：種別決定　ACB：ブランド決定　ACE：効果表
        ・의상　DT：챌린지 걸즈　RC：로드 투 프린스　FC:フォーチュンスターズ
        ・엉망진창 표　LUR：로컬 아이돌　SUR：정열의 여름　WUR：온기의 겨울
        　NUR：대자연　GUR：女学園　BUR：アカデミー
        ・센터 룰　HW：역풍 씬표　FL：신출내기 씬표　LN：고독표
        　マイスキル【MS：名前決定　MSE：効果表】　演出表【ST　FST：ファンタジー】
        ・합숙 룰　산책표 【SH：쇼핑몰　MO：산　SEA：바다　SPA：온천】
        　TN：야밤의 대화 시츄에이션　성장표 【CG：커먼　GG：골드】
        ・작사표　CHO　SCH：정열의 여름　WCH：온기의 겨울　NCH：대자연
        ・캐릭터 공백표　CBT：챌린지 걸즈　RCB：로드 투 프린스
        ・취미 공백표　HBT：챌린지 걸즈　RHB：로드 투 프린스
        ・마스코트 폭주표　RU
        ・버스트 타임　nC：バーストタイム(n：온도)　BU：バースト表
        ・攻撃　n[S]A[r][+m/-m](n：振る数　S：失敗しない　r：取り除く出目　m：修正値)
        ・かんたんパーソン表　SIP
        ・회장표
        　BVT：대형 예능 프로덕션　LVT：약소 예능 프로덕션　TVT：라이브 시어터　CVT：아이돌 부
        ・장소표
        　BST：대형 예능 프로덕션　LST：약소 예능 프로덕션　TST：라이브 시어터　CST：아이돌 부
        ・프레셔 종류 결정표
        　BPT：대형 예능 프로덕션　LPT：약소 예능 프로덕션　TPT：라이브 시어터　CPT：아이돌 부
        ・도구표
        　BIT：대형 예능 프로덕션　LIT：약소 예능 프로덕션　TIT：라이브 시어터　CIT：아이돌 부
        []内は省略可　D66 다이스가 존재
      INFO_MESSAGE_TEXT

      register_prefix_from_super_class()

      def initialize(command)
        super(command)

        @locale = :ko_kr
      end

      TABLES = translate_tables(:ko_kr)

      BAD_STATUS_TABLE = BadStatusTable.new(:ko_kr)

      LOCAL_WORK_TABLE = translate_local_work_table(:ko_kr)
      ITEM_TABLE = ItemTable.new(:ko_kr)

      SKILL_TABLE = translate_skill_table(:ko_kr)
    end
  end
end
