# -*- coding: utf-8 -*-
# frozen_string_literal: true

class Fiasco < DiceBot
  # ゲームシステムの識別子
  ID = 'Fiasco'

  # ゲームシステム名
  NAME = 'フィアスコ'

  # ゲームシステム名の読みがな
  SORT_KEY = 'ふいあすこ'

  # ダイスボットの使い方
  HELP_MESSAGE = <<INFO_MESSAGE_TEXT
  ・判定コマンド(FSSx, FSWxBx)
    相関図・転落要素用(FSSx)：相関図や転落要素のためにx個ダイスを振り、出目ごとに分類する
    黒白差分判定用(FSWxBx)  ：転落、残響のために白ダイス(W指定)と黒ダイス(B指定)で差分を求める
      ※ WとBは省略(FSBx, FSWx)、入替(FSWxBx,FSBxWx)可能

INFO_MESSAGE_TEXT

  COMMAND_TYPE_INDEX = 1

  START_DICE_INDEX = 2

  BW_FIRST_DICE_INDEX = 2
  BW_SECOND_DICE_INDEX = 5
  BW_SECOND_DICE_TAG_INDEX = 4

  BW_SECOND_DICE_WHITE_TAG = "W"
  BW_SECOND_DICE_BLACK_TAG = "B"

  START_COMMAND_TAG = "FSS"
  WB_DICEROLL_COMMAND_TAG = "FSW"
  BW_DICEROLL_COMMAND_TAG = "FSB"

  setPrefixes(['FS.*'])

  def rollDiceCommand(command)
    m = /\A(FS[SWB]?)(\d+)(([WB])(\d+))?/.match(command)
    unless m
      return ''
    end

    type = m[COMMAND_TYPE_INDEX]
    if type == START_COMMAND_TAG
      return makeStartDiceRoll(m)
    else
      return makeWhiteBlackDiceRoll(type, m)
    end
  end

  def makeStartDiceRoll(m)
    dice = m[START_DICE_INDEX]
    _, diceText, = roll(dice, 6)

    diceList = [0, 0, 0, 0, 0, 0]

    diceText.split(',').each do |takeDice|
      diceList[takeDice.to_i - 1] += 1
    end

    return "１ => #{diceList[0]}個 ２ => #{diceList[1]}個 ３ => #{diceList[2]}個 ４ => #{diceList[3]}個 ５ => #{diceList[4]}個 ６ => #{diceList[5]}個"
  end

  def makeWhiteBlackDiceRoll(type, m)
    if type == WB_DICEROLL_COMMAND_TAG
      whiteTotal, whiteDiceText, blackTotal, blackDiceText = makeDiceRoll(m[BW_FIRST_DICE_INDEX], m[BW_SECOND_DICE_INDEX])
      result = "白ダイス[#{whiteDiceText}]"
      if blackDiceText
        if m[BW_SECOND_DICE_TAG_INDEX][0] == BW_SECOND_DICE_WHITE_TAG
          return "#{m}：白ダイス指定(#{BW_SECOND_DICE_WHITE_TAG})は重複できません。"
        end

        result += " 黒ダイス[#{blackDiceText}]"
      end
    elsif type == BW_DICEROLL_COMMAND_TAG
      blackTotal, blackDiceText, whiteTotal, whiteDiceText = makeDiceRoll(m[BW_FIRST_DICE_INDEX], m[BW_SECOND_DICE_INDEX])
      result = "黒ダイス[#{blackDiceText}]"
      if whiteDiceText
        if m[BW_SECOND_DICE_TAG_INDEX][0] == BW_SECOND_DICE_BLACK_TAG
          return "#{m}：黒ダイス指定(#{BW_SECOND_DICE_BLACK_TAG})は重複できません。"
        end

        result += " 白ダイス[#{whiteDiceText}]"
      end

    else
      return ''
    end

    if blackTotal > whiteTotal
      return "#{result} ＞ 黒#{blackTotal - whiteTotal}"
    elsif blackTotal < whiteTotal
      return "#{result} ＞ 白#{whiteTotal - blackTotal}"
    end

    return "#{result} ＞ 0"
  end

  def makeDiceRoll(firstDice, secondDice)
    secondTotal = 0

    firstTotal, firstDiceText, = roll(firstDice, 6)

    if secondDice
      if secondDice.to_i > 0
        secondTotal, secondDiceText, = roll(secondDice, 6)
      else
        secondDiceText = "0"
      end
    end

    return firstTotal, firstDiceText, secondTotal, secondDiceText
  end
end
