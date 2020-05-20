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
  SORT_KEY = 'さんさーらばらっど'

  # ダイスボットの使い方
  HELP_MESSAGE = <<MESSAGETEXT
SB	 通常の1d100ロールを行う
SBS	 スワップロールで1d100ロールを行う
SB(F,C)	 F値、C値を適用して通常の1d100ロールを行う
SBS(F,C)	 F値、C値を適用してスワップロールで1d100ロールを行う

例：
SB<=85 通常の技能で成功率85%の判定
SBS<=70 習熟を得た技能で成功率70%の判定
SBS(3,7)<=80 習熟を得た技能で、F値3、C値7で成功率80%の判定
MESSAGETEXT

  # ダイスボットで使用するコマンドを配列で列挙する
  setPrefixes(['SBS?(\(\d,\d\))?.*'])

  def initialize
    @swap = false
    @f_value = -1
    @c_value = 10
    super
  end

  def rollDiceCommand(command)
    debug("rollDiceCommand Begin")

    case command
    when /SBS\((\d),(\d)\)/i
      debug("Swap roll with F and C")
      @swap = true
      @f_value = Regexp.last_match(1).to_i
      @c_value = Regexp.last_match(2).to_i
      return getCheckResult(command)
    when /SB\((\d),(\d)\)/i
      debug("Normal roll with F and C")
      @swap = false
      @f_value = Regexp.last_match(1).to_i
      @c_value = Regexp.last_match(2).to_i
      return getCheckResult(command)
    when /SBS/i
      debug("Swap roll")
      @swap = true
      @f_value = -1
      @c_value = 10
      return getCheckResult(command)
    when /SB/i
      debug("Normal roll")
      @swap = false
      @f_value = -1
      @c_value = 10
      return getCheckResult(command)
    end
    return nil
  end

  def getCheckResult(command)
    diff = 0

    if (m = %r{SBS?(\(\d,\d\))?<=([+-/*\d]+)}i.match(command))
      diff = ArithmeticEvaluator.new.eval(m[2])
    end

    total_n, = roll(1, 100)
    dice_label = total_n.to_s
    if total_n < 100 && @swap
      x = total_n.div(10)
      y = total_n % 10
      if x > y
        new_total_n = 10 * y + x
        dice_label = "#{total_n} -> #{new_total_n}"
        total_n = new_total_n
      end
    end

    is_fumble = @f_value > 0 && total_n % 10 <= @f_value
    is_critical = !is_fumble && @c_value < 10 && total_n % 10 >= @c_value

    if diff > 0
      output = "(1D100<=#{diff})"
      output += " ＞ #{dice_label}"
      if (total_n <= diff) && (total_n < 100)
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
      output += " ＞ #{dice_label}"
      if is_fumble
        output += " ＞ ファンブル"
      elsif is_critical
        output += " ＞ クリティカル"
      end
    end

    return output
  end
end
