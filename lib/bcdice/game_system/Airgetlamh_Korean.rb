# frozen_string_literal: true

require "bcdice/game_system/Airgetlamh"

module BCDice
  module GameSystem
    class Airgetlamh_Korean < Airgetlamh
      # ゲームシステムの識別子
      ID = 'Airgetlamh:Korean'

      # ゲームシステム名
      NAME = '붉은 고탑의 에어게트람'

      # ゲームシステム名の読みがな
      SORT_KEY = '国際化:Korean:붉은 고탑의 에어게트람'

      HELP_MESSAGE = <<~MESSAGETEXT
        【Reg2.0『THE ANSWERER』～】
        ・조사 판정（성공 수 표시）：[n]AA[m]
        ・명중 판정（대미지 표시）：[n]AA[m]*p[+t][Cx]
        【～Reg1.1『승화(昇華)』】
        ・조사 판정（성공 수 표시）：[n]AL[m]
        ・명중 판정（대미지 표시）：[n]AL[m]*p
        ----------------------------------------
        []안의 커맨드는 생략 가능.

        「n」으로 주사위 수（공격 횟수）지정. 생략 시「2」.
        「m」으로 목표값 지정. 생략 시「6」.
        「p」으로 위력 지정.「*」는「x」로 대체 가능.
        「+t」으로 크리티컬 트리거 지정. 생략 가능.
        「Cx」으로 크리티컬 값 지정. 생략 시「1」, 최대값「3」,「0」은 크리티컬 없음.

        공격력 지정으로 명중 판정이 되며, 성공 수가 아닌 대미지를 결과로 표시합니다.
        크리티컬 히트 수만큼 자동으로 추가 굴림 처리를 합니다.
        （AL 커맨드에서는 크리티컬 처리를 하지 않습니다）

        【사용 예시】
        ・AL → 2d10으로 목표값 6의 조사 판정.
        ・5AA7*12 → 5d10으로 목표값 7, 위력 12의 명중 판정.
        ・AA7x28+5 → 2d10으로 목표값 7, 위력 28, 크리티컬 트리거 5의 명중 판정.
        ・9aa5*10C2 → 9d10으로 목표값 5, 위력 10, 크리티컬 값 2의 명중 판정.
        ・15AAx4c0 → 15d10으로 목표값 6, 위력 4, 크리티컬 없음의 명중 판정.
      MESSAGETEXT

      register_prefix_from_super_class()

      def initialize(command)
        super(command)
        @locale = :ko_kr
      end
    end
  end
end
