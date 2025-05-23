# frozen_string_literal: true

require "bcdice/game_system/StratoShout"

module BCDice
  module GameSystem
    class StratoShout_Korean < StratoShout
      # ゲームシステムの識別子
      ID = 'StratoShout:Korean'

      # ゲームシステム名
      NAME = '스트라토 샤우트'

      # ゲームシステム名の読みがな
      SORT_KEY = '国際化:Korean:스트라토 샤우트'

      # ダイスボットの使い方
      HELP_MESSAGE = <<~INFO_MESSAGE_TEXT
        VOT, GUT, BAT, KEYT, DRT: (보컬, 기타, 베이스, 키보드, 드럼)트러블표
        EMO: 감정표
        RTT[1-6], AT[1-6]: 특기표(공백: 랜덤 1: 가치관 2: 신체 3: 모티브 4: 이모션 5: 행동 6: 역경)
        SCENE, MACHI, GAKKO, BAND: (범용, 거리, 학교, 밴드)장면표. 접근 장면에 사용
        TENKAI: 장면 전개표. 분주 장면, 연습 장면에 사용
        []내는 생략가능　D66는 변동있음
      INFO_MESSAGE_TEXT

      register_prefix_from_super_class()

      def initialize(command)
        super(command)

        @locale = :ko_kr
      end

      TABLES = translate_tables(:ko_kr).freeze
      RTT = translate_rtt(:ko_kr)
    end
  end
end
