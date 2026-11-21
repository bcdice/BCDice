# frozen_string_literal: true

require 'bcdice/game_system/YearZeroEngine'

module BCDice
  module GameSystem
    class YearZeroEngine_Korean < YearZeroEngine
      # ゲームシステムの識別
      ID = 'YearZeroEngine:Korean'

      # ゲームシステム名
      NAME = '이어 제로 엔진(Year Zero Engine)'

      # ゲームシステム名の読みがな
      SORT_KEY = '国際化:Korean:이어 제로 엔진(Year Zero Engine)'

      # ダイスボットの使い方
      HELP_MESSAGE = <<~INFO_MESSAGE_TEXT
        ・다이스 풀 판정 커맨드(nYZEx+x+x+m)
          (난이도)YZE(능력 주사위 수)+(기능 주사위 수)+(아이템 주사위 수)+(수정치)  # (6만 셈함)
          (난이도)YZE(능력 주사위 수)+(기능 주사위 수)+(아이템 주사위 수)-(수정치)  # (6만 셈함)

        ・다이스 풀 판정 커맨드(nMYZx+x+x)
          (난이도)MYZ(능력 주사위 수)+(기능 주사위 수)+(아이템 주사위 수)  # (1과 6을 세어 푸시 가능 수 표시)
          (난이도)MYZ(능력 주사위 수)-(기능 주사위 수)+(아이템 주사위 수)  # (1과 6을 세어 푸시 가능 수 표시, 기능 마이너스 지정)

          ※ 난이도, 기능 주사위 수, 아이템 주사위 수는 생략 가능

        ・스텝 다이스 판정 커맨드(nYZSx+x+m+f)
          (난이도)YZS(능력 주사위 면 수)+(기능 주사위 면 수)+(수정치)   # (1, 6을 세어 푸시 가능 수 표시)
          (난이도)YZS(능력 주사위 면 수)+(기능 주사위 면 수)-(수정치)   # (1, 6을 세어 푸시 가능 수 표시)
          (난이도)YZS(능력 주사위 면 수)+(기능 주사위 면 수)+(수정치)A  # (1, 6을 세어 푸시 가능 수 표시, 유리)
          (난이도)YZS(능력 주사위 면 수)+(기능 주사위 면 수)-(수정치)A  # (1, 6을 세어 푸시 가능 수 표시, 유리)
          (난이도)YZS(능력 주사위 면 수)+(기능 주사위 면 수)+(수정치)D  # (1, 6을 세어 푸시 가능 수 표시, 불리)
          (난이도)YZS(능력 주사위 면 수)+(기능 주사위 면 수)-(수정치)D  # (1, 6을 세어 푸시 가능 수 표시, 불리)
      INFO_MESSAGE_TEXT

      register_prefix_from_super_class()

      def initialize(command)
        super(command)
        @locale = :ko_kr
      end
    end
  end
end
