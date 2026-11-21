# frozen_string_literal: true

require 'bcdice/game_system/AnimaAnimus'

module BCDice
  module GameSystem
    class AnimaAnimus_Korean < AnimaAnimus
      # ゲームシステムの識別子
      ID = 'AnimaAnimus:Korean'

      # ゲームシステム名
      NAME = '아니마 아니무스'

      # ゲームシステム名の読みがな
      SORT_KEY = '国際化:Korean:아니마 아니무스'

      # ダイスボットの使い方
      HELP_MESSAGE = <<~MESSAGETEXT
        ・행위 판정(xAN<=y±z)
        　십면체 주사위를 x개 굴려서 판정합니다. 달성치가 산출됩니다(크리티컬 발생 시 2 증가).
        　x：굴리는 주사위의 수. 혼백값이나 공격값.
        　y：성공값.
        　z：성공값에 대한 보정. 생략 가능.
        　(예) 2AN<=3+1 5AN<=7
        ・각종 표
        　정보 수집표　IGT/상실표　LT
      MESSAGETEXT

      TABLES = translate_tables(:ko_kr).freeze

      def initialize(command)
        super(command)
        @locale = :ko_kr
      end

      register_prefix('\d+AN<=', TABLES.keys)
    end
  end
end
