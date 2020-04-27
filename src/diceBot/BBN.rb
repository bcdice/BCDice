# -*- coding: utf-8 -*-

class BBN < DiceBot
  # ダイスボットで使用するコマンドを配列で列挙する
  setPrefixes(['\d+BN.*'])

  ID = 'BBN'

  NAME = 'BBNTRPG'

  SORT_KEY = 'ひいひいえぬTRPG'

  HELP_MESSAGE =  <<MESSAGETEXT
・判定(xBN±y>=z[c,f])
　xD6の判定。クリティカル、ファンブルの自動判定を行います。
　1Dの場合はクリティカル、ファンブルなし。2Dの場合は6ゾロと1ゾロのみクリティカル、ファンブルになります。
　クリティカルとファンブルが同時に発生した場合、自動的に相殺されます。
　x：xに振るダイス数を入力。
　y：yに修正値を入力。省略可能。
  z：zに目標値を入力。省略可能。
  c：クリティカルに必要なダイス目「６」の数の増減。省略可能。
  f：ファンブルに必要なダイス目「６」の数の増減。省略可能。
　例） 3BN+4　3BN>=8　3BN+1>=10[6]
MESSAGETEXT

  def rollDiceCommand(command)
    return getCheckRollDiceCommandResult(command)
  end

  def getCheckRollDiceCommandResult(command)
    test = "test"
    return nil unless /(\d+)BN([\+\-\d]*)(>=([\+\-\d]*))?(\[([\+\-\d]*)?(,[\+\-\d]*)?\])?/i === command

    diceCount = Regexp.last_match(1).to_i
    modifyText = (Regexp.last_match(2) || '')
    difficultyText = (Regexp.last_match(4) || '')
    cfText = (Regexp.last_match(5) || '')

    modify = RetNum(modifyText)
    difficulty = RetNum(difficultyText)

    # ダイスロール
    dice, dice_str = roll(diceCount, 6)
    diceList = dice_str.split(/,/).collect { |i| i.to_i }.sort

    total = dice + modify

    # 出力文の生成
    result = "(#{command}) ＞ #{dice}[#{dice_str}]#{modifyText} ＞ #{total}"

    cricicalCheck = isCritical(diceList, cfText, diceCount)
    fambleCheck = isFamble(diceList, cfText, diceCount)

    # クリティカル・ファンブルチェック
    if cricicalCheck != 0 && fambleCheck != 0
      result += getJudgeResultString(difficulty, total)
    elsif cricicalCheck >= 1
      result += " ＞ クリティカル！ ＞ "
      result += getCriticalResultString(difficulty, total, cricicalCheck)
    elsif fambleCheck >= 1
      result += " ＞ ファンブル！"
    else
      result += getJudgeResultString(difficulty, total)
    end

    return result
  end

  def isCritical(diceList, cfText, dicecount)
    temp = diceList.select { |i| i == 6 }.size

    if cfText.nil?
      critical = 0
    else
      if /\[([\+\-\d]*)(,([\+\-\d]*)?)?\]/ =~ cfText
        criticalText = Regexp.last_match(1)
        critical = RetNum(criticalText)
      else
        critical = 0
      end
    end

    result = 0

    targetFloat = dicecount.to_f / 2
    target = targetFloat.ceil.to_i + critical

    if dicecount == 2
      target += 1
    elsif dicecount == 1
      temp = 0
    end

    if temp >= target
      result = temp
    else
      result = 0
    end
    return result
  end

  def isFamble(diceList, cfText, dicecount)
    temp = diceList.select { |i| i == 1 }.size

    if cfText.nil?
      famble = 0
    else
      if /\[([\+\-\d]*)(,([\+\-\d]*)?)?\]/ =~ cfText
        fambleText = Regexp.last_match(3)
        famble = RetNum(fambleText)
      else
        famble = 0
      end
    end

    result = 0

    targetFloat = dicecount.to_f / 2
    target = targetFloat.ceil.to_i + famble

    if dicecount == 2
      target += 1
    elsif dicecount == 1
      temp = 0
    end

    if temp >= target
      result = temp
    else
      result = 0
    end
    return result
  end
end

# 成否判定
def getJudgeResultString(difficulty, total)
  return '' if difficulty.nil?

  if total >= difficulty
    return " ＞ 成功"
  else
    return " ＞ 失敗"
  end
end

# クリティカルの成否判定
def getCriticalResultString(difficulty, total, cricicalCheck)
  return '' if difficulty.nil?

  result = ""

  flag = 0
  count = cricicalCheck
  while flag == 0
    dice, dice_str = roll(count, 6)
    diceList = dice_str.split(/,/).collect { |i| i.to_i }.sort
    temp = diceList.select { |i| i == 6 }.size

    temp2 = total
    total += dice

    if temp >= 1
      count = temp
      result += "#{temp2}+#{dice}[#{dice_str}]"
      result += " ＞ 追加クリティカル！ ＞ "
    else
      result += "#{temp2}+#{dice}[#{dice_str}] ＞ #{total}"
      flag = 1
    end
  end

  if total >= difficulty
    result += " ＞ 成功"
  else
    result += " ＞ 失敗"
  end
  return result
end

def RetNum(text)
  if !text.nil?
    result = text.gsub(/[^0-9\-]/, "")
    return result.to_i
  else
    return 0
  end
end
