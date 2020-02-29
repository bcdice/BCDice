# -*- coding: utf-8 -*-
# frozen_string_literal: true

class Gorilla < DiceBot
  # ゲームシステムの識別子
  ID = 'Gorilla'

  # ゲームシステム名
  NAME = 'ゴリラTRPG'

  # ゲームシステム名の読みがな
  SORT_KEY = 'こりらTRPG'

  # ダイスボットの使い方
  HELP_MESSAGE = <<MESSAGETEXT
2D6ロール時のゴリティカル自動判定を行います。

G = 2D6のショートカット

例) G>=7 : 2D6して7以上なら成功
MESSAGETEXT

  setPrefixes(['G.*'])

  def changeText(string)
    string = string.gsub(/^(S)?G/i) { "#{Regexp.last_match(1)}2D6" }
    return string
  end

  def check_2D6(totalValue, dice_n, signOfInequality, diff, _dice_cnt, _dice_max, _n1, _n_max) # ゲーム別成功度判定(2D6)
    if dice_n == 10
      diceList = getDiceList()
      if diceList[0] == 5
        # 2d6の合計が10で片方5ならもう片方も5であろうという手抜き判定
        return " ＞ ゴリティカル（自動的成功）"
      end
    end
    # 2014.02.24 余り無いと思うが'>'に対応できてなかったので追記
    if signOfInequality == '>='
      if totalValue >= diff
        return " ＞ 成功"
      end
    end
    if signOfInequality == '>'
      if totalValue > diff
        return " ＞ 成功"
      end
    end
    return " ＞ 失敗"
  end
end
