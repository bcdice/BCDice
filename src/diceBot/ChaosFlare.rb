# -*- coding: utf-8 -*-
# frozen_string_literal: true

class ChaosFlare < DiceBot
  # ゲームシステムの識別子
  ID = 'Chaos Flare'
  # ゲームシステム名
  NAME = 'カオスフレア'

  # ゲームシステム名の読みがな
  SORT_KEY = 'かおすふれあ'

  # ダイスボットの使い方
  HELP_MESSAGE = <<INFO_MESSAGE_TEXT
[ダイスの数]CF[修正値][@クリティカル値][#ファンブル値][修正値][>=目標値]
　　(例1) CF (2d6で普通に判定)
　　(例2) CF+10@10 (+10の修正値で、クリティカル値10で判定)
　　(例3) CF+10#3 (+10の修正値で、ファンブル値3で判定)
　　(例4) CF+10>=10 (+10の修正値で、目標値を指定。差分値が出ます)
　　(例5) 3CF (ダイス3つで判定)
　　(例6) 3CF+10@10#3>=10 (ダイス3つ、修正値10、クリティカル値10、ファンブル値3、目標値10で判定)
　　(例7) CF+5-3#3+3>=10 (修正値は計算できます。修正値は、ファンブル値の後、目標値の前の場所にも書けます)

各種表
　　FT：因縁表
INFO_MESSAGE_TEXT

  setPrefixes(['\d*CF.*', 'FT\d*'])

  # ダイスボット設定後に行う処理
  # @return [void]
  def postSet
    if bcdice
      bcdice.cardTrader.set2Decks2Jokers
      # 手札の他のカード置き場
      bcdice.cardTrader.card_place = 0
      # 場札のタップ処理の必要があるか？
      bcdice.cardTrader.canTapCard = false
    end
  end

  # ゲーム別成功度判定(2D6)。以前の処理をそのまま残しています。
  def check_2D6(total, dice_total, _dice_list, cmp_op, target)
    output = ''

    if dice_total <= 2
      total -= 20
      output = " ＞ ファンブル(-20)"
    end

    unless cmp_op == :>=
      return output
    end

    if total >= target
      output += " ＞ 成功"
      if total > target
        output += " ＞ 差分値#{total - target}"
      end
    else
      output += " ＞ 失敗 ＞ 差分値#{total - target}"
    end

    return output
  end

  # コマンドを分岐する場所。
  def rollDiceCommand(command)
    case command
      when /FT\d*/i
        return getFate(command)
    end

    return getRollResult(command)
  end

  # 因縁表を振る場所。
  def getFate(command)
    debug("getFate", "begin")
    matched = /FT(\d*)/i.match(command)
    debug("matched", matched)

    if matched[1] == ""
      #ランダムに振る処理。
      first_die = roll(1,6)[0]
      first_index = first_die
      second_die = roll(1,6)[0]
      second_index = ((second_die) / 2).ceil - 1
      return "(#{first_die},#{second_die}) → #{FATE_TABLE[first_index][second_index]}"
    else
      #出目を指定して因縁表を振る処理の場所です。気力のある方お願いします。腐れ縁と任意はすでにtableに入っています。
      return ""
    end
  end

  #カオスフレア用の判定を処理する場所。べた書きです。
  def getRollResult(command)
    #まずはコマンドが合っているか。
    roll_regex =  /(?:(\d+))?CF((?:[+-]\d+)*)(?:@(\d+))?(?:#(\d+))?((?:[+-]\d+)*)(?:>=(\d+))?/i
    matched = roll_regex.match(command)
    debug("match", matched)
    unless matched
      return nil
    end

    #指定された各種数字を取得。
    dice_num = 2
    if matched[1] != nil
      dice_num = matched[1].to_i
    end

    critical = 12
    if matched[3] != nil
      critical = matched[3].to_i
    end

    fumble = 2
    if matched[4] != nil
      fumble = matched[4].to_i
    end
    debug("fumble", fumble)

    #素のダイスで振る。
    dice_result = roll(dice_num, 6)
    debug("result", dice_result)

    dice_sum = dice_result[0]
    debug("sum", dice_sum)

    #クリティカルなら30に、ファンブルなら-20に。
    critical_flag = false
    fumble_flag = false
    if dice_sum >= critical
      dice_sum = 30
      critical_flag = true
    elsif dice_sum <= fumble
      dice_sum = -20
      fumble_flag = true
    end

    #修正値を計算して出目に加える。evalで手抜きです。
    adjust = 0
    if matched[2] != ""
      adjust += eval(matched[2])
    end
    if matched[5] != ""
      adjust += eval(matched[5])
    end

    dice_sum = dice_sum + adjust
    debug("sum", dice_sum)

    #必要なら差分値を出す。
    diff = 0
    if matched[6] != nil
      diff = dice_sum
      if dice_sum < 0
        diff = 0
      end
      diff -= matched[6].to_i
    end

    #結果の文字列を作る。
    result_string = "(#{dice_result[1]}) → #{dice_sum}"
    if dice_sum < 0
      result_string += "(0)"
    end
    if critical_flag
      result_string += " (クリティカル)"
    end
    if fumble_flag
      result_string += " (ファンブル)"
    end
    if matched[6] != nil
      result_string += " [差分値：#{diff}]"
    end

    #お疲れ様でした。
    return result_string
  end


  #表を振るのに使う定数的なやつ。
  FATE_TABLE = [
    ["腐れ縁"],
    ["純愛", "親近感", "庇護"],
    ["信頼", "感服", "共感"],
    ["友情", "尊敬", "慕情"],
    ["好敵手", "期待", "借り"],
    ["興味", "憎悪", "悲しみ"],
    ["恐怖", "執着", "利用"],
    ["任意"]
  ].freeze

end
