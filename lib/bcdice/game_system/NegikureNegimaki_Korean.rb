# frozen_string_literal: true

require 'bcdice/game_system/NegikureNegimaki'

module BCDice
  module GameSystem
    class NegikureNegimaki_Korean < NegikureNegimaki
      # ゲームシステムの識別子
      ID = 'NegikureNegimaki:Korean'

      # ゲームシステム名
      NAME = '네지쿠레 네지마키'

      # ゲームシステム名の読みがな
      SORT_KEY = '国際化:Korean:네지쿠레 네지마키'

      # ダイスボットの使い方
      HELP_MESSAGE = <<~INFO_MESSAGE_TEXT
        ■ 행위 판정
        nNNx#y: n개의 D6을 굴려, x 이상의 주사위 결과값의 개수를 성공 레벨로 판정.
        n: 주사위 수（생략 시 1）
        x: 난이도（생략 시 4）
        y: 요구 성공 레벨（생략 시 1, 0은 1로 처리）

        ■ 전투 판정（공격 판정）
        nNAx#y: n개의 D6을 굴려, x 이상을 성공으로 간주. y 이상의 성공은 직격 피해가 된다.
        n: 주사위 수（생략 시 1）
        x: 난이도（생략 시 4）
        y: 크리티컬 값（생략 시 6, 0은 1로 처리）
        일반 피해 = 성공 레벨 - 직격 피해
        직격 피해 = 성공한 눈 중 y 이상의 개수
        거츠 감소 = 주사위 결과값 1의 개수

        ■ 스트라이크 판정
        nNS: n개의 D6을 굴려, 주사위 결과값 1의 개수만큼 거츠 감소를 산출한다
        n: 주사위 수（생략 시 1）
        거츠 감소가 0이면 성공, 1 이상이면 실패
      INFO_MESSAGE_TEXT

      register_prefix_from_super_class()

      def initialize(command)
        super(command)
        @locale = :ko_kr
      end
    end
  end
end
