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
          x が91以上でエラー。
          x が10以下でクリティカル。

        ■ 判定 (nABm>=x)
          nBmのダイスロールをして、
            x 以下であれば成功数+1。
            x が91以上でエラー。成功数+1。
            x が10以下でクリティカル。成功数-1。
          上記による成功数をカウント。

        ■ 判定 (nBm>=x--役職)
          nBmのダイスロールをして、
            x 以下であれば成功数+1。
            x が91以上でエラー。成功数+1。
            x が10以下でクリティカル。成功数-1。
          上記による成功数をカウントした上で、以下の役職による成功数増加効果を適応。
            狙撃 成功数1以上のとき、成功数+1。
      TEXT

      TABLES = {
        "--WORSENING" => {
          name: "worsening",
          dice: "1d3",
          contents: [
            "末梢神経障害",
            "内臓機能不全",
            "精神症状",
          ]
        },
        "--ADDICTION" => {
          name: "addiction",
          dice: "1d3",
          contents: [
            "中枢神経障害",
            "多臓器不全",
            "急性ストレス反応",
          ]
        },
      }.freeze

      register_prefix('\d*AD\d*<=\d+',
                      '\d*AB\d*<=\d+',
                      '\d*AB\d*<=\d+--[^\d\s]+',
                      TABLES.keys)

      def eval_game_system_specific_command(command)
        case command
        when /^(\d*)AD(\d*)<=(\d+)$/                        # AD<=70, 2AD100<=70
          times = ::Regexp.last_match(1)
          sides = ::Regexp.last_match(2)
          target = ::Regexp.last_match(3).to_i
          times = !times.empty? ? times.to_i : 1
          sides = !sides.empty? ? sides.to_i : 100
          return roll_d(command, times, sides, target)

        when /^(\d*)AB(\d*)<=(\d+)$/                        # 2AB<=70, 2AB100<=70
          times = ::Regexp.last_match(1)
          sides = ::Regexp.last_match(2)
          target = ::Regexp.last_match(3).to_i
          times = !times.empty? ? times.to_i : 1
          sides = !sides.empty? ? sides.to_i : 100
          return roll_b(command, times, sides, target)

        when /^(\d*)AB(\d*)<=(\d+)--([^\d\s]+)$/             # 2AB<=70--SNIPER, 2AB100<=70--SNIPER
          times = ::Regexp.last_match(1)
          sides = ::Regexp.last_match(2)
          target = ::Regexp.last_match(3).to_i
          type = ::Regexp.last_match(4)
          times = !times.empty? ? times.to_i : 1
          sides = !sides.empty? ? sides.to_i : 100
          return roll_b_withtype(command, times, sides, target, type)

        when /^(\d*)AB(\d*)<=(\d+)--([^\d\s]+)0$/            # 2AB<=70--SNIPER0, 2AB100<=70--SNIPER0
          times = ::Regexp.last_match(1)
          sides = ::Regexp.last_match(2)
          target = ::Regexp.last_match(3).to_i
          times = !times.empty? ? times.to_i : 1
          sides = !sides.empty? ? sides.to_i : 100
          return roll_b(command, times, sides, target)

        when /^--ADDICTION$/                                  # --ADDICTION
          return roll_addiction(command, TABLES)
        when /^--WORSENING$/                                  # --WORSENING
          return roll_worsening(command, TABLES)
        end

        return nil
      end

      private

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
        (1..target).each do |num|
          success_count += dice_list.count(num)
        end

        critical_count = 0
        (1..10).each do |num|
          critical_count += dice_list.count(num)
        end

        error_count = 0
        (91..100).each do |num|
          error_count += dice_list.count(num)
        end

        return [dice_list, success_count, critical_count, error_count]
      end

      ### ダイステーブル（ユーザー定義配列）の処理

      def roll_addiction(command, tables)
        syndrome = roll_ark_tables(command, tables, @randomizer)
        return nil unless syndrome

        return syndrome
      end

      def roll_worsening(command, tables)
        randomizer = @randomizer
        addiction = roll_ark_tables(command, tables, randomizer)
        return nil unless addiction

        elapse = randomizer.roll_barabara(1, 6)[0] + 1

        return "#{addiction}: #{elapse} rounds"
      end

      # 事情により自作。roll_worsening()で症状の内容と期間をそれぞれ決定する際、同一のrandmizerを受け渡して使う必要がある模様。
      # このとき、roll_addictionと処理が重複する症状決定処理について、randmizerを引数指定可能な形で以下に実装する形となった。
      def roll_ark_tables(command, tables, randomizer)
        table = tables[command]
        return nil unless table

        contents = table[:contents]
        m = /^(\d+)d(\d+)$/.match(table[:dice])
        dice_result = randomizer.roll_barabara(m[1].to_i, m[2].to_i)[0]
        return contents[dice_result - 1]
      end
    end
  end
end
