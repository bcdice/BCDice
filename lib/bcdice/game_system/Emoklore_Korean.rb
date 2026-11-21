# frozen_string_literal: true

require 'bcdice/game_system/Emoklore'

module BCDice
  module GameSystem
    class Emoklore_Korean < Emoklore
      # ゲームシステムの識別子
      ID = "Emoklore:Korean"

      # ゲームシステム名
      NAME = "에모크로아TRPG"

      # ゲームシステム名の読みがな
      #
      # 「ゲームシステム名の読みがなの設定方法」（docs/dicebot_sort_key.md）を参考にして
      # 設定してください
      SORT_KEY = "国際化:Korean:에모크로아TRPG"

      # ダイスボットの使い方
      HELP_MESSAGE = <<~MESSAGETEXT
        ・기능치 판정（xDM<=y / xDM<=yEz）
          "(개수)DM<=(판정치)"로 판정합니다.
          주사위의 개수는 생략 가능하며, 생략 시 1개로 설정됩니다.
          주사위 개수와 판정치에는 사칙연산（+-*/）을 사용할 수 있습니다.
          수식 끝에 Ez를 붙이면 주사위 수에 z를 더합니다. E-z로 빼기도 가능합니다.
          ex）2DM<=5　DM<=8　2DM<=3+2
              2+2DM<=5 → 주사위 4개로 판정치 5
              2DM<=5E2 → 주사위 2+2 = 주사위 4개로 판정치 5
              3DM<=5E-1 → 주사위 3-1 = 주사위 2개로 판정치 5
            ※주사위 수가 0 이하가 되는 경우 확정 실패

        ・기능치 판정（sDAa+z)
          "(기능 레벨)DA(능력치)+(주사위 보너스)"로 판정합니다.
          주사위 보너스의 개수는 생략 가능하며, 생략 시 0개로 설정됩니다.
          기능 레벨에는 1~3의 수치를 입력합니다. 기본 기능으로 판정하려면 기능 레벨에"b"를 입력하세요.
          주사위 개수는 기능 레벨과 주사위 보너스 개수에 따라 결정되며, s+z개의 주사위를 굴립니다. (s="b"인 경우 s=1)
          판정치는 s+a 입니다.（s="b"인 경우에는 s=0）
      MESSAGETEXT

      register_prefix_from_super_class()

      def initialize(command)
        super(command)

        @locale = :ko_kr
      end
    end
  end
end
