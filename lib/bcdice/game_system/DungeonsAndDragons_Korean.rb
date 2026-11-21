# frozen_string_literal: true

require 'bcdice/game_system/DungeonsAndDragons'

module BCDice
  module GameSystem
    class DungeonsAndDragons_Korean < DungeonsAndDragons
      # ゲームシステムの識別子
      ID = 'DungeonsAndDragons:Korean'

      # ゲームシステム名
      NAME = '던전 앤 드래곤'

      # ゲームシステム名の読みがな
      SORT_KEY = '国際化:Korean:던전 앤 드래곤'

      # ダイスボットの使い方
      HELP_MESSAGE = "※ 이 다이스봇은 방의 시스템 이름 표시용입니다.\n"

      # 성공 결과 문자열
      def success_text
        "성공"
      end

      # 실패 결과 문자열
      def failure_text
        "실패"
      end

      # 크리티컬 결과 문자열
      def critical_text
        "크리티컬"
      end

      # 펌블 결과 문자열
      def fumble_text
        "펌블"
      end

      # Base.check_result(total, rand_results, cmp_op, target)를 오버라이드
      def check_result(total, rand_results, cmp_op, target)
        # target이 '?' 같은 문자열일 경우 nil 반환
        return nil if target.is_a?(String)

        # 크리티컬/펌블 처리 (D&D 룰: 1 = 펌블, 20 = 크리티컬)
        dice_total = rand_results.map(&:value).sum
        if rand_results.map(&:sides) == [20]
          return Result.critical(critical_text) if dice_total == 20
          return Result.fumble(fumble_text) if dice_total == 1
        end

        # 일반 성공/실패 판정
        if total.send(cmp_op, target)
          Result.success(success_text)
        else
          Result.failure(failure_text)
        end
      end
    end
  end
end
