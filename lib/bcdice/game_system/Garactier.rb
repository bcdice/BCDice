# frozen_string_literal: true

module BCDice
  module GameSystem
    class Garactier < Base
      # ゲームシステムの識別子
      ID = "Garactier"

      # ゲームシステム名
      NAME = "ガラクティア"

      # ゲームシステム名の読みがな
      SORT_KEY = "からくていあ"

      HELP_MESSAGE = <<~TEXT
        x：基準値
        y：目標値

        GRx>=y 　通常の判定を行う
        GRHx>=y　命中判定を行う
        GRDx>=y　回避判定を行う
        GRMx>=y　抵抗判定を行う
        GRSx   　探索・索敵判定時の最大成功MLを算出する

        x, yについては四則演算の入力が可能

      TEXT

      register_prefix('^GR[HDMS]?')

      def eval_game_system_specific_command(command)
        case command
        when /^GRS/
          roll_search(command)
        when /^GR[HDM]/
          roll_target(command)
        when /^GR/
          roll_gr(command)
        end
      end

      # 探索・索敵判定
      def roll_search(command)
        m = %r{^GRS([+-/*\d]+)?$}.match(command)
        unless m
          return nil
        end

        modifier = ArithmeticEvaluator.eval(m[1])

        dice_result = roll_dice_with_modifier(modifier)
        r = determine_no_target_result("S", dice_result[:total], dice_result[:critical], dice_result[:fumble])

        r.text = "(#{m[0]}) ＞ #{dice_result[:dice_sum]}[#{dice_result[:dice_list].join(',')}]#{m[1]} ＞ #{dice_result[:total]} ＞ #{r.text}"
        return r
      end

      # 目標値を持つ判定ロール
      def roll_target(command)
        m = %r{^GR([HDM])([+-/*\d]+)?(?:>=?([+-/*\d]+)+)$}.match(command)
        unless m
          return nil
        end

        roll_type = m[1].to_str
        modifier = ArithmeticEvaluator.eval(m[2])
        target = ArithmeticEvaluator.eval(m[3])

        dice_result = roll_dice_with_modifier(modifier)
        r = determine_target_result(roll_type, dice_result[:total], target, dice_result[:critical], dice_result[:fumble])

        r.text = "(#{m[0]}) ＞ #{dice_result[:dice_sum]}[#{dice_result[:dice_list].join(',')}]#{m[2]} ＞ #{dice_result[:total]} ＞ #{r.text}"
        return r
      end

      # GRのみの基本判定
      def roll_gr(command)
        m = %r{^GR([+-/*\d]+)?(>=)?\(?([+-/*\d]+)?\)?$}.match(command)
        unless m
          return nil
        end

        modifier = ArithmeticEvaluator.eval(m[1])
        target_flag = !m[2].nil?

        dice_result = roll_dice_with_modifier(modifier)

        if target_flag
          target = ArithmeticEvaluator.eval(m[3])
          r = determine_target_result("", dice_result[:total], target, dice_result[:critical], dice_result[:fumble])
        else
          r = determine_no_target_result("", dice_result[:total], dice_result[:critical], dice_result[:fumble])
        end
        r.text = "(#{m[0]}) ＞ #{dice_result[:dice_sum]}[#{dice_result[:dice_list].join(',')}]#{m[1]} ＞ #{dice_result[:total]} ＞ #{r.text}"
        return r
      end

      # 基準値(modifier)をもとに2d6+基準値の判定を行う
      def roll_dice_with_modifier(modifier)
        dice_list = randomizer.roll_barabara(2, 6)
        dice_sum = dice_list.sum
        total = dice_sum + modifier
        critical_flag = dice_list.count(6) == 2
        fumble_flag = dice_list.count(1) == 2
        return {dice_list: dice_list, dice_sum: dice_sum, total: total, critical: critical_flag, fumble: fumble_flag}
      end

      # roll_typeごとにResultを作成（目標値あり）
      def determine_target_result(roll_type, total, target, critical, fumble)
        case roll_type
        when "H"
          if critical
            Result.critical("クリティカル命中")
          elsif fumble
            Result.fumble("ファンブル")
          elsif total >= target + 4
            Result.success("急所命中")
          elsif total >= target
            Result.success("命中")
          else
            Result.failure("失敗")
          end
        when "D"
          if critical
            Result.critical("クリティカル")
          elsif fumble
            Result.fumble("ファンブル")
          elsif total >= target
            Result.success("回避成功")
          elsif total >= target - 4
            Result.failure("半減命中")
          else
            Result.failure("失敗")
          end
        when "M"
          # 抵抗判定は基準値以上(激情)のほうが悪い効果のことが多いためResultを反転[6,6]の場合にファンブル
          if critical
            Result.fumble("必ず激情")
          elsif fumble
            Result.critical("必ず平静")
          elsif total >= target
            Result.failure("激情")
          else
            Result.success("平静")
          end
        else
          if critical
            Result.critical("クリティカル")
          elsif fumble
            Result.fumble("ファンブル")
          elsif total >= target
            Result.success("成功")
          else
            Result.failure("失敗")
          end
        end
      end

      # roll_typeごとにResultを作成（目標値なし）
      def determine_no_target_result(roll_type, total, critical, fumble)
        case roll_type
        when "S"
          if critical
            Result.critical("クリティカル")
          elsif fumble
            Result.fumble("ファンブル")
          else
            Integer success_level = (total - 4) / 2
            if success_level >= 11
              success_level = 11
            elsif success_level <= 0
              success_level = 1
            end
            r = Result.new
            r.text = "成功ML #{success_level}"
            return r
          end
        else
          if critical
            Result.critical("クリティカル")
          elsif fumble
            Result.fumble("ファンブル")
          else
            r = Result.new
            r.text = "達成値 #{total}"
            return r
          end
        end
      end
    end
  end
end
