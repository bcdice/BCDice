# frozen_string_literal: true

require 'bcdice/game_system/Ventangle'

module BCDice
  module GameSystem
    class Ventangle_Korean < Ventangle
      # ゲームシステムの識別子
      ID = 'Ventangle:Korean'

      # ゲームシステム名
      NAME = '벤탱글'

      # ゲームシステム名の読みがな
      SORT_KEY = '国際化:Korean:벤탱글'

      # ダイスボットの使い方
      HELP_MESSAGE = <<~MESSAGETEXT
        기본 양식 VTn@s#f$g>=T n=주사위 개수（생략 시 2） s=스페셜치（생략 시 12） f=펌블치（생략 시 2） g=레벨 갭 판정치（생략 가능） T=목표치（생략 가능）

        예시：
        VT        기본 스페셜치, 펌블치로 판정
        VT@10#3   스페셜치 10, 펌블치 3으로 판정
        VT3@10#3  어드밴티지 1점을 사용해 스페셜치 10, 펌블치 3 판정을 주사위 3개로 판정

        VT>=5         기본 스페셜치, 펌블치로 목표치 5 판정
        VT@10#3>=5    스페셜치 10, 펌블치 3으로 목표치 5 판정
        VT@10#3$5>=5  스페셜치 10, 펌블치 3으로 목표치 5 판정. 이때 달성치가 목표치보다 5이상 큰 경우, 갭 보너스를 표시
        VT3@10#3>=5   어드밴티지 1점을 사용해 스페셜치 10, 펌블치 3, 목표치 5 판정을 주사위 3개로 판정
        VT3@10#3$4>=5 어드밴티지 1점을 사용해 스페셜치 10, 펌블치 3, 목표치 5 판정을 주사위 3개로 판정. 이때 달성치가 목표치보다 4이상 큰 경우, 갭 보너스를 표시
      MESSAGETEXT

      register_prefix_from_super_class()

      def initialize(command)
        super(command)
        @locale = :ko_kr
      end
    end
  end
end
