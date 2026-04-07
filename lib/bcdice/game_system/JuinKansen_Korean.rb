# frozen_string_literal: true

require "bcdice/game_system/JuinKansen"

module BCDice
  module GameSystem
    class JuinKansen_Korean < JuinKansen
      # ゲームシステムの識別子
      ID = "JuinKansen:Korean"

      # ゲームシステム名
      NAME = "주인감염"

      # ゲームシステム名の読みがな
      SORT_KEY = "国際化:Korean:주인감염"

      # ダイスボットの使い方
      HELP_MESSAGE = <<~INFO_MESSAGE_TEXT
        ■ 표
          ・일상 표 (DAI, Daily)
          ・장소 표
            ・「도시」 (PCI, PlaceCity)
            ・「시골」 (PCO, PlaceCountryside)
            ・「시설 안」 (PFA, PlaceFacility)
          ・초면 표 (FL, FirstLook)
          ・친구 표 (AF, AppreciativeFriend)
          ・복선 표 (FOR, Foreshadow)
          ・감정 표 (EMO, Emotion)
          ・상황 표 (SIT, Situation)
          ・대상 표 (TAR, Target)
          ・광기 표 (INS, Insanity)
          ・종말 표 (DEA, Death)
          ・공포 표 (FEA, Fear)
      INFO_MESSAGE_TEXT

      register_prefix_from_super_class()

      def initialize(command)
        super(command)
        @locale = :ko_kr
      end

      TABLES = translate_tables(:ko_kr).freeze
    end
  end
end
