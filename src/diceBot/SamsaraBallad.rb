# -*- coding: utf-8 -*-
# frozen_string_literal: true

class SamsaraBallad < DiceBot
  # ゲームシステムの識別子
  ID = 'SamsaraBallad'

  # ゲームシステム名
  NAME = 'サンサーラ・バラッド'

  # ゲームシステム名の読みがな
  #
  # 「ゲームシステム名の読みがなの設定方法」（docs/dicebot_sort_key.md）を参考にして
  # 設定してください
  SORT_KEY = 'さんさあらはらつと'

  # ダイスボットの使い方
  HELP_MESSAGE = <<MESSAGETEXT
SB	 通常のD100ロールを行う
SBS	 スワップロールでD100ロールを行う
SB#x@y	 F値をx、C値をyとして通常のD100ロールを行う
SBS#x@y	 F値をx、C値をyとしてスワップロールでD100ロールを行う

例：
SB<=85 通常の技能で成功率85%の判定
SBS<=70 習熟を得た技能で成功率70%の判定
SBS#3@7<=80 習熟を得た技能で、F値3、C値7で成功率80%の攻撃判定
SB<57 通常の技能で、能動側の達成値が57の受動判定
SBS<70 習熟を得た技能で、能動側の達成値が70の受動判定
MESSAGETEXT

  # ダイスボットで使用するコマンドを配列で列挙する
  setPrefixes(['SBS?(#\d@\d)?(<=?[+-/*\d]+)?'])

  def rollDiceCommand(command)
    debug("rollDiceCommand Begin")

    is_swap = false
    f_value = -1
    c_value = 10
    diff = 0
    is_diff_eq_allowable = true

    if (m = %r{SB(S?)(#(\d)@(\d))?(<(=?)([+-/*\d]+))?}i.match(command))
      is_swap = true if m[1] != ""
      unless m[2].nil?
        f_value = m[3].to_i
        c_value = m[4].to_i
      end
      unless m[5].nil?
        diff = ArithmeticEvaluator.new.eval(m[7])
        is_diff_eq_allowable = false if m[6] == ""
      end
    else
      debug("command parse failed")
      return nil
    end

    debug("SamsaraBallad Roll Param:", is_swap, f_value, c_value, diff, is_diff_eq_allowable)
    return getCheckResult(is_swap, f_value, c_value, diff, is_diff_eq_allowable)
  end

  def getCheckResult(is_swap, f_value, c_value, diff, is_diff_eq_allowable)
    if is_swap
      d100_n1, = roll(1, 10)
      d100_n2, = roll(1, 10)
      d100_dice = [d100_n1, d100_n2]
      min_n = d100_dice.min
      max_n = d100_dice.max
      debug(min_n, max_n)
      if min_n == 10
        total_n = 100
      elsif max_n == 10
        total_n = min_n
      else
        total_n = 10 * min_n + max_n
      end
      dice_label = "#{d100_n1},#{d100_n2} ＞ #{total_n}"
    else
      total_n, = roll(1, 100)
      dice_label = total_n.to_s
    end

    is_fumble = f_value >= 0 && total_n % 10 <= f_value
    is_critical = !is_fumble && c_value < 10 && total_n % 10 >= c_value

    if diff > 0
      if is_diff_eq_allowable
        output = "(D100<=#{diff})"
        cmp = (total_n <= diff) && (total_n < 100)
      else
        output = "(D100<#{diff})"
        cmp = (total_n < diff) && (total_n < 100)
      end
      output += " ＞ #{dice_label}"
      if cmp
        if is_fumble
          output += " ＞ ファンブル"
        elsif is_critical
          output += " ＞ クリティカル"
        else
          output += " ＞ 成功"
        end
      else
        output += " ＞ 失敗"
      end
    else
      output = "D100 ＞ #{dice_label}"
      if is_fumble
        output += " ＞ ファンブル"
      elsif is_critical
        output += " ＞ クリティカル"
      end
    end

    return output
  end
end
