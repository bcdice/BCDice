# frozen_string_literal: true

require 'bcdice/game_system/Alsetto'

module BCDice
  module GameSystem
    class Alsetto_Korean < Alsetto
      # ゲームシステムの識別子
      ID = 'Alsetto:Korean'

      # ゲームシステム名
      NAME = '시편의 알세토'

      # ゲームシステム名の読みがな
      SORT_KEY = '国際化:Korean:시편의 알세토'

      # ダイスボットの使い方
      HELP_MESSAGE = <<~MESSAGETEXT
        ・성공 판정：nAL[m]　　　　・트라이엄프 없음：nALC[m]
        ・명중 판정：nAL[m]*p　　　・트라이엄프 없음：nALC[m]*p
        ・명중 판정(건슬링거의 근원시)：nALG[m]*p
        [] 내부는 생략 가능.

        AL 커맨드는 트라이엄프 수만큼, 자동으로 추가 주사위 굴림 처리를 수행합니다.
        「n」으로 주사위 수를 지정.
        「m」으로 목표치를 지정. 생략 시에는 기본값인 「3」이 사용됩니다.
        「p」로 공격력을 지정. 「*」 대신 「x」도 사용 가능.
        공격력을 지정하면 명중 판정이 되며, 성공수가 아닌 대미지를 결과로 표시합니다.

        ALC 커맨드는 트라이엄프 없이 성공수, 대미지를 결과로 표시합니다.
        ALG 커맨드는 「2 이하」에서 트라이엄프 처리를 수행합니다.

        【사용 예시】
        ・5AL → 5d6에서 목표치 3.
        ・5ALC → 5d6에서 목표치 3. 트라이엄프 없음.
        ・6AL2 → 6d6에서 목표치 2.
        ・4AL*5 → 4d6에서 목표치 3, 공격력 5의 명중 판정.
        ・7AL2x10 → 7d6에서 목표치 2, 공격력 10의 명중 판정.
        ・8ALC4x5 → 8d6에서 목표치 4, 공격력 5, 트라이엄프 없는 명중 판정.
      MESSAGETEXT

      register_prefix_from_super_class()

      def initialize(command)
        super(command)

        @locale = :ko_kr
      end
    end
  end
end
