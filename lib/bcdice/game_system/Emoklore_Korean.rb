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
        ・기능치 판정（xDM<=y）
          "(개수)DM<=(판정치)"로 판정합니다.
          주사위의 개수는 생략 가능하며, 생략 시 1개로 설정됩니다.
          ex）2DM<=5 DM<=8

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
