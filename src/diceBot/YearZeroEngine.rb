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
・判定コマンド(YZEn+n+n)
  (難易度)YZE(能力ダイス数)+(技能ダイス数)+(修正ダイス数)  # YearZeroEngine(TALES FROM THE LOOP等)の判定(6のみ数える)
  ※ 技能と修正ダイス数は省略可能
INFO_MESSAGE_TEXT

  ConstAbilityIndex    = 2 # 能力値ダイスのインデックス
  ConstSkillIndex      = 4 # 技能値ダイスのインデックス
  ConstModifiedAbility = 6 # 修正ダイスのインデックス

  setPrefixes(['\A(YZE)(\d+)(\+(\d+))?(\+(\d+))?'])

  def initialize
    super
  end

  def rollDiceCommand(_command)
    m = /\A(YZE)(\d+)(\+(\d+))?(\+(\d+))?/.match(_command)
    unless m
      return ''
    end
        
    successDice = 0
    matchText = m[ConstAbilityIndex.to_i]
    abilityDiceText, successDice = makeDiceRoll(matchText, successDice)

    diceCountText = "(#{matchText}D6)"
    diceText = abilityDiceText

    matchText = m[ConstSkillIndex.to_i]
    if matchText
      skillDiceText, successDice = makeDiceRoll(matchText, successDice)
      
      diceCountText += "+(#{matchText}D6)"
      diceText += "+#{skillDiceText}"
    end

    matchText = m[ConstModifiedAbility.to_i]
    if matchText
      modifiedDiceText, successDice = makeDiceRoll(matchText, successDice)
      
      diceCountText += "+(#{matchText}D6)"
      diceText += "+#{modifiedDiceText}"
    end
    
    return "#{diceCountText} ＞ #{diceText} 成功数:#{successDice}"
  end
  
  def makeDiceRoll(matchText, successDice)
    resultText = ""
    
    dice = matchText.to_i
    _, diceText, _ = roll(dice, 6)

    for dice in diceText.split(',') do
      if dice == "6"
        successDice += 1
      end
    end
    return "[#{diceText}]", successDice
  end
end
