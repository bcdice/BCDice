# frozen_string_literal: true

require 'bcdice/arithmetic_evaluator'

module BCDice
  module GameSystem
    class Cthulhu < Base
      # ゲームシステムの識別子
      ID = 'Cthulhu'

      # ゲームシステム名
      NAME = 'クトゥルフ神話TRPG'

      # ゲームシステム名の読みがな
      SORT_KEY = 'くとうるふしんわTRPG'

      # ダイスボットの使い方
      HELP_MESSAGE = <<~INFO_MESSAGE_TEXT
        c=クリティカル値 ／ f=ファンブル値 ／ s=スペシャル

        1d100<=n    c・f・sすべてオフ（単純な数値比較判定のみ行います）

        ・cfs判定付き判定コマンド

        CC	 1d100ロールを行う c=1、f=100
        CCB  同上、c=5、f=96

        例：CC<=80  （技能値80で行為判定。1%ルールでcf適用）
        例：CCB<=55 （技能値55で行為判定。5%ルールでcf適用）

        ・組み合わせロールについて

        CBR(x,y)	c=1、f=100
        CBRB(x,y)	c=5、f=96

        ・抵抗表ロールについて
        RES(x-y)	c=1、f=100
        RESB(x-y)	c=5、f=96

        ※故障ナンバー判定

        ・CC(x) c=1、f=100
        x=故障ナンバー。出目x以上が出た上で、ファンブルが同時に発生した場合、共に出力する（テキスト「ファンブル＆故障」）
        ファンブルでない場合、成功・失敗に関わらずテキスト「故障」のみを出力する（成功・失敗を出力せず、上書きしたものを出力する形）

        ・CCB(x) c=5、f=96
        同上

      INFO_MESSAGE_TEXT

      register_prefix(['CC(B)?\(\d+\)', 'CC(B)?.*', 'RES(B)?.*', 'CBR(B)?\(\d+,\d+\)'])

      def initialize(command)
        super(command)
        @special_percentage  = 20
        @critical_percentage = 1
        @fumble_percentage   = 1
      end

      def eval_game_system_specific_command(command)
        case command
        when /CCB/i
          # 5%
          @critical_percentage = 5
          @fumble_percentage   = 5
          return getCheckResult(command)
        when /CC/i
          # 1%
          @critical_percentage = 1
          @fumble_percentage   = 1
          return getCheckResult(command)
        when /RESB/i
          # 5%
          @critical_percentage = 5
          @fumble_percentage   = 5
          return getRegistResult(command)
        when /CBRB/i
          # 5%
          @critical_percentage = 5
          @fumble_percentage   = 5
          return getCombineRoll(command)
        when /RES/i
          # 1%
          @critical_percentage = 1
          @fumble_percentage   = 1
          return getRegistResult(command)
        when /CBR/i
          # 1%
          @critical_percentage = 1
          @fumble_percentage   = 1
          return getCombineRoll(command)
        end

        return nil
      end

      private

      def getCheckResult(command)
        m = %r{CCB?(\d+)?(?:<=([+-/*\d]+))?}i.match(command)
        broken_num = m[1].to_i
        diff = ArithmeticEvaluator.eval(m[2])

        if diff <= 0
          total = @randomizer.roll_once(100)
          return Result.new("(1D100) ＞ #{total}")
        end

        expr = "(1D100<=#{diff})"
        if broken_num > 0
          expr += " #{translate('Cthulhu.broken_number')}[#{broken_num}]"
        end

        total = @randomizer.roll_once(100)
        compare_result = compare(total, diff, broken_num)

        compare_result.to_result.tap do |r|
          r.text = "#{expr} ＞ #{total} ＞ #{compare_result.text}"
        end
      end

      class CompareResult
        include Translate
        attr_accessor :success, :failure, :critical, :fumble, :special, :broken

        def initialize(locale)
          @locale = locale

          @success = false
          @failure = false
          @critical = false
          @fumble = false
          @special = false
          @broke = false
        end

        def text
          if critical && special
            translate("Cthulhu.critical_special")
          elsif critical
            translate("Cthulhu.critical")
          elsif special
            translate("Cthulhu.special")
          elsif success
            translate("success")
          elsif broken && fumble
            "#{translate('Cthulhu.fumble')}/#{translate('Cthulhu.broken')}"
          elsif broken
            translate("Cthulhu.broken")
          elsif fumble
            translate("Cthulhu.fumble")
          elsif failure
            translate("failure")
          end
        end

        def to_result
          Result.new.tap do |r|
            r.success = success
            r.failure = failure
            r.critical = critical
            r.fumble = fumble
          end
        end
      end

      def compare(total, target, broken_number = 0)
        result = CompareResult.new(@locale)
        target_special = (target * @special_percentage / 100).clamp(1, 100)

        if (total <= target) && (total < 100)
          result.success = true
          result.special = total <= target_special
          result.critical = total <= @critical_percentage
        else
          result.failure = true
          result.fumble = total >= (101 - @fumble_percentage)
        end

        if broken_number > 0 && total >= broken_number
          result.broken = true
          result.failure = true
          result.success = false
          result.special = false
          result.critical = false
        end

        return result
      end

      def getRegistResult(command)
        m = /RES(B)?([-\d]+)/i.match(command)
        unless m
          return nil
        end

        value = m[2].to_i
        target = value * 5 + 50

        if target < 5
          return Result.failure("(1d100<=#{target}) ＞ #{translate('Cthulhu.automatic_failure')}")
        end

        if target > 95
          return Result.success("(1d100<=#{target}) ＞ #{translate('Cthulhu.automatic_success')}")
        end

        # 通常判定
        total_n = @randomizer.roll_once(100)
        compare_result = compare(total_n, target)

        compare_result.to_result.tap do |r|
          r.text = "(1d100<=#{target}) ＞ #{total_n} ＞ #{compare_result.text}"
        end
      end

      def getCombineRoll(command)
        m = /CBR(B)?\((\d+),(\d+)\)/i.match(command)
        unless m
          return nil
        end

        diff_1 = m[2].to_i
        diff_2 = m[3].to_i

        total = @randomizer.roll_once(100)

        result_1 = compare(total, diff_1)
        result_2 = compare(total, diff_2)

        rank =
          if result_1.success && result_2.success
            translate("success")
          elsif result_1.success || result_2.success
            translate("Cthulhu.partial_success")
          else
            translate("failure")
          end

        Result.new.tap do |r|
          r.text = "(1d100<=#{diff_1},#{diff_2}) ＞ #{total}[#{result_1.text},#{result_2.text}] ＞ #{rank}"
          r.critical = result_1.critical || result_2.critical
          r.fumble = result_1.fumble || result_2.fumble
          r.condition = result_1.success || result_2.success
        end
      end
    end
  end
end
