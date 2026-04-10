# frozen_string_literal: true

require 'bcdice/game_system/KemonoNoMori'

module BCDice
  module GameSystem
    class KemonoNoMori_Korean < KemonoNoMori
      # ゲームシステムの識別子
      ID = 'KemonoNoMori:Korean'

      # ゲームシステム名
      NAME = '짐승의 숲'

      # ゲームシステム名の読みがな
      SORT_KEY = '国際化:Korean:짐승의 숲'

      # ダイスボットの使い方
      HELP_MESSAGE = <<~MESSAGETEXT
        ・행위 판정（성공도 자동 산출）（P119）: KAx[±y]
        ・지속 판정（성공도+1 고정）: KCx[±y]
           x=목표치
           y=목표치에 대한 수정（임의） x+y-z 처럼 여러 개 지정 가능
             예1）KA7+3 → 목표치7에 +3 수정을 더한 행위 판정
             예2）KC6 → 목표치6의 지속 판정
        ・함정 작동 체크+먹잇감표（P163）: CTR
           함정마다 1D12를 굴려, 12가 나온 경우 생물이 함정을 작동시켜 그 영향을 받고 있다.
        ・각종 표（기본 룰북）
          ・대실패표（P120）: FT
          ・능력치 무작위 결정표（P121）: RST
          ・무작위 소요 시간표（P122）: RTT
          ・무작위 소모표（P122）: RET
          ・무작위 날씨표（P128）: RWT
          ・무작위 날씨 지속표（P128）: RWDT
          ・무작위 엄폐물표（야외）（P140）: ROMT
          ・무작위 엄폐물표（실내）（P140）: RIMT
          ・도주 체험표（P144）: EET
          ・식재료 채집표（P157）: GFT
          ・물 채집표（P157）: GWT
          ・백색 마석 효과표（P186）: WST
        ・부위 피해 관련 표（참조 페이지는 리플레이&데이터북 「가미신의 연회」 기준）
          ・인간 부위표（P216）: HPT
          ・부위 피해 단계표（P217）: PDT
          ・네발 동물 부위표（P225）: QPT
          ・무족류 부위표（P225）: APT
          ・두발 동물 부위표（P226）: TPT
          ・새 부위표（P226）: BPT
          ・두족류 부위표（P227）: CPT
          ・곤충 부위표（P227）: IPT
          ・거미 부위표（P228）: SPT
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
