# frozen_string_literal: true

require "bcdice/game_system/FinalFantasyXIV"

module BCDice
  module GameSystem
    class FinalFantasyXIV_English < FinalFantasyXIV
      # ゲームシステムの識別子
      ID = "FinalFantasyXIV:English"

      # ゲームシステム名
      NAME = "FINAL FANTSY XIV TTRPG(English)"

      # ゲームシステム名の読みがな
      SORT_KEY = "国際化:English:FINAL FANTASY XIV TTRPG"

      HELP_MESSAGE = <<~TEXT
        Ability Checks nAB+m>=CR
          Perform a d20 ability check. If a die count is specified, the highest roll is adopted.
          n: die count(optional)
          m: modifiy number(optional)
          CR: Challenge Ratting(optional)
          Base Effect only, Direct hit and Critical are automatically evaluated.
          Example: AB, AB+5, AB+5>=14, 2AB+5>=14
        Making checks nDC+m>=CR
          Same as ability check.
          Success and Failure ar automatically evaluated.
      TEXT

      register_prefix_from_super_class()

      def initialize(command)
        super(command)

        @locale = :en_us
      end
    end
  end
end
