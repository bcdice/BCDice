# frozen_string_literal: true

module BCDice
  module GameSystem
    class Fiasco < Base
      # ゲームシステムの識別子
      ID = 'Fiasco'

      # ゲームシステム名
      NAME = 'フィアスコ'

      # ゲームシステム名の読みがな
      SORT_KEY = 'ふいあすこ'

      # ダイスボットの使い方
      HELP_MESSAGE = <<INFO_MESSAGE_TEXT
  ・判定コマンド(FSx, WxBx)
    相関図・転落要素用(FSx)：相関図や転落要素のためにx個ダイスを振り、出目ごとに分類する
    黒白差分判定用(WxBx)  ：転落、残響のために白ダイス(W指定)と黒ダイス(B指定)で差分を求める
      ※ WとBは片方指定(Bx, Wx)、入替指定(WxBx,BxWx)可能

INFO_MESSAGE_TEXT

      COMMAND_TYPE_INDEX = 1

      START_DICE_INDEX = 2

      BW_FIRST_DICE_INDEX = 2
      BW_SECOND_DICE_INDEX = 5
      BW_SECOND_DICE_TAG_INDEX = 4

      START_COMMAND_TAG = "FS"
      W_DICEROLL_COMMAND_TAG = "W"
      B_DICEROLL_COMMAND_TAG = "B"

      register_prefix(['(FS|[WB])(\d+).*'])

      def eval_game_system_specific_command(command)
        m = /\A(FS|[WB])(\d+)(([WB])(\d+))?/.match(command)
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
        dice = m[START_DICE_INDEX].to_i

        dice_list = @randomizer.roll_barabara(dice, 6)

        diceList = [0, 0, 0, 0, 0, 0]
        dice_list.each do |takeDice|
          diceList[takeDice - 1] += 1
        end

        return "１ => #{diceList[0]}個 ２ => #{diceList[1]}個 ３ => #{diceList[2]}個 ４ => #{diceList[3]}個 ５ => #{diceList[4]}個 ６ => #{diceList[5]}個"
      end

      def makeWhiteBlackDiceRoll(type, m)
        if type == W_DICEROLL_COMMAND_TAG
          whiteTotal, whiteDiceText, blackTotal, blackDiceText = makeArgsDiceRoll(m[BW_FIRST_DICE_INDEX], m[BW_SECOND_DICE_INDEX])
          result = "白#{whiteTotal}[#{whiteDiceText}]"
          if blackDiceText
            if m[BW_SECOND_DICE_TAG_INDEX] == W_DICEROLL_COMMAND_TAG
              return "#{m}：白指定(#{W_DICEROLL_COMMAND_TAG})は重複できません。"
            end

            result += " 黒#{blackTotal}[#{blackDiceText}]"
          end
        elsif type == B_DICEROLL_COMMAND_TAG
          blackTotal, blackDiceText, whiteTotal, whiteDiceText = makeArgsDiceRoll(m[BW_FIRST_DICE_INDEX], m[BW_SECOND_DICE_INDEX])
          result = "黒#{blackTotal}[#{blackDiceText}]"
          if whiteDiceText
            if m[BW_SECOND_DICE_TAG_INDEX] == B_DICEROLL_COMMAND_TAG
              return "#{m}：黒指定(#{B_DICEROLL_COMMAND_TAG})は重複できません。"
            end

            result += " 白#{whiteTotal}[#{whiteDiceText}]"
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

      def makeArgsDiceRoll(firstDice, secondDice)
        firstDice = firstDice.to_i
        secondDice = secondDice&.to_i

        secondTotal = 0

        dice_list = @randomizer.roll_barabara(firstDice, 6)
        firstTotal = dice_list.sum()
        firstDiceText = dice_list.join(",")

        if secondDice
          if secondDice > 0
            dice_list = @randomizer.roll_barabara(secondDice, 6)
            secondTotal = dice_list.sum()
            secondDiceText = dice_list.join(",")
          else
            secondDiceText = "0"
          end
        end

        return firstTotal, firstDiceText, secondTotal, secondDiceText
      end
    end
  end
end
