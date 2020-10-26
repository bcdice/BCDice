# frozen_string_literal: true

require "bcdice/game_system/DetatokoSaga"

module BCDice
  module GameSystem
    class DetatokoSaga_Korean < DetatokoSaga
      # ゲームシステムの識別子
      ID = 'DetatokoSaga:Korean'

      # ゲームシステム名
      NAME = '데타토코 사가'

      # ゲームシステム名の読みがな
      SORT_KEY = '国際化:Korean:데타토코 사가'

      # ダイスボットの使い方
      HELP_MESSAGE = <<~INFO_MESSAGE_TEXT
        ・통상판정　xDS or xDSy or xDS>=z or xDSy>=z
        　(x＝스킬레벨, y＝현재 플래그(생략=0), z＝목표치(생략=８))
        　예）3DS　2DS5　0DS　3DS>=10　3DS7>=12
        ・판정치　xJD or xJDy or xJDy+z or xJDy-z or xJDy/z
        　(x＝스킬레벨, y＝현재 플래그(생략=0), z＝수정치(생략=０))
        　예）3JD　2JD5　3JD7+1　4JD/3
        ・체력 낙인표　SST (StrengthStigmaTable)
        ・기력 낙인표　WST (WillStigmaTable)
        ・체력 배드엔딩표　SBET (StrengthBadEndTable)
        ・기력 배드엔딩표　WBET (WillBadEndTable)
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
