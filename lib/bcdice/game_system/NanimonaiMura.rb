# frozen_string_literal: true

module BCDice
  module GameSystem
    class NanimonaiMura < Base
      # ゲームシステムの識別子
      ID = "NanimonaiMura"

      # ゲームシステム名
      NAME = "なにもない村"

      # ゲームシステム名の読みがな
      SORT_KEY = "なにもないむら"

      # ダイスボットの使い方
      HELP_MESSAGE = <<~INFO_MESSAGE_TEXT
        ・行為判定 xNMy
        　x個のD10を振り、2つの出目から達成値を作成して判定します。
        　達成値は成功度が最も高くなる組み合わせを自動選択し、同値なら低い値を優先します。
        　x: ダイス数（1以上）
        　y: 判定値（0以上）
        　例）4NM55 6NM199 2NM35
      INFO_MESSAGE_TEXT

      register_prefix('\d+NM\d+')

      ResultData = Struct.new(:score, :success, :critical, :result_text, :success_level)

      STAGE_NAMES = %w[ノーマル エピック レジェンダリ ミシック].freeze
      BASE_SUCCESS_LEVELS = [1, 11, 21, 31].freeze

      def eval_game_system_specific_command(command)
        roll_action(command)
      end

      private

      def roll_action(command)
        m = /\A(\d+)NM(\d+)\z/.match(command)
        return nil unless m

        dice_count = m[1].to_i
        target = m[2].to_i
        return nil if dice_count < 1

        dice_list = @randomizer.roll_barabara(dice_count, 10).map { |value| normalize_d10(value) }
        result = select_best_result(dice_list, target)

        Result.new.tap do |r|
          r.text = "#{command} (#{dice_count}D10) ＞ [#{dice_list.join(',')}] ＞ #{result.score} ＞ #{result.result_text} ＞ 成功度#{result.success_level}"
          r.condition = result.success
          r.critical = result.critical
        end
      end

      def normalize_d10(value)
        value == 10 ? 0 : value
      end

      def select_best_result(dice_list, target)
        candidates =
          if dice_list.size == 1
            [build_result(dice_list.first * 10, target)]
          else
            [].tap do |results|
              dice_list.each_index do |i|
                dice_list.each_index do |j|
                  next if i == j

                  results << build_result(dice_list[i] * 10 + dice_list[j], target)
                end
              end
            end
          end

        best_result = candidates.first

        candidates.drop(1).each do |candidate|
          next if candidate.success_level < best_result.success_level
          next if candidate.success_level == best_result.success_level && candidate.score > best_result.score

          best_result = candidate
        end

        best_result
      end

      def build_result(score, target)
        if score > target
          return ResultData.new(score, false, false, "失敗", 0)
        end

        diff = target - score
        stage_index = [diff.div(100), STAGE_NAMES.size - 1].min
        critical_bonus = zoro_bonus(score)
        critical = !critical_bonus.nil?
        success_level = BASE_SUCCESS_LEVELS[stage_index] + (critical_bonus || 0)
        result_text = "#{STAGE_NAMES[stage_index]}#{critical ? '大成功' : '成功'}"

        ResultData.new(score, true, critical, result_text, success_level)
      end

      def zoro_bonus(score)
        tens = score.div(10)
        ones = score % 10
        return nil unless tens == ones

        ones
      end
    end
  end
end
