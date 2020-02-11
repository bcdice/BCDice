# -*- coding: utf-8 -*-

class SRS < DiceBot
  setPrefixes(['2D6.*'])

  def initialize
    super

    @sendMode = 2
    @sortType = 1
    @need_check_critical_2d6 = false
  end

  def gameName
    'Standard RPG System'
  end

  def gameType
    "SRS"
  end

  def getHelpMessage
    return <<INFO_MESSAGE_TEXT
・判定
　・通常判定　　　　　　2D6+m>=t[c,f]
　　修正値m,目標値t,クリティカル値c,ファンブル値fで判定ロールを行います。
　　クリティカル値、ファンブル値は省略可能です。([]ごと省略できます)
　　自動成功、自動失敗、成功、失敗を自動表示します。

　　例) 2d6+2>=10       修整+2、目標値10で判定
　　例) 2d6+2>=10[11]   ↑をクリティカル値11で判定
　　例) 2d6+2>=10[12,4] ↑をクリティカル値12、ファンブル値4で判定
INFO_MESSAGE_TEXT
  end

  def rollDiceCommand(command)
    return roll_2d6_with_compare(command) || roll_2d6_without_compare(command)
  end

  def roll_2d6_with_compare(string)
    crit = 12
    fumble = 2

    return nil unless /^2D6([\+\-\d]*)>=(\d+)(\[(\d+)?(,(\d+))?\])?$/i =~ string

    modText = Regexp.last_match(1)
    target = Regexp.last_match(2).to_i
    crit = Regexp.last_match(4).to_i if Regexp.last_match(4)
    fumble = Regexp.last_match(6).to_i if Regexp.last_match(6)

    mod = 0
    mod = parren_killer("(0#{modText})") unless modText.nil?

    total, dice_str, = roll(2, 6, @sortType && 1)
    total_n = total + mod.to_i

    if mod.to_i < 0
      output = "#{total}[#{dice_str}]－#{mod.to_i.abs} ＞ #{total_n}"
    else
      output = "#{total}[#{dice_str}]＋#{mod} ＞ #{total_n}"
    end

    if total >= crit
      output += " ＞ 自動成功"
    elsif total <= fumble
      output += " ＞ 自動失敗"
    elsif total_n >= target
      output += " ＞ 成功"
    else
      output += " ＞ 失敗"
    end

    output = "(#{string}) ＞ #{output}"
    return output
  end

  def roll_2d6_without_compare(string)
    unless @need_check_critical_2d6
      return nil
    end

    m = /^2D6([\+\-\d]*)$/i.match(string)
    unless m
      return nil
    end

    constant = ArithmeticEvaluator.new.eval(m[1], @fractionType.to_sym)
    total, dice_str, = roll(2, 6, @sortType && 1)
    total_n = total + constant

    if constant < 0
      output = "#{total}[#{dice_str}]－#{constant.abs} ＞ #{total_n}"
    else
      output = "#{total}[#{dice_str}]＋#{constant} ＞ #{total_n}"
    end

    if total >= 12
      output += " ＞ 自動成功"
    elsif total <= 2
      output += " ＞ 自動失敗"
    end

    output = "(#{string}) ＞ #{output}"

    return output
  end
end
