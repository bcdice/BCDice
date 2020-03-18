# -*- coding: utf-8 -*-
# frozen_string_literal: true

class Gundog < DiceBot
  # ゲームシステムの識別子
  ID = 'Gundog'

  # ゲームシステム名
  NAME = 'ガンドッグ'

  # ゲームシステム名の読みがな
  SORT_KEY = 'かんとつく'

  # ダイスボットの使い方
  HELP_MESSAGE = <<INFO_MESSAGE_TEXT
失敗、成功、クリティカル、ファンブルとロールの達成値の自動判定を行います。
nD9ロールも対応。
INFO_MESSAGE_TEXT

  # ゲーム別成功度判定(1d100)
  def check_1D100(total_n, _dice_n, signOfInequality, diff, _dice_cnt, _dice_max, _n1, _n_max)
    return '' unless signOfInequality == "<="

    if total_n >= 100
      return " ＞ ファンブル"
    end

    if total_n <= 1
      return " ＞ 絶対成功(達成値1+SL)"
    end

    if total_n <= diff
      dig10 = (total_n / 10).to_i
      dig1 = total_n - dig10 * 10
      dig10 = 0 if dig10 >= 10
      dig1 = 0 if dig1 >= 10 # 条件的にはあり得ない(笑

      if dig1 <= 0
        return " ＞ クリティカル(達成値20+SL)"
      end

      return " ＞ 成功(達成値#{(dig10 + dig1)}+SL)"
    end

    return " ＞ 失敗"
  end

  def isD9
    true
  end
end
