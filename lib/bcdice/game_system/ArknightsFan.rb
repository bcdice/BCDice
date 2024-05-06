# frozen_string_literal: true

module BCDice
  module GameSystem
    class ArknightsFan < Base
      # ゲームシステムの識別子
      ID = "ArknightsFan"

      # ゲームシステム名
      NAME = "アークナイツTRPG by Dapto"

      # ゲームシステム名の読みがな
      SORT_KEY = "ああくないつTRPGはいたふと"

      HELP_MESSAGE = <<~TEXT
        ■ 判定 (nADm>=x)
          nDmのダイスロールをして、x 以下であれば成功。
          出目が91以上でエラー。
          出目が10以下でクリティカル。

        ■ 判定 (nABm>=x)
          nBmのダイスロールをして、
            x 以下であれば成功数+1。
            出目が91以上でエラー。成功数+1。
            出目が10以下でクリティカル。成功数-1。
          上記による成功数をカウント。

        ■ 判定 (nABm>=x--役職)
          nBmのダイスロールをして、
            出目が x 以下であれば成功数+1。
            出目が91以上でエラー。成功数+1。
            出目が10以下でクリティカル。成功数-1。
          上記による成功数をカウントした上で、以下の役職による成功数増加効果を適応。
            狙撃（SNIPER） 成功数1以上のとき、成功数+1。
      TEXT

      register_prefix('\d*AD\d*', '\d*AB\d*', '--ADDICTION', '--WORSENING')

      def eval_game_system_specific_command(command)
        roll_ad(command) || roll_ab(command) || roll_addiction(command) || roll_worsening(command)
      end

      private

      def roll_ad(command)
        m = /^(\d*)AD(\d*)<=(\d+)$/.match(command)
        return nil unless m

        times = m[1]
        sides = m[2]
        target = m[3].to_i
        times = !times.empty? ? times.to_i : 1
        sides = !sides.empty? ? sides.to_i : 100
        return roll_d(command, times, sides, target)
      end

      def roll_ab(command)
        m = /^(\d*)AB(\d*)<=(\d+)(?:--([^\d\s]+)(0)?)?$/.match(command)
        return nil unless m

        times = m[1]
        sides = m[2]
        target = m[3].to_i
        type = m[4]
        suffix = m[5]
        times = !times.empty? ? times.to_i : 1
        sides = !sides.empty? ? sides.to_i : 100

        if suffix || type.nil?
          roll_b(command, times, sides, target)
        else
          roll_b_withtype(command, times, sides, target, type)
        end
      end

      def roll_d(command, times, sides, target)
        dice_list = @randomizer.roll_barabara(times, sides).sort
        total = dice_list.sum
        success = total <= target

        crierror =
          if total <= 10
            "Critical"
          elsif total >= 91
            "Error"
          else
            "Neutral"
          end

        result =
          if success && (crierror == "Critical")
            "クリティカル！"
          elsif success && (crierror == "Neutral")
            "成功"
          elsif success && (crierror == "Error")
            "成功"
          elsif !success && (crierror == "Critical")
            "失敗"
          elsif !success && (crierror == "Neutral")
            "失敗"
          elsif !success && (crierror == "Error")
            "エラー"
          end

        if times == 1
          return "(#{command}) ＞ #{dice_list.join(',')} ＞ #{result}"
        else
          return "(#{command}) ＞ #{total}[#{dice_list.join(',')}] ＞ #{result}"
        end
      end

      def roll_b(command, times, sides, target)
        dice_list, success_count, critical_count, error_count = process_b(times, sides, target)
        result_count = success_count + critical_count - error_count

        return "(#{command}) ＞ [#{dice_list.join(',')}] ＞ #{success_count}+#{critical_count}C-#{error_count}E ＞ 成功数#{result_count}"
      end

      def roll_b_withtype(command, times, sides, target, type)
        dice_list, success_count, critical_count, error_count = process_b(times, sides, target)
        result_count = success_count + critical_count - error_count

        type_effect =
          if (type == "SNIPER") && (result_count > 0)
            1
          else
            0
          end
        result_count += type_effect

        return "(#{command}) ＞ [#{dice_list.join(',')}] ＞ #{success_count}+#{critical_count}C-#{error_count}E+#{type_effect}(#{type}) ＞ 成功数#{result_count}"
      end

      def process_b(times, sides, target)
        dice_list = @randomizer.roll_barabara(times, sides).sort

        success_count = 0
        critical_count = 0
        error_count = 0

        dice_list.each do |value|
          success_count += 1 if value <= target
          critical_count += 1 if value <= 10
          error_count += 1 if value >= 91
        end

        return [dice_list, success_count, critical_count, error_count]
      end

      ADDICTION_TABLE = [
        "中枢神経障害",
        "多臓器不全",
        "急性ストレス反応",
      ].freeze

      def roll_addiction(command)
        return nil if command != "--ADDICTION"

        value = @randomizer.roll_once(3)
        chosen = ADDICTION_TABLE[value - 1]

        return "--ADDICTION ＞ #{chosen}"
      end

      WORSENING_TABLE = [
        "末梢神経障害",
        "内臓機能不全",
        "精神症状",
      ].freeze

      def roll_worsening(command)
        return nil if command != "--WORSENING"

        value = @randomizer.roll_once(3)
        chosen = WORSENING_TABLE[value - 1]
        elapse = @randomizer.roll_once(6) + 1

        return "--WORSENING ＞ #{chosen}: #{elapse} rounds"
      end
    end
  end
end
