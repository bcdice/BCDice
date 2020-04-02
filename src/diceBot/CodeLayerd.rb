# -*- coding: utf-8 -*-
# frozen_string_literal: true

require 'utils/modifier_formatter'

class CodeLayerd < DiceBot
  include ModifierFormatter
  # ゲームシステムの識別子
  ID = 'CodeLayerd'

  # ゲームシステム名
  NAME = 'コード：レイヤード'

  # ゲームシステム名の読みがな
  SORT_KEY = 'こおとれいやあと'

  # ダイスボットの使い方
  HELP_MESSAGE = <<MESSAGETEXT
・行為判定（nCL@m+x または nCL+x@m） クリティカル・ファンブル判定あり
  n個のD10でmを判定値とした行為判定を行う。mは省略可能。（@6扱い）
  修正値x(固定成功度)もつけられます。
  例）7CL>=5 ：サイコロ7個で判定値6のロールを行い、目標値5に対して判定
  例）4CL@7  ：サイコロ4個で判定値7のロールを行い達成値を出す
  例）4CL+2@7 または 4CL@7+2  ：サイコロ4個で判定値7のロールを行い達成値を出し、修正値2を足す。
MESSAGETEXT

  setPrefixes(['\d*CL[@\d]*.*'])

  def isGetOriginalMessage
    true
  end

  def rollDiceCommand(command)
    debug('rollDiceCommand command', command)

    result = ''

    case command
    when /(\d+)?CL([+-]\d+)?(\@?(\d))?([+-]\d+)?(>=(\d+))?/i
      m = Regexp.last_match
      base = (m[1] || 1).to_i
      modifier1 = (m[2].to_i || 0)
      target = (m[4] || 6).to_i
      modifier2 = (m[5].to_i || 0)
      diff = m[7].to_i
      result = checkRoll(base, target, diff, modifier1 + modifier2)
    end

    return nil if result.empty?

    return "#{command} ＞ #{result}"
  end

  def checkRoll(base, target, diff, modifier)
    result = ""

    base = getValue(base)
    target = getValue(target)

    return result if base < 1

    target = 10 if target > 10

    result += "(#{base}d10#{format_modifier(modifier)})"

    _, diceText = roll(base, 10)

    diceList = diceText.split(/,/).collect { |i| i.to_i }.sort

    result += " ＞ [#{diceList.join(',')}]#{format_modifier(modifier)} ＞ "
    result += getRollResultString(diceList, target, diff, modifier)

    return result
  end

  def getRollResultString(diceList, target, diff, modifier)
    successCount, criticalCount = getSuccessInfo(diceList, target)

    successTotal = successCount + criticalCount + modifier
    result = ""

    result += "判定値[#{target}] 達成値[#{successCount}]"
    result += "+クリティカル[#{criticalCount}]" if criticalCount > 0
    result += format_modifier(modifier)
    result += "=[#{successTotal}]" if criticalCount > 0 || modifier != 0

    successText = getSuccessResultText(successTotal, diff)
    result += " ＞ #{successText}"

    return result
  end

  def getSuccessResultText(successTotal, diff)
    return "ファンブル！" if successTotal <= 0
    return successTotal.to_s if diff == 0
    return "成功" if successTotal >= diff

    return "失敗"
  end

  def getSuccessInfo(diceList, target)
    debug("checkSuccess diceList, target", diceList, target)

    successCount  = 0
    criticalCount = 0

    diceList.each do |dice|
      successCount += 1 if dice <= target
      criticalCount += 1 if dice == 1
    end

    return successCount, criticalCount
  end

  def getValue(number)
    return 0 if number > 100

    return number
  end
end
