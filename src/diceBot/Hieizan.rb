# -*- coding: utf-8 -*-
# frozen_string_literal: true

class Hieizan < DiceBot
  # ゲームシステムの識別子
  ID = 'Hieizan'

  # ゲームシステム名
  NAME = '比叡山炎上'

  # ゲームシステム名の読みがな
  SORT_KEY = 'ひえいさんえんしよう'

  # ダイスボットの使い方
  HELP_MESSAGE = "大成功、自動成功、失敗、自動失敗、大失敗の自動判定を行います。\n"

  # ゲーム別成功度判定(1d100)
  def check_1D100(total_n, _dice_n, _signOfInequality, diff, _dice_cnt, _dice_max, _n1, _n_max)
    if total_n <= 1 # 1は自動成功
      if total_n <= (diff / 5)
        return " ＞ 大成功" # 大成功 > 自動成功
      end

      return " ＞ 自動成功"
    end

    if total_n >= 100
      return " ＞ 大失敗" # 00は大失敗(大失敗は自動失敗でもある)
    end

    if total_n >= 96
      return " ＞ 自動失敗" # 96-00は自動失敗
    end

    if total_n <= diff

      if total_n <= (diff / 5)
        return " ＞ 大成功" # 目標値の1/5以下は大成功
      end

      return " ＞ 成功"
    end

    return " ＞ 失敗"
  end
end
