# frozen_string_literal: true

module BCDice
  module GameSystem
    class ZombiLine_Korean < ZombiLine
      # ゲームシステムの識別子
      ID = "ZombiLine:Korean"

      # ゲームシステム名
      NAME = "좀비 라인"

      # ゲームシステム名の読みがな
      SORT_KEY = "国際化:Korean:좀비 라인"

      HELP_MESSAGE = <<~TEXT
        ■ 판정 (xZL<=y)
        　x：주사위 개수(생략 시 1)
        　y：성공률

        ■ 각종 표
        　스트레스 증상표 SST
        　식재료 표 IT
      TEXT

      register_prefix_from_super_class()

      def initialize(command)
        super(command)
        @locale = :ko_kr
      end

      TABLES = translate_tables(:ko_kr).freeze
    end
  end
end
