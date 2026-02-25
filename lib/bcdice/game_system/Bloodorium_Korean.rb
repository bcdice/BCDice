# frozen_string_literal: true

require 'bcdice/game_system/Bloodorium'

module BCDice
  module GameSystem
    class Bloodorium_Korean < Bloodorium
      # ゲームシステムの識別子
      ID = 'Bloodorium:Korean'

      # ゲームシステム名
      NAME = '블러도리움'

      # ゲームシステム名の読みがな
      SORT_KEY = '国際化:Korean:블러도리움'

      # ダイスボットの使い方
      HELP_MESSAGE = <<~INFO_MESSAGE_TEXT
        ・주사위 체크 xDC+y
        　【주사위 체크】를 실행한다.《트라이엄프》를 결과에 자동 반영한다.
        　x: 주사위 수
        　y: 결과에 대한 수정값 (생략 가능)
      INFO_MESSAGE_TEXT

      register_prefix_from_super_class()

      def initialize(command)
        super(command)

        @locale = :ko_kr
      end
    end
  end
end