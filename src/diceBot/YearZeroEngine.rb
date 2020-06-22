# -*- coding: utf-8 -*-
# frozen_string_literal: true

class YearZeroEngine < DiceBot
  # ゲームシステムの識別子
  ID = 'YearZeroEngine'

  # ゲームシステム名
  NAME = 'YearZeroEngine'

  # ゲームシステム名の読みがな
  SORT_KEY = 'いやあせろえんしん'

  # ダイスボットの使い方
  HELP_MESSAGE = <<INFO_MESSAGE_TEXT
・判定コマンド(YZEx+x+x)
  (難易度)YZE(能力ダイス数)+(技能ダイス数)+(修正ダイス数)  # YearZeroEngine(TALES FROM THE LOOP等)の判定(6を数える)
  ※ 難易度と技能、修正ダイス数は省略可能
INFO_MESSAGE_TEXT

  DIFFICULTY_INDEX   = 1 # 難易度のインデックス
  COMMAND_TYPE_INDEX = 2 # コマンドタイプのインデックス
  ABILITY_INDEX      = 3 # 能力値ダイスのインデックス
  SKILL_INDEX        = 5 # 技能値ダイスのインデックス
  MODIFIED_INDEX     = 7 # 修正ダイスのインデックス

  setPrefixes(['(\d+)?YZE.*'])

  def rollDiceCommand(command)
    m = /\A(\d+)?(YZE)(\d+)(\+(\d+))?(\+(\d+))?/.match(command)
    unless m
      return ''
    end

    difficulty = m[DIFFICULTY_INDEX].to_i

    command_type = m[COMMAND_TYPE_INDEX]

    total_success_dice = 0

    match_text = m[ABILITY_INDEX]
    ability_dice_text, success_dice = make_dice_roll(match_text)
    total_success_dice += success_dice

    dice_count_text = "(#{match_text}D6)"
    dice_text = ability_dice_text

    match_text = m[SKILL_INDEX]
    if match_text
      skill_dice_text, success_dice = make_dice_roll(match_text)
      total_success_dice += success_dice

      dice_count_text += "+(#{match_text}D6)"
      dice_text += "+#{skill_dice_text}"
    end

    match_text = m[MODIFIED_INDEX]
    if match_text
      modified_dice_text, success_dice = make_dice_roll(match_text)
      total_success_dice += success_dice

      dice_count_text += "+(#{match_text}D6)"
      dice_text += "+#{modified_dice_text}"
    end

    result_text = "#{dice_count_text} ＞ #{dice_text} 成功数:#{total_success_dice}"
    if difficulty > 0
      if total_success_dice >= difficulty
        result_text = "#{result_text} 難易度=#{difficulty}:判定成功！"
      else
        result_text = "#{result_text} 難易度=#{difficulty}:判定失敗！"
      end
    end

    return result_text
  end

  def make_dice_roll(match_text)
    botch_dice = 0
    success_dice = 0

    dice = match_text.to_i
    _, dice_text, = roll(dice, 6)

    dice_text.split(',').each do |take_dice|
      if take_dice == "6"
        success_dice += 1
      elsif take_dice == "1"
        botch_dice += 1
      end
    end
    return "[#{dice_text}]", success_dice, botch_dice
  end
end
