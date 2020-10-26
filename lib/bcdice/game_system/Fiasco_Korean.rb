# frozen_string_literal: true

require "bcdice/game_system/Fiasco"

module BCDice
  module GameSystem
    class Fiasco_Korean < Fiasco
      # ゲームシステムの識別子
      ID = 'Fiasco:Korean'

      # ゲームシステム名
      NAME = '피아스코'

      # ゲームシステム名の読みがな
      SORT_KEY = '国際化:Korean:피아스코'

      # ダイスボットの使い方
      HELP_MESSAGE = <<INFO_MESSAGE_TEXT
  ・판정 커맨드(FSx, WxBx)
    관계, 비틀기 요소용(FSx)：관계나 비틀기 요소를 위해 x개의 다이스를 굴려 나온 값별로 분류한다.
    흑백차이판정용(WxBx)    ：비틀기, 후기를 위해 흰 다이스(W지정)과 검은 다이스(B지정)으로 차이를 구한다.
      ※ W와B는 한 쪽만 지정(Bx, Wx), 앞뒤 바꿔 지정(WxBx,BxWx)도 가능
INFO_MESSAGE_TEXT

      register_prefix_from_super_class()

      def initialize(command)
        super(command)

        @locale = :ko_kr
      end
    end
  end
end
