# -*- coding: utf-8 -*-
# frozen_string_literal: true

class ParanoiaRebooted < DiceBot
  # ゲームシステムの識別子
  ID = 'ParanoiaRebooted'

  # ゲームシステム名
  NAME = 'パラノイア リブーテッド'

  # ゲームシステム名の読みがな
  SORT_KEY = 'ぱらのいありぶーてっど'

  # ダイスボットの使い方
  HELP_MESSAGE = <<INFO_MESSAGE_TEXT
※コマンドは入力内容の前方一致で検出しています。
・通常の判定　NDx
　x：ノードダイスの数.マイナスも可.
　ノードダイスの絶対値+1個(コンピュータダイス)のダイスがロールされる.
例）ND2　ND-3

・ミュータントパワー判定　MPx
  x：ノードダイスの数.
　ノードダイスの値+1個(コンピュータダイス)のダイスがロールされる.
例）MP2
INFO_MESSAGE_TEXT

  setPrefixes(['ND.*', 'MP.*', 'REQP', 'DINF', 'PDEQP'])

  def initialize
    # $isDebug = true
    super
  end

  def rollDiceCommand(command)
    case command
    when /^ND/i
      return get_node_dice_role(command)
    when /^MP/i
      return get_mutant_power_role(command)
    else
      return nil
    end
  end

  private

  def get_node_dice_role(command)
    debug("rollDiceCommand Begin")

    m = /^ND((-)?\d+)/i.match(command)
    unless m
      return ''
    end

    debug("command", command)

    parameter_num = m[1].to_i
    dice_count = parameter_num.abs + 1

    total, dice_text, = roll(dice_count, 6)
    success_rate = 0
    computer_roll_result = ''
    dices = dice_text.split(/,/)
    index = 0
    results = dices.map do |d|
      result = d.to_i
      if result >= 5
        success_rate += 1
      elsif parameter_num < 0
        success_rate -= 1
      end

      if index == dices.length - 1 && result == 6
        result = "C"
        computer_roll_result = '(Computer)'
      end
      index += 1

      next result
    end

    debug(dices)

    debug("rollDiceCommand result")

    return "(#{command}) ＞ [#{results.join(', ')}] ＞ 成功度#{success_rate}#{computer_roll_result}"
  end

  def get_mutant_power_role(command)
    debug("rollDiceCommand Begin")

    m = /^MP(\d+)/i.match(command)
    unless m
      return ''
    end

    debug("command", command)

    parameter_num = m[1].to_i
    dice_count = parameter_num.abs + 1

    total, dice_text, = roll(dice_count, 6)
    computer_roll_result = ''
    dices = dice_text.split(/,/)
    failure_rate = 0
    index = 0
    results = dices.map do |d|
      result = d.to_i
      if result == 1
        failure_rate -= 1
      end

      if index == dices.length - 1 && result == 6
        result = 'C'
        computer_roll_result = '(Computer)'
      end

      index += 1
      next result
    end

    message = failure_rate >= 0 ? '成功' : "失敗(#{failure_rate.abs})"

    debug(dices)

    debug("rollDiceCommand result")

    return "(#{command}) ＞ [#{results.join(', ')}] ＞ #{message}#{computer_roll_result}"
  end
end
