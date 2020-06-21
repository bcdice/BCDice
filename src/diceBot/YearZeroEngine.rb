# -*- coding: utf-8 -*-
# frozen_string_literal: true

class YearZeroEngine < DiceBot
  # ゲームシステムの識別子
  ID = 'YearZeroEngine'

  # ゲームシステム名
  NAME = 'イヤーゼロエンジン'

  # ゲームシステム名の読みがな
  SORT_KEY = 'いやあせろえんしん'

  # ダイスボットの使い方
  HELP_MESSAGE = <<INFO_MESSAGE_TEXT
・判定コマンド(YZEx+x+x)
  YZE(能力ダイス数)+(技能ダイス数)+(修正ダイス数)  # YearZeroEngine(TALES FROM THE LOOP等)の判定(6を数える)
  ※ 技能と修正ダイス数は省略可能
INFO_MESSAGE_TEXT

  ABILITY_INDEX    = 2 # 能力値ダイスのインデックス
  SKILL_INDEX      = 4 # 技能値ダイスのインデックス
  MODIFIED_INDEX   = 6 # 修正ダイスのインデックス

  setPrefixes(['YZE.*'])

  def rollDiceCommand(command)
    m = /\A(YZE)(\d+)(\+(\d+))?(\+(\d+))?/.match(command)
    unless m
      return ''
    end

    success_dice = 0
    match_text = m[ABILITY_INDEX]
    ability_dice_text, success_dice = make_dice_roll(match_text, success_dice)

    dice_count_text = "(#{match_text}D6)"
    dice_text = ability_dice_text

    match_text = m[SKILL_INDEX]
    if match_text
      skill_dice_text, success_dice = make_dice_roll(match_text, success_dice)

      dice_count_text += "+(#{match_text}D6)"
      dice_text += "+#{skill_dice_text}"
    end

    match_text = m[MODIFIED_INDEX]
    if match_text
      modified_dice_text, success_dice = make_dice_roll(match_text, success_dice)

      dice_count_text += "+(#{match_text}D6)"
      dice_text += "+#{modified_dice_text}"
    end

    return "#{dice_count_text} ＞ #{dice_text} 成功数:#{success_dice}"
  end

  def make_dice_roll(match_text, success_dice)
    dice = match_text.to_i
    _, dice_text, = roll(dice, 6)

    dice_text.split(',').each do |take_dice|
      if take_dice == "6"
        success_dice += 1
      end
    end
    return "[#{dice_text}]", success_dice
  end
end
