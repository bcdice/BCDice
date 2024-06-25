# frozen_string_literal: true

require "bcdice/game_system/UnsungDuet"

module BCDice
  module GameSystem
    class UnsungDuet_Korean < UnsungDuet
      ID = 'UnsungDuet:Korean'
      NAME = '언성 듀엣'
      SORT_KEY = '国際化:Korean:언성 듀엣'

      HELP_MESSAGE = <<~MESSAGETEXT
        ■ 시프터 용 판정 (shifter, UDS)
          1D10을 다이스롤 해서 판정을 행합니다.
          예） shifter, UDS, shifter>=5, shifter+1>=6

        ■ 바인더 용 판정 (binder, UDB)
          2D6을 다이스롤 해서 판정을 행합니다.
          예） binder, UDB, binder>=5, binder+1>=6

        ■ 변이표
          ・상처 (HIN, HInjury)
          ・몸 상태의 변화 (HPH, HPhysical)
          ・공포 (HFE, HFear)
          ・환상화 (HFA, HFantasy)
          ・정신 (HMI, HMind)
          ・기타 (HOT, HOther)
      MESSAGETEXT

      register_prefix_from_super_class()

      def initialize(command)
        super(command)

        @locale = :ko_kr
      end

      TABLES = translate_tables(:ko_kr)
    end
  end
end
