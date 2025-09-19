# frozen_string_literal: true

require "bcdice/game_system/Nechronica"

module BCDice
  module GameSystem
    class Nechronica_Korean < Nechronica
      # ゲームシステムの識別子
      ID = 'Nechronica:Korean'

      # ゲームシステム名
      NAME = '네크로니카'

      # ゲームシステム名の読みがな
      SORT_KEY = '国際化:Korean:네크로니카'

      # ダイスボットの使い方
      HELP_MESSAGE = <<~INFO_MESSAGE_TEXT
        ・판정　(nNC+m)
        　주사위 수n, 수정치m으로 판정굴림을 행합니다.
        　주사위 수가 2개 이상일 때에 파츠파손 수도 표시합니다.
        ・공격판정　(nNA+m)
        　주사위 수n, 수정치m으로 공격판정굴림을 행합니다.
        　명중부위와 주사위 수가 2개 이상일 때에 파츠파손 수도 표시합니다.

        표
        ・자매에 대한 미련표 nm
        ・중립자에 대한 미련표 nmn
        ・적에 대한 미련표 nme
      INFO_MESSAGE_TEXT

      register_prefix_from_super_class()

      def initialize(command)
        super(command)

        @locale = :ko_kr
      end

      TABLES = translate_tables(:ko_kr)
    end
  end
end
