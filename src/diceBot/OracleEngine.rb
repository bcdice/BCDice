# -*- coding: utf-8 -*-
# frozen_string_literal: true

class OracleEngine < DiceBot
  # ゲームシステムの識別子
  ID = 'OracleEngine'

  # ゲームシステム名
  NAME = 'オラクルエンジン'

  # ゲームシステム名の読みがな
  #
  # 「ゲームシステム名の読みがなの設定方法」（docs/dicebot_sort_key.md）を参考にして
  # 設定してください
  SORT_KEY = 'おらくるえんしん'

  # ダイスボットの使い方
  HELP_MESSAGE = <<MESSAGETEXT
  ・クラッチロール （xCL+y>=z)
  ダイスをx個振り、1個以上目標シフトzに到達したか判定します。修正yは全てのダイスにかかります。
  成功した時は目標シフトを、失敗した時はダイスの最大値-1シフトを返します
  zが指定されないときは、ダイスをx個を振り、それに修正yしたものを返します。
  通常、最低シフトは1、最大シフトは6です。目標シフトもそろえられます。
  また、CLの後に7を入れ、(xCL7+y>=z)と入力すると最大シフトが7になります。
 ・判定 (xR6+y@c#f$b>=z)
  ダイスをx個振り、大きいもの2つだけを見て達成値を算出し、成否を判定します。修正yは達成値にかかります。
  ダイスブレイクとしてbを、クリティカル値としてcを、ファンブル値としてfを指定できます。
  それぞれ指定されない時、0,12,2になります。
  クリティカル値の上限はなし、下限は2。ファンブル値の上限は12、下限は0。
  zが指定されないとき、達成値の算出のみ行います。
 ・ダメージロールのダイスブレイク (xD6+y$b)
  ダイスをx個振り、合計値を出します。修正yは合計値にかかります。
  ダイスブレイクとしてbを指定します。合計値は0未満になりません。
MESSAGETEXT

  # ダイスボットで使用するコマンドを配列で列挙する
  setPrefixes(['\d+CL.*', '\d+R6.*', '\d+D6.*\$[\+\-]?\d+.*'])

  def initialize
    super
    @sortType = 3
  end

  def rollDiceCommand(command)
    case command
    when /\d+CL.*/i
      ClutchRoll(command)
    when /\d+D6.*\$[\+\-]?\d.*/
      DamageRoll(command)
    else
      super(command)
    end
  end

  def dice_command_xRn(string, nick_e)
    return OracleEngine_roll(string, nick_e)
  end

  def getDiceList(string)
    array = string.split(",").map { |i| i.to_i }
    return array
  end

  def addBonusTextToString(string, bonus)
    string ||= ""
    bonus ||= 0
    string += "+#{bonus}" unless (bonus == 0) || /^\d+/.match(bonus.to_s).nil?
    string += bonus.to_s unless (bonus == 0) || /^[\+\-]\d+/.match(bonus.to_s).nil?

    return string
  end

  # ##############クラッチロール###############

  def ClutchRoll(string)
    debug("ClutchRoll begin", string)

    m = /(^|\s)S?((\d+)CL(6|7)?(([\+\-]\d+)*)(([>=]+)(\d+))?)(\s|$)/i.match(string)
    return '1' if m.nil?

    _, _, diceCount, maxShift, modifyText, _, _, signOfInequality, target, = m.captures
    diceCount = diceCount.to_i
    minShift = 1
    maxShift ||= 6
    maxShift = maxShift.to_i
    signOfInequality ||= ""
    target ||= 0
    target = Min_Max_Shift(target.to_i, minShift, maxShift)

    debug("m", m)
    debug("diceCount", diceCount)
    debug("maxShift", maxShift)
    debug("modifyText", modifyText)
    debug("signOfInequality", signOfInequality)
    debug("target", target)

    return '1' if diceCount == 0

    bonus = 0
    if modifyText
      bonus = parren_killer("(0#{modifyText})").to_i
    end
    debug("bonus", bonus)

    dummy, diceText = roll(diceCount, 6)
    diceArray = getDiceList(diceText)
    diceArray = diceArray.map { |i| Min_Max_Shift(i + bonus, minShift, maxShift) }.sort
    debug("diceArray", diceArray)

    output = "(#{diceCount}CL"
    output += "7" if maxShift == 7
    output = addBonusTextToString(output, bonus)
    output += ">=#{target}" unless /(>=|=>)/.match(signOfInequality).nil? || (target == 0)
    output += ") > #{diceArray} > "
    afterShift = diceArray.last

    debug("output", output)
    if /(>=|=>)/.match(signOfInequality).nil?
      debug("no check")
      output += "シフト#{afterShift}"
    else
      debug("check sucsess")
      if afterShift >= target
        output += "成功 シフト#{target}"
      else
        afterShift -= 1
        afterShift = 1 if afterShift < 1
        output += "失敗 シフト#{afterShift}"
      end
    end

    return output
  end

  def Min_Max_Shift(target, min_n, max_n)
    debug("Min_Max_Shift start", target, min_n, max_n)
    target = [target, min_n].max
    target = [target, max_n].min
    return target
  end

  # ##############nR6ロール###############

  def OracleEngine_roll(string, nick_e)
    debug("OE_roll start", string)

    output = '1'

    m = /(^|\s)[sS]?((\d+)[Rr]6(([\+\-]\d+|[\@\#\$][\+\-]?\d+)*)(([>=]+)(\d+))?)($|\s)/.match(string)
    return output if m.nil?

    _, _, diceCount, modifyText, _, _, signOfInequality, target, = m.captures
    diceCount = diceCount.to_i
    target = target.to_i

    debug("diceCount", diceCount)
    debug("modifyText", modifyText)
    debug("signOfInequality", signOfInequality)
    debug("target", target)

    return '1' if diceCount == 0

    crit, modifyText = extract_critical_number(modifyText)
    fumb, modifyText = extract_fumble_number(modifyText)
    brak, modifyText = extract_brake_number(modifyText)

    debug("crit", crit)
    debug("fumb", fumb)
    debug("brak", brak)

    bonus = 0
    if modifyText
      bonus = parren_killer("(0#{modifyText})").to_i
    end
    debug("bonus", bonus)

    dummy, diceText = roll(diceCount, 6)
    diceArray = getDiceList(diceText)
    diceArray = diceArray.map { |i| i.to_i }.sort
    debug("diceArray", diceArray)

    dice_braked = []
    unless brak == 0
      if diceCount < brak
        diceCount.times { dice_braked.unshift(diceArray.pop) }
      else
        brak.times { dice_braked.unshift(diceArray.pop) }
      end
    end
    debug("diceArray after brake", diceArray)

    dice_now = 0
    dice_now += diceArray[-1] if diceArray.length >= 1
    dice_now += diceArray[-2] if diceArray.length >= 2

    total_n = dice_now + bonus
    debug("dice_now, total_n", dice_now, total_n)

    output = "#{nick_e}: (#{diceCount}R6"
    output = addBonusTextToString(output, bonus)
    output += "c[#{crit}]" unless crit == 12
    output += "f[#{fumb}]" unless fumb == 2
    output += "b[#{brak}]" unless brak == 0
    output += ">=#{target}" unless /(>=|=>)/.match(signOfInequality).nil? || target.nil?
    output += ") > #{dice_now}#{diceArray}"
    output += "×#{dice_braked}" unless dice_braked.empty?
    output = addBonusTextToString(output, bonus)
    output += " > "

    debug("check sucsess")

    if dice_now <= fumb
      output += "ファンブル!"
    elsif dice_now >= crit
      output += "クリティカル!"
    else
      output += total_n.to_s
      unless /(>=|=>)/.match(signOfInequality).nil?
        if total_n >= target
          output += " 成功"
        else
          output += " 失敗"
        end
      end
    end

    return output
  end

  def extract_critical_number(string)
    crit = 12
    m = /\@[\+\-]?(\d+)/.match(string)
    unless m.nil?
      crit = m[1].to_i
      crit = 12 - crit unless /\@\-(\d+)/.match(string).nil?
      crit = 12 + crit unless /\@\+(\d+)/.match(string).nil?
      string = string.gsub(m.regexp, '')
    end

    critDwLim = 2
    crit = critDwLim if crit < critDwLim

    return crit, string
  end

  def extract_fumble_number(string)
    fumb = 2
    m = /\#[\+\-]?(\d+)/.match(string)
    unless m.nil?
      fumb = m[1].to_i
      fumb = 2 - fumb unless /\#\-(\d+)/.match(string).nil?
      fumb = 2 + fumb unless /\#\+(\d+)/.match(string).nil?
      string = string.gsub(m.regexp, '')
    end

    fumbUpLim = 12
    fumbDwLim = 0
    fumb = Min_Max_Shift(fumb, fumbDwLim, fumbUpLim)

    return fumb, string
  end

  def extract_brake_number(string)
    brak = 0
    m = /\$[\+\-]?(\d+)/.match(string)
    unless m.nil?
      brak = m[1].to_i
      string = string.gsub(m.regexp, '')
    end

    return brak, string
  end

  # ##############ダメージロール###############

  def DamageRoll(string)
    debug("DamageRoll start")
    output = '1'

    m = /(^|\s)S?((\d+)D6(([\+\-]\d+|\$[\+\-]?\d+)*))($|\s)/i.match(string)
    return output if m.nil?

    _, _, diceCount, modifyText, = m.captures
    diceCount = diceCount.to_i
    brak, modifyText = extract_brake_number(modifyText)
    bonus = 0
    if modifyText
      bonus = parren_killer("(0#{modifyText})").to_i
    end
    debug("diceCount", diceCount, "brak", brak, "bonus", bonus)

    return '1' if diceCount == 0

    dummy, diceText, = roll(diceCount, 6)
    diceArray = getDiceList(diceText)
    diceArray = diceArray.map { |i| i.to_i }.sort
    debug("diceArray", diceArray.to_s)

    dice_braked = []
    unless brak == 0
      if diceCount < brak
        diceCount.times { dice_braked.unshift(diceArray.pop) }
      else
        brak.times { dice_braked.unshift(diceArray.pop) }
      end
    end
    debug("diceArray after brake", diceArray, "dice_braked", dice_braked)

    dice_now = diceArray.sum(0)
    total_n = dice_now + bonus
    total_n = 0 if total_n < 0

    output = "(#{diceCount}D6"
    output = addBonusTextToString(output, bonus)
    output += "b[#{brak}]" unless brak == 0
    output += ") > #{dice_now}#{diceArray}"
    output += "×#{dice_braked}" unless dice_braked.empty?
    output = addBonusTextToString(output, bonus)
    output += " > #{total_n}"

    return output
  end
end
