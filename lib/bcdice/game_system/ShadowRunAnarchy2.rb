# frozen_string_literal: true

module BCDice
  module GameSystem
    class ShadowRunAnarchy2 < Base
      ID = "ShadowRunAnarchy2"
      NAME = "シャドウラン：アナーキー 2.0"
      SORT_KEY = "しやとうらんあなあきい2.0"

      HELP_MESSAGE = <<~TEXT
        ■ 判定 nSRA[r][@q][A|D]
          n: ダイスプール（1以上）。r: そのうちリスクダイスに置き換える個数（0～n）。
          q: リスク軽減（RR、0～3、省略時0）。A: 有利、D: 不利、省略時は通常。
          r省略時はRRに応じて2・5・8・12個（プールの個数まで）。
          通常は5・6、有利は4・5・6、不利は6がヒット。
          通常ダイスは1ヒット、リスクダイスは2ヒットとして集計します。
          リスクダイスの1の個数からRRを引き、残り1個で軽度、2個で重度のコンプリケーション、3個以上で大惨事。
          大惨事は原則として判定失敗です。最終的な結果はGMが判断します。
          例: 8SRA / 8SRA0 / 8SRA3@1 / 8SRA3@1A / 8SRA3@1D
          このコマンドは新規判定用です。Anarchyによる振り直しは最初のコンプリケーションを維持します。
      TEXT

      DEFAULT_RISK_DICE = [2, 5, 8, 12].freeze
      COMPLICATIONS = ["コンプリケーションなし", "軽度のコンプリケーション", "重度のコンプリケーション", "大惨事（原則として判定失敗）"].freeze

      register_prefix('\d+SRA')

      def eval_game_system_specific_command(command)
        # The common preprocessor expands a trailing numeric nD into nD6.
        m = /\A(\d+)SRA(\d+)?(?:@(\d+))?(A|D6?)?\z/.match(command)
        return nil unless m

        pool = m[1].to_i
        rr = m[3].to_i
        return nil if pool < 1 || rr > 3

        risk_count = m[2] ? m[2].to_i : [pool, DEFAULT_RISK_DICE[rr]].min
        return nil if risk_count > pool

        mode = m[4]&.sub("D6", "D")
        threshold = {"A" => 4, "D" => 6}.fetch(mode, 5)
        normal = @randomizer.roll_barabara(pool - risk_count, 6).sort
        risk = @randomizer.roll_barabara(risk_count, 6).sort
        normal_hits = normal.count { |die| die >= threshold }
        risk_hits = risk.count { |die| die >= threshold } * 2
        ones = risk.count(1)
        remaining = [ones - rr, 0].max
        complication = COMPLICATIONS[[remaining, 3].min]

        return "(#{pool}SRA#{risk_count}@#{rr}#{mode}) ＞ 通常[#{normal.join(',')}] リスク[#{risk.join(',')}] ＞ ヒット数#{normal_hits + risk_hits} ＞ リスクの1:#{ones}個 RR:#{rr} 残り:#{remaining}個 ＞ #{complication}"
      end
    end
  end
end
