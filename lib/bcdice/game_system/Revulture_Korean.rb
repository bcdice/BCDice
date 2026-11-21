# frozen_string_literal: true

require "bcdice/game_system/Revulture"

module BCDice
  module GameSystem
    class Revulture_Korean < Revulture
      # ゲームシステムの識別子
      ID = 'Revulture:Korean'

      # ゲームシステム名
      NAME = '광쇄의 리벌처'

      # ゲームシステム名の読みがな
      SORT_KEY = '国際化:Korean:광쇄의 리벌처'

      # ダイスボットの使い方
      HELP_MESSAGE = <<~HELP
        ■공격 판정（ xAT, xATK, xATTACK ）
        x: 주사위 수（덧셈 + 과 나눗셈 / 사용 가능）
        예시） 3AT, 4ATK, 5+6ATTACK, 15/2AT

        □공격 판정 목표값 포함（ xAT<=y, xATK<=y, xATTACK<=y ）
        x: 주사위 수（덧셈 + 과 나눗셈 / 사용 가능）
        y: 목표값（ 1 이상 6 이하. 덧셈 + 사용 가능）
        예시） 3AT<=4, 3AT<=2+1

        □공격 판정　목표값＆추가 대미지 포함（ xAT<=y[>=a:+b], xATK<=y[>=a:+b], xATTACK<=y[z] ）
        x: 주사위 수（덧셈 + 과 나눗셈 / 사용 가능）
        y: 목표값（ 1 이상 6 이하. 덧셈 + 사용 가능）
        z: 추가 대미지 규칙（자세한 내용은 아래 참고）（※여러 개를 동시에 사용 가능）

        ▽추가 대미지 규칙 [a:+b]
        a: 히트 수가 a 라면
        　=a　（히트 수가 a와 동일）
        　>=a　（히트 수가 a 이상）
        b: 대미지를 b 점 추가

        예시） 3AT<=4[>=2:+3] #룰 북 p056「그레인그랜트 AR(グレングラントAR)」
        예시） 2AT<=4[=1:+5][>=2:+8] #룰 북 p067「파보르 드래곤 브레스(ファーボル・ドラゴンブレス)」
      HELP

      register_prefix_from_super_class()

      def initialize(command)
        super(command)
        @locale = :ko_kr
      end
    end
  end
end
