# -*- coding: utf-8 -*-
# frozen_string_literal: true

class NeverCloud < DiceBot
  # ゲームシステムの識別子
  ID = 'NeverCloud'

  # ゲームシステム名
  NAME = 'ネバークラウドTRPG'

  # ゲームシステム名の読みがな
  #
  # 「ゲームシステム名の読みがなの設定方法」（docs/dicebot_sort_key.md）を参考にして
  # 設定してください
  SORT_KEY = 'ねはあくらうとTRPG'

  # ダイスボットの使い方
  HELP_MESSAGE = <<MESSAGETEXT
・判定(xNC±y>=z)
　xD6の判定を行います。ファンブル、クリティカルの場合、その旨を出力します。
　x：振るダイスの数。
　±y：固定値・修正値。省略可能。
　z：目標値。省略可能。
　例）　2NC+2>=5　1NC
MESSAGETEXT

  # ダイスボットで使用するコマンドを配列で列挙する
  setPrefixes(['\d+NC.*', '\d+D6?([\+\-\d]*)>=\d+'])

  def initialize
    super
  end

  def changeText(string)
    string
  end

  def rollDiceCommand(command)
    adjust = 0
    adjust_str = ''
    target = -1
    target_str = ''
    op = ''

    case command
    when /^\d+NC([\+\-\d]*)(>=)?(\d+)?$/i
      adjust_str = Regexp.last_match(1) if Regexp.last_match(1)
      adjust = parren_killer("(0#{adjust_str})").to_i if adjust_str != ''
      op = Regexp.last_match(2) if Regexp.last_match(2)
      target_str = Regexp.last_match(3) if Regexp.last_match(3)
      target = target_str.to_i if target_str != ''
      dice = command[0] + 'D6' + adjust_str + op + target_str
    when /^\d+D6?([\+\-\d]*)(>=)?(\d+)?$/i
      adjust_str = Regexp.last_match(1) if Regexp.last_match(1)
      adjust = parren_killer("(0#{adjust_str})").to_i if adjust_str != ''
      target_str = Regexp.last_match(3) if Regexp.last_match(3)
      target = target_str.to_i if target_str != ''
      dice = command
    else
      return ''
    end
    total, dice_str, result_val, result = checkRoll(command[0].to_i, adjust, target)
    if result != ""
      return "(#{dice}) ＞ #{total}[#{dice_str}]#{adjust_str if adjust != 0} ＞ #{result_val} ＞ #{result}"
    else
      return "(#{dice}) ＞ #{total}[#{dice_str}]#{adjust_str if adjust != 0} ＞ #{result_val}"
    end
  end

  def checkRoll(dice_count, adjust, target)
    result = ""
    total, dice_str, number_spot_1, cnt_max, = roll(dice_count, 6)
    result_val = total + adjust
    if dice_count == number_spot_1
      result = "ファンブル"
      result_val = 0
    elsif cnt_max >= 2
      result = "クリティカル"
    elsif total + adjust >= target && target != -1
      result = "成功"
    elsif total + adjust < target && target != -1
      result = "失敗"
    end
    return total, dice_str, result_val, result
  end
end
