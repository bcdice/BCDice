# frozen_string_literal: true

require "bcdice/game_system/MagicPunk"

module BCDice
  module GameSystem
    class MagicPunk_Korean < MagicPunk
      # ゲームシステムの識別子
      ID = "MagicPunk:Korean"

      # ゲームシステム名
      NAME = "매직펑크TRPG"

      # ゲームシステム名の読みがな
      SORT_KEY = "国際化:Korean:매직펑크TRPG"

      HELP_MESSAGE = <<~TEXT
        ■ 판정 (nMPm)
        nD20을 굴려, m 이하의 눈이 있으면 성공.
        m과 같은 눈이 있으면 잭팟(자동 성공).
        모든 눈이 1이면 배드 비트(자동 실패).

        ■ 챌린지 판정 (nMPmCx)
        통상 판정에 더해, 챌린지 값 x 이상의 눈이 필요.

        ■ 주사위 수 0개 (0MPmCx)
        수정치 등으로 주사위 수가 0개가 된 경우 2d20을 굴림.
        두 개의 눈 중 더 나쁜 쪽의 결과를 적용.
      TEXT

      register_prefix_from_super_class()

      def initialize(command)
        super(command)
        @locale = :ko_kr
      end
    end
  end
end
