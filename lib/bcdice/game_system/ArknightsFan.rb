# frozen_string_literal: true

module BCDice
  module GameSystem
    class ArknightsFan < Base
      # ゲームシステムの識別子
      ID = "ArknightsFan"

      # ゲームシステム名
      NAME = "アークナイツTRPG by daaaper"

      # ゲームシステム名の読みがな
      SORT_KEY = "ああくないつTRPGはいてえはあ"

      HELP_MESSAGE = <<~TEXT
        ■ 能力値判定 (nADm<=x)
          nDmのダイスロールをして、出目が x 以下であれば成功。
          出目が91以上でエラー。
          出目が10以下でクリティカル。

        ■ 攻撃/防御判定 (nABm<=x)
          nBmのダイスロールをして、
            出目が x 以下であれば成功数+1。
            出目が91以上でエラー。成功数-1。
            出目が10以下でクリティカル。成功数+1。
          上記による成功数をカウント。

        ■ 役職効果付き攻撃判定 (nABm<=x--役職名h)
          h: 健康状態(0: 健康、1: 中等症、2: 重症)
          nBmのダイスロールをして、
            出目が x 以下であれば成功数+1。
            出目が91以上でエラー。成功数-1。
            出目が10以下でクリティカル。成功数+1。
          上記による成功数をカウントした上で、以下の役職名による成功数増加効果を適応。
            狙撃（SNI）: 健康(h=0)かつ成功数1以上のとき、成功数+1。
          健康状態hを省略した場合、健康(h=0)として扱われる。

        ■ 鉱石病判定 (ORPx@y+Dd+Tt)
          x: 生理的耐性、y: 上昇後侵食度、d: ダイス補正、t: 判定値補正
          生理的耐性xのOPが侵食度yに上昇した際の鉱石病判定を、ダイス数補正d、判定値補正tで行う。
          ダイス数補正と判定値補正は省略可能。例えば ORP60@25 は ORP60@25+D0+T0 と同義。
          また、ダイス数補正と判定値補正は逆順でも可。例えば ORP60@25+T10+D2 も可。

        ■ 増悪判定（--WORSENING）
          症状を「末梢神経障害」「内臓機能不全」「精神症状」からランダムに選択。
          継続ラウンド数を1d6+1で判定。

        ■ 中毒判定（--ADDICTION）
          症状を「脳神経障害」「多臓器不全」「急性精神反応」からランダムに選択。

        ■ 判定の省略表記
          nADm、nABm、nABmにおいて、
            n（ダイス個数）を省略した場合、1として扱われる。
            m（ダイス種類）を省略した場合、100として扱われる。
          例えば、AD<=90は1AD100<=90として解釈される。
      TEXT

      register_prefix('[-+*/\d]*AD\d*', '[-+*/\d]*AB\d*', 'ORP', '--WORSENING', '--ADDICTION')

      def initialize(command)
        super(command)
        @sort_add_dice = true      # 加算ダイスでダイス目をソートする
        @sort_barabara_dice = true # バラバラダイスでダイス目をソートする
        @sides_implicit_d = 100    # 1D のようにダイスの面数が指定されていない場合に100面ダイスにする
      end

      def eval_game_system_specific_command(command)
        eval_ad(command) || eval_ab(command) || eval_orp(command) || eval_worsening(command) || eval_addiction(command)
      end

      private

      module Status
        CRITICAL = 1
        SUCCESS  = 2
        FAILURE  = 3
        ERROR    = 4
      end

      STATUS_NAME = {
        Status::CRITICAL => 'クリティカル！',
        Status::SUCCESS => '成功',
        Status::FAILURE => '失敗',
        Status::ERROR => 'エラー'
      }.freeze

      # クリティカル、エラー、成功失敗周りの閾値や優先関係が複雑かつルールが変動する可能性があるため、明示的にルール管理するための関数。
      def check_roll(roll_result, target)
        success = roll_result <= target

        crierror =
          if roll_result <= 10
            "Critical"
          elsif roll_result >= 91
            "Error"
          else
            "Neutral"
          end

        result =
          if success && (crierror == "Critical")
            Status::CRITICAL
          elsif success && (crierror == "Neutral")
            Status::SUCCESS
          elsif success && (crierror == "Error")
            Status::SUCCESS
          elsif !success && (crierror == "Critical")
            Status::FAILURE
          elsif !success && (crierror == "Neutral")
            Status::FAILURE
          elsif !success && (crierror == "Error")
            Status::ERROR
          end

        return result
      end

      def eval_ad(command)
        # -は文字クラスの先頭または最後に置く。
        # そうしないと範囲指定子として解釈される。
        m = %r{^([-+*/\d]*)AD(\d*)<=([-+*/\d]+)$}.match(command)
        return nil unless m

        times = m[1]
        sides = m[2]
        target = Arithmetic.eval(m[3], @round_type)
        times = !times.empty? ? Arithmetic.eval(m[1], @round_type) : 1
        sides = !sides.empty? ? sides.to_i : 100

        roll_ad(command, times, sides, target)
      end

      def eval_ab(command)
        m = %r{^([-+*/\d]*)AB(\d*)<=([-+*/\d]+)(?:--([^\d\s]+)([0-2])?)?$}.match(command)
        return nil unless m

        times = m[1]
        sides = m[2]
        target = Arithmetic.eval(m[3], @round_type)
        type = m[4]
        type_status = m[5]
        times = !times.empty? ? Arithmetic.eval(m[1], @round_type) : 1
        sides = !sides.empty? ? sides.to_i : 100
        if !type_status.nil?
          type_status = type_status.to_i
        elsif type == "SNIPER" # スプレッドシート版キャラシの後方互換性のために必要
          type_status = 1
        else
          type_status = 0
        end

        if type.nil?
          roll_ab(command, times, sides, target)
        else
          roll_ab_withtype(command, times, sides, target, type, type_status)
        end
      end

      def eval_orp(command)
        m   = %r{^ORP(?'END'[-+*/\d]+)@(?'ORP'[-+*/\d]+)(?:\+D(?'DICE'[-+*/\d]+))?(?:\+T(?'TGT'[-+*/\d]+))?$}.match(command)
        # D補正とT補正が逆順でも対応する
        m ||= %r{^ORP(?'END'[-+*/\d]+)@(?'ORP'[-+*/\d]+)(?:\+T(?'TGT'[-+*/\d]+))?(?:\+D(?'DICE'[-+*/\d]+))?$}.match(command)
        return nil unless m

        endurance = Arithmetic.eval(m[:END], @round_type)
        oripathy = Arithmetic.eval(m[:ORP], @round_type)
        times_mod = !m[3].nil? ? Arithmetic.eval(m[:DICE], @round_type) : 0
        target_mod = !m[4].nil? ? Arithmetic.eval(m[:TGT], @round_type) : 0

        roll_orp(command, endurance, oripathy, times_mod, target_mod)
      end

      def roll_ad(command, times, sides, target)
        dice_list = @randomizer.roll_barabara(times, sides).sort
        total = dice_list.sum

        result = check_roll(total, target)

        if times == 1
          result_text = "(#{command}) ＞ #{dice_list.join(',')} ＞ #{STATUS_NAME[result]}"
        else
          result_text = "(#{command}) ＞ #{total}[#{dice_list.join(',')}] ＞ #{STATUS_NAME[result]}"
        end
        case result
        when Status::CRITICAL
          Result.critical(result_text)
        when Status::SUCCESS
          Result.success(result_text)
        when Status::FAILURE
          Result.failure(result_text)
        when Status::ERROR
          Result.fumble(result_text)
        end
      end

      def roll_ab(command, times, sides, target)
        dice_list = @randomizer.roll_barabara(times, sides).sort

        success_count, critical_count, error_count = process_ab(dice_list, target)
        result_count = success_count + critical_count - error_count

        result_text = "(#{command}) ＞ [#{dice_list.join(',')}] ＞ #{success_count}+#{critical_count}C-#{error_count}E ＞ 成功数#{result_count}"
        Result.new.tap do |r|
          r.text = result_text
          r.condition = result_count > 0
          r.critical = critical_count > 0
          r.fumble = error_count > 0
        end
      end

      def roll_ab_withtype(command, times, sides, target, type, type_status)
        dice_list = @randomizer.roll_barabara(times, sides).sort

        success_count, critical_count, error_count = process_ab(dice_list, target)
        result_count = success_count + critical_count - error_count

        case type
        when "SNI"
          if (type_status == 0) && (result_count > 0)
            result_mod = 1
          else
            result_mod = 0
          end
        when "SNIPER" # スプレッドシート版キャラシの後方互換性のため残している
          if (type_status != 0) && (result_count > 0)
            result_mod = 1
          else
            result_mod = 0
          end
        end

        if !result_mod.nil?
          result_count += result_mod
          result_text = "(#{command}) ＞ [#{dice_list.join(',')}] ＞ #{success_count}+#{critical_count}C-#{error_count}E+#{result_mod}(#{type}) ＞ 成功数#{result_count}"
        else
          result_text = "(#{command}) ＞ [#{dice_list.join(',')}] ＞ #{success_count}+#{critical_count}C-#{error_count}E ＞ 成功数#{result_count}"
        end
        Result.new.tap do |r|
          r.text = result_text
          r.condition = result_count > 0
          r.critical = critical_count > 0
          r.fumble = error_count > 0
        end
      end

      ENDURANCE_LEVEL_TABLE = [20, 40, 70, 90, Float::INFINITY].freeze # 生理的耐性の実数値から能力評価への変換テーブル
      ORP_TIMES_TABLE = [1, 2, 2, 3, 4].freeze                         # 生理的耐性の能力評価ごとのダイス数基本値
      def roll_orp(command, endurance, oripathy, times_mod, target_mod)
        sides = 100

        endurance_level = ENDURANCE_LEVEL_TABLE.find_index { |n| endurance <= n }
        original_times = ORP_TIMES_TABLE[endurance_level]
        times = original_times + times_mod

        if oripathy <= 20
          return Result.new("(#{command}) ＞ 鉱石病判定が発生しない侵食度です。侵食度は21以上を指定してください。")
        end

        oripathy_stage = (oripathy / 20.0).ceil - 1
        original_target = (80 - oripathy_stage * 20) - (oripathy - oripathy_stage * 20) * 5
        target = original_target + target_mod
        dice_and_target_text = "ダイス数#{original_times}" +
                               (times_mod > 0 ? "+#{times_mod}" : "") +
                               "、判定値#{original_target}" +
                               (target_mod > 0 ? "+#{target_mod}" : "")
        result_texts = ["(#{command})", dice_and_target_text, "#{times}B100<=#{target}"]

        if target <= 0
          result_texts += ["自動失敗！"]
          return Result.failure(result_texts.join(" ＞ "))
        end

        # 複数振ったダイスのうち1つでも判定値を下回れば成功なので、最も出目の小さいダイスのみを確認すればよい。
        # dice_listをソートした上で、dice_list[0]が最小の出目。
        dice_list = @randomizer.roll_barabara(times, sides).sort
        success_count = dice_list.count { |n| n <= target }
        if success_count > 0
          result_texts += ["[#{dice_list.join(',')}]", "成功数#{success_count}", "成功"]
          Result.success(result_texts.join(" ＞ "))
        else
          result_texts += ["[#{dice_list.join(',')}]", "成功数#{success_count}", "失敗"]
          Result.failure(result_texts.join(" ＞ "))
        end
      end

      def process_ab(dice_list, target)
        success_count = 0
        critical_count = 0
        error_count = 0

        dice_list.each do |value|
          case check_roll(value, target)
          when Status::CRITICAL
            critical_count += 1
            success_count += 1
          when Status::SUCCESS
            success_count += 1
          when Status::FAILURE
            # Nothing to do
          when Status::ERROR
            error_count += 1
          end
        end

        return [success_count, critical_count, error_count]
      end

      WORSENING_TABLE = [
        "末梢神経障害",
        "内臓機能不全",
        "精神症状",
      ].freeze

      def eval_worsening(command)
        return nil if command != "--WORSENING"

        value = @randomizer.roll_once(3)
        chosen = WORSENING_TABLE[value - 1]
        elapse = @randomizer.roll_once(6) + 1

        return "--WORSENING ＞ #{chosen}: #{elapse} rounds"
      end

      ADDICTION_TABLE = [
        "脳神経障害",
        "多臓器不全",
        "急性精神症状",
      ].freeze

      def eval_addiction(command)
        return nil if command != "--ADDICTION"

        value = @randomizer.roll_once(3)
        chosen = ADDICTION_TABLE[value - 1]

        return "--ADDICTION ＞ #{chosen}"
      end
    end
  end
end
