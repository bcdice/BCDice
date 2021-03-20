# frozen_string_literal: true

require "bcdice/game_system/Cthulhu"

module BCDice
  module GameSystem
    class Cthulhu_Korean < Cthulhu
      # ゲームシステムの識別子
      ID = 'Cthulhu:Korean'

      # ゲームシステム名
      NAME = '크툴루'

      # ゲームシステム名の読みがな
      SORT_KEY = '国際化:Korean:크툴루'

      # ダイスボットの使い方
      HELP_MESSAGE = <<~INFO_MESSAGE_TEXT
        c=크리티컬치 ／ f=펌블치 ／ s=스페셜

        1d100<=n    c・f・s 모두 오프（단순하게 수치만을 뽑아낼 때 사용）

        ・cfs이 붙는 판정의 커맨드

        CC	 1d100 판정을 행함 c=1、f=100
        CCB  위와 동일、c=5、f=96

        예：CC<=80  （기능치 80로 행휘판정. 1%룰으로 cf적용）
        예：CCB<=55 （기능치 55로 행휘판정. 5%룰으로 cf적용）

        ・경우의 수 판정에 대해서

        CBR(x,y)	c=1、f=100
        CBRB(x,y)	c=5、f=96

        ・저항 판정에 대해서
        RES(x-y)	c=1、f=100
        RESB(x-y)	c=5、f=96

        ※고장 넘버 판정

        ・CC(x) c=1、f=100
        x=고장 넘버. 주사위 눈x이상이 나온 후에, 펌블이 동시에 발생했을 경우. 모두 출력한다. （텍스트 「펌블＆고장」）
        펌블이 아닌 경우, 성공・실패에 관련되지 않고 「고장」만을 출력한다. （성공・실패를 출력하지 않고 덧쓰기한 것을 출력하는 형태）

        ・CCB(x) c=5、f=96
        위와 동일
      INFO_MESSAGE_TEXT

      register_prefix_from_super_class()

      def initialize(command)
        super(command)

        @locale = :ko_kr
      end
    end
  end
end
