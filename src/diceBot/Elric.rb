# -*- coding: utf-8 -*-
# frozen_string_literal: true

class Elric < DiceBot
  # ゲームシステムの識別子
  ID = 'Elric!'

  # ゲームシステム名
  NAME = 'エルリック！'

  # ゲームシステム名の読みがな
  SORT_KEY = 'えるりつく'

  # ダイスボットの使い方
  HELP_MESSAGE = "貫通、クリティカル、ファンブルの自動判定を行います。\n"

  # ゲーム別成功度判定(1d100)
  def check_1D100(total_n, _dice_n, signOfInequality, diff, _dice_cnt, _dice_max, _n1, _n_max)
    return '' unless signOfInequality == "<="

    # 1は常に貫通
    return " ＞ 貫通" if total_n <= 1
    # 100は常に致命的失敗
    return " ＞ 致命的失敗" if total_n >= 100

    return " ＞ 決定的成功" if total_n <= (diff / 5 + 0.9)
    return " ＞ 成功" if total_n <= diff
    return " ＞ 致命的失敗" if (total_n >= 99) && (diff < 100)

    return " ＞ 失敗"
  end
end
