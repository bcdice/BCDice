# frozen_string_literal: true

require "bcdice/game_system/Cthulhu"

module BCDice
  module GameSystem
    class Cthulhu_English < Cthulhu
      # ゲームシステムの識別子
      ID = 'Cthulhu:English'

      # ゲームシステム名
      NAME = 'Call of Cthulhu'

      # ゲームシステム名の読みがな
      SORT_KEY = '国際化:English:Call of Cthulhu'

      # ダイスボットの使い方
      HELP_MESSAGE = <<~INFO_MESSAGE_TEXT
        c=Critical Rate ／ f=Fumble Rate ／ s=Special

        1d100<=n    c・f・s AllOff（Does Simple Numeric Comparison Only）

        ・Roll Command that determines cfs

        CC	 Does a 1d100 roll c=1、f=100
        CCB  Same as above、c=5、f=96

        Ex：CC<=80  （Rolls using 80 as skill value with 1% cf rule applied）
        Ex：CCB<=55 （Rolls using 55 as skill value with 5% cf rule applied）

        ・About Roll Combination

        CBR(x,y)	c=1、f=100
        CBRB(x,y)	c=5、f=96

        ・About Opposed Rolls
        RES(x-y)	c=1、f=100
        RESB(x-y)	c=5、f=96

        ※Malfunction Number Determination

        ・CC(x) c=1、f=100
        x=Malfunction Number. Outputs（text "Fumble&Malfunction"）together, when roll result is equal or above x, and fumble happens simultaneously.
        If not a fumble, outputs text "Malfunction" regardless of success/failure（Outputs the overwritten result, not outputting success/failure）

        ・CCB(x) c=5、f=96
        Same as above
      INFO_MESSAGE_TEXT

      register_prefix_from_super_class()

      def initialize(command)
        super(command)

        @locale = :en_us
      end
    end
  end
end
