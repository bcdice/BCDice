# frozen_string_literal: true

require 'bcdice/game_system/Irisbane'

module BCDice
  module GameSystem
    class Irisbane_Korean < Irisbane
      # ゲームシステムの識別子
      ID = 'Irisbane:Korean'

      # ゲームシステム名
      NAME = '눈 돌리지 않는 이리스베인'

      # ゲームシステム名の読みがな
      SORT_KEY = '国際化:Korean:눈 돌리지 않는 이리스베인'

      # ダイスボットの使い方
      HELP_MESSAGE = <<~HELP
        ■공격 판정（ ATTACKx@y<=z ）
        x: 공격력
        y: 판정 수
        z: 목표값
        （※ ATTACK 은 ATK 또는 AT 로 줄여 쓸 수 있습니다）
        예） ATTACK2@3<=5
        예） ATK10@2<=4
        예） AT8@3<=2

        위 x y z 에는 각각 사칙연산을 지정할 수 있습니다.
        예） ATTACK2+7@3*2<=5-1

        □공격 판정의 데미지 증감（ ATTACKx@y<=z[+a]  ATTACKx@y<=z[-a]）
        말미에 [+a] 또는 [-a] 를 지정하면 최종 데미지를 증감할 수 있습니다.
        a: 증감량
        예） ATTACK2@3<=5[+10]
        예） ATK10@2<=4[-8]
        예） AT8@3<=2[-8+5]

        ■시추에이션（p115）
        SceneSituation, SSi
      HELP

      def initialize(command)
        super(command)
        @locale = :ko_kr
      end

      TABLES = translate_tables(:ko_kr).freeze

      register_prefix_from_super_class()
    end
  end
end
