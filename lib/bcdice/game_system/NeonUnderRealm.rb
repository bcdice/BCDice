# frozen_string_literal: true

module BCDice
  module GameSystem
    class NeonUnderRealm < Base
      ID = "NeonUnderRealm"
      NAME = "光都暗域〈ネオン・アンダーレルム〉"
      SORT_KEY = "ねおんあんたあれるむ"

      HELP_MESSAGE = <<~TEXT
        ・判定（D10の出目が「目標値以下」を成功として数える）
          [M]NU[N][±K][@L][±K']

          M：判定ダイス数（省略不可）。「10+5+3-2」のような加減算を許可
          N：目標値（1～10）。省略時は 5
          K, K'：達成値への補正。両方指定された場合はKを採用し、K'は無視される。（省略可）
          L：気合の閾値（0～5）。省略時は 0（気合は常に0扱い）

          ※Nが1～10の範囲外、またはLが0～5の範囲外の場合はコマンドとして処理しません（出力しません）
          ※達成値 = max(0, 素の成功数 + K)
          ※効果値 = ダイス数 - 素の成功数
          ※素の成功数が0なら判定は失敗（達成値が補正で1以上でも失敗扱い）
          ※成功は表示しません。素の成功数0または達成値0のときのみ「失敗」を表示します。

        例）
          4NU
          4NU7+2
          10+5+3-2NU5-1@2
      TEXT

      DEFAULT_THRESHOLD = 5
      MIN_THRESHOLD = 1
      MAX_THRESHOLD = 10
      DEFAULT_KIAI_THRESHOLD = 0
      MIN_KIAI_THRESHOLD = 0
      MAX_KIAI_THRESHOLD = 5

      register_prefix('\d+([+\-]\d+)*NU')

      # [M]NU[N]±[K]@[L]
      def eval_game_system_specific_command(command)
        m_expr, n_str, k_str, l_str = parse_command(command)
        return nil unless m_expr

        dice_count = eval_dice_count(m_expr)
        return nil unless dice_count && dice_count >= 1

        threshold = n_str&.to_i || DEFAULT_THRESHOLD
        return nil unless (MIN_THRESHOLD..MAX_THRESHOLD).cover?(threshold)

        modifier = (k_str ? k_str.to_i : 0)

        kiai_threshold = (l_str ? l_str.to_i : DEFAULT_KIAI_THRESHOLD)
        return nil unless (MIN_KIAI_THRESHOLD..MAX_KIAI_THRESHOLD).cover?(kiai_threshold)

        dice_list = @randomizer.roll_barabara(dice_count, 10).sort

        raw_success = dice_list.count { |x| x <= threshold }
        achieved = raw_success + modifier
        achieved = 0 if achieved < 0

        effect = dice_count - raw_success
        kiai = kiai_threshold > 0 ? dice_list.count { |x| x <= kiai_threshold } : 0

        expr_text = build_expr_text(dice_count, threshold,  modifier, kiai_threshold, dice_list)

        result_text_parts = [
          "達成値：#{achieved}（成功数：#{raw_success}）",
          "効果値：#{effect}",
          "気合：#{kiai}",
        ]

        # 素成功0なら失敗。または達成値0なら失敗。成功表示は不要。失敗表示はこのケースのみ。
        result_text_parts << "失敗" if raw_success == 0 || achieved == 0

        text = [
          "(#{command.upcase})",
          expr_text,
          result_text_parts.join(" / "),
        ].join(" ＞ ")

        result = Result.new(text)

        # 成功条件：達成値>=1 かつ 素成功>=1
        is_success = (achieved >= 1) && (raw_success >= 1)
        result.success = is_success
        result.failure = !is_success

        result
      end

      private

      # returns [m_expr, n_str, k_str, l_str] or [nil,...]
      def parse_command(command)
        # M は「加減算のみ」の式を許可（例：10+5+3-2）
        # N は省略可、K は ±整数、L は @整数、K' は ±整数
        m = /\A(?<m_expr>\d+(?:[+-]\d+)*)NU(?<n>\d+)?(?<k>[+-]\d+)?(?:@(?<l>\d+))?(?<j>[+-]\d+)?\z/.match(command)
        return [nil, nil, nil, nil] unless m

        # 修正値が K を優先
        k = m[:k] || m[:j]

        [m[:m_expr], m[:n], k, m[:l]]
      end

      def eval_dice_count(source)
        # Arithmetic.eval は失敗時 nil を返す
        v = BCDice::Arithmetic.eval(source, @round_type)
        return nil unless v

        # 加減算のみの想定だが、念のため整数以外は弾く
        i = v.to_i
        return nil unless v == i

        i
      rescue StandardError
        nil
      end

      def build_expr_text(dice_count, n, k, l, dice_list)
        # 「MB10」表記に寄せる：xB10<=n±k@l[...]
        k_text = Format.modifier(k)
        l_text = l > 0 ? "@#{l}" : ""
        "#{dice_count}B10<=#{n}#{k_text}#{l_text}[#{dice_list.join(',')}]"
      end
    end
  end
end
