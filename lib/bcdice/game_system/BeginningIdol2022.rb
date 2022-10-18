# frozen_string_literal: true

module BCDice
  module GameSystem
    class BeginningIdol2022 < Base
      # ゲームシステムの識別子
      ID = 'BeginningIdol2022'

      # ゲームシステム名
      NAME = 'ビギニングアイドル（2022年改訂版）'

      # ゲームシステム名の読みがな
      SORT_KEY = 'ひきにんくあいとる2022'

      # ダイスボットの使い方
      HELP_MESSAGE = <<~INFO_MESSAGE_TEXT
        これは、2022年に大判サイズで発売された『駆け出しアイドルRPG ビギニングアイドル 基本ルールブック』に対応したコマンドです。

        ・行為判定　BIn@c#f+m>=t
        　nD6をダイスロールし、行為判定に成功したかを出力します。スペシャルとファンブルの判定も行います。
        　　n: ダイス数（省略時 2)
        　　c: スペシャル値（省略時 12)
        　　f: ファンブル値（省略時 2)
        　　m: 修正値（省略可)
        　　t: 目標値

        ・パフォーマンス判定　PDn+m
        　nD6をダイスロールし、パフォーマンス値を出力します。パーフェクトミラクルとミラクルの判定も行います。
        　　n: ダイス数
        　　m: 修正値（省略可)

        ・シンフォニー　xxxPDn+m
        　nD6をダイスロールし、場に残っているダイスを加味してパフォーマンス値を出力します。
        　パーフェクトミラクルとミラクルシンクロの判定も行います。
        　　xxx: 場に残っているダイスの出目を列挙したもの
        　　n: ダイス数
        　　m: 修正値（省略可)
      INFO_MESSAGE_TEXT

      def initialize(command)
        super(command)

        @sort_add_dice = true
        @d66_sort_type = D66SortType::ASC
      end

      register_prefix("BI", "PD", "[1-6]+PD")

      def eval_game_system_specific_command(command)
        roll_skill_check(command) || roll_performance_check(command) || roll_symphony_check(command)
      end

      private

      # 行為判定
      def roll_skill_check(command)
        parser = Command::Parser.new("BI", round_type: @round_type)
                                .enable_suffix_number
                                .enable_critical
                                .enable_fumble
                                .restrict_cmp_op_to(:>=)
        parsed = parser.parse(command)
        unless parsed
          return nil
        end

        dice_times = parsed.suffix_number || 2
        critical = parsed.critical || 12
        fumble = parsed.fumble || 2

        dice_list = @randomizer.roll_barabara(dice_times, 6).sort()
        dice_total = dice_list.sum()
        is_critical = dice_total >= critical
        is_fumble = !is_critical && dice_total <= fumble
        total = dice_total + parsed.modify_number

        result =
          if is_critical
            Result.critical("スペシャル(PCは【思い出】を1つ獲得する)")
          elsif is_fumble
            Result.fumble("ファンブル(【思い出】を1つ獲得し、ファンブル表を振る)")
          elsif total >= parsed.target_number
            Result.success("成功")
          else
            Result.failure("失敗")
          end

        result.text = "(#{parsed}) ＞ #{dice_total}[#{dice_list.join(',')}]#{Format.modifier(parsed.modify_number)} ＞ #{total} ＞ #{result.text}"
        return result
      end

      # パフォーマンス判定
      def roll_performance_check(command)
        m = /^PD(\d+)([+\-]\d+)?$/.match(command)
        unless m
          return nil
        end

        suffix_number = m[1].to_i
        modifier = m[2].to_i
        is_extension = suffix_number >= 7
        dice_times = is_extension ? 6 : suffix_number
        extension_bonus = is_extension ? suffix_number - dice_times : 0

        if dice_times <= 0
          return nil
        end

        dice_list = @randomizer.roll_barabara(dice_times, 6).sort()
        uniqed = select_uniqs(dice_list).sort()

        is_perfect_miracle = uniqed == [1, 2, 3, 4, 5, 6]
        is_miracle = uniqed.empty?
        result_label =
          if is_perfect_miracle
            "【パーフェクトミラクル】#{30 + extension_bonus + modifier}"
          elsif is_miracle
            "【ミラクル】#{10 + extension_bonus + modifier}"
          else
            (uniqed.sum() + extension_bonus + modifier).to_s
          end
        if is_extension
          result_label += " (エクステンション: #{extension_bonus}個まで振りなおし可能)"
        end

        Result.new.tap do |result|
          result.critical = is_perfect_miracle || is_miracle
          result.text = [
            "(#{command})",
            "パフォーマンス判定",
            "[#{dice_list.join(',')}]#{Format.modifier(extension_bonus)}#{Format.modifier(modifier)}",
            ("[#{uniqed.join(',')}]#{Format.modifier(extension_bonus)}#{Format.modifier(modifier)}" if dice_list.size != uniqed.size),
            result_label,
          ].compact.join(" ＞ ")
        end
      end

      def select_uniqs(array)
        # TODO: Ruby 2.7以降のみサポートするようになった場合に Enumerable#tally で書く
        array.group_by(&:itself)
             .to_a
             .select { |_, arr| arr.size == 1 }
             .map { |key, _| key }
      end

      # シンフォニー
      def roll_symphony_check(command)
        m = /^([1-6]+)PD([1-6])([+\-]\d+)?$/.match(command)
        unless m
          return nil
        end

        carries = m[1].chars.map(&:to_i).sort()
        dice_times = m[2].to_i
        modifier = m[3].to_i

        dice_list = @randomizer.roll_barabara(dice_times, 6).sort()
        uniqed = select_uniqs(carries + dice_list).sort()

        is_perfect_miracle = uniqed == [1, 2, 3, 4, 5, 6]
        is_miracle_synchro = uniqed.empty?
        result_label =
          if is_perfect_miracle
            "【パーフェクトミラクル】#{30 + modifier}"
          elsif is_miracle_synchro
            "【ミラクルシンクロ】#{20 + modifier}"
          else
            (uniqed.sum() + modifier).to_s
          end

        Result.new.tap do |result|
          result.critical = is_perfect_miracle || is_miracle_synchro
          result.text = [
            "(#{command})",
            "シンフォニー",
            "[#{carries.join(',')}],[#{dice_list.join(',')}]#{Format.modifier(modifier)}",
            "[#{uniqed.join(',')}]#{Format.modifier(modifier)}",
            result_label,
          ].join(" ＞ ")
        end
      end
    end
  end
end
