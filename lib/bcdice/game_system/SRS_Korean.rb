# frozen_string_literal: true

require 'bcdice/arithmetic_evaluator'
require 'bcdice/game_system/SRS'

module BCDice
  module GameSystem
    class SRS_Korean < SRS
      # ゲームシステムの識別子
      ID = 'SRS:Korean'

      # ゲームシステム名
      NAME = '스탠다드 RPG 시스템(SRS)'

      # ゲームシステム名の読みがな
      SORT_KEY = '国際化:Korean:스탠다드 RPG 시스템(SRS)'

      HELP_MESSAGE_1 = <<~HELP_MESSAGE
        ・판정
        　・일반판정: 2D6+m@c#f>=t 또는 2D6+m>=t[c,f]
        　　수정치 m, 목표치 t, 크리티컬치 c, 펌블치 f로 판정합니다.
        　　수정치, 크리티컬치, 펌블치는 생략 가능합니다([]째로 생략 가능, @c・#f 지정 순서는 상관없음).
        　　크리티컬치, 펌블치의 기본값은 각각 12, 2입니다.
        　　자동성공, 자동실패, 성공, 실패를 자동 표시합니다.

        　　예) 2d6>=10　　　　　수정치 0, 목표치 10으로 판정
        　　예) 2d6+2>=10　　　　수정치 +2, 목표치 10으로 판정
        　　예) 2d6+2>=10[11]　　↑를 크리티컬치 11로 판정
        　　예) 2d6+2@11>=10 　　↑를 크리티컬치 11로 판정
        　　예) 2d6+2>=10[12,4]　↑를 크리티컬치 12, 펌블치 4로 판정
        　　예) 2d6+2@12#4>=10 　↑를 크리티컬치 12, 펌블치 4로 판정
        　　예) 2d6+2>=10[,4]　　↑를 크리티컬치 12, 펌블치 4로 판정 (크리티컬치 생략)
        　　예) 2d6+2#4>=10　　　↑를 크리티컬치 12, 펌블치 4로 판정 (크리티컬치 생략)
      HELP_MESSAGE

      HELP_MESSAGE_2 = <<~HELP_MESSAGE
        　・크리티컬 및 펌블만 판정: 2D6+m@c#f 또는 2D6+m[c,f]
        　　목표치를 지정하지 않고, 수정치 m, 크리티컬치 c, 펌블치 f로 판정합니다.
        　　수정치, 크리티컬치, 펌블치는 생략 가능합니다([]는 생략 불가, @c・#f 지정 순서는 상관없음).
        　　자동성공, 자동실패를 자동 표시합니다.

        　　예) 2d6[]　　　　수정치 0, 크리티컬치 12, 펌블치 2로 판정
        　　예) 2d6+2[11]　　수정치 +2, 크리티컬치 11, 펌블치 2로 판정
        　　예) 2d6+2@11 　　수정치 +2, 크리티컬치 11, 펌블치 2로 판정
        　　예) 2d6+2[12,4]　수정치 +2, 크리티컬치 12, 펌블치 4로 판정
        　　예) 2d6+2@12#4 　수정치 +2, 크리티컬치 12, 펌블치 4로 판정
      HELP_MESSAGE

      HELP_MESSAGE_3 = <<~HELP_MESSAGE
        ・D66 주사위 있음 (순서 교체 없음)
      HELP_MESSAGE

      # 既定のダイスボット説明文
      DEFAULT_HELP_MESSAGE = "#{HELP_MESSAGE_1}\n#{HELP_MESSAGE_2}\n#{HELP_MESSAGE_3}"

      HELP_MESSAGE = DEFAULT_HELP_MESSAGE

      register_prefix_from_super_class()

      # ダイスボットを初期化
      def initialize(command)
        super(command)
        @locale = :ko_kr
      end
    end
  end
end
