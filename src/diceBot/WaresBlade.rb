# -*- coding: utf-8 -*-
# frozen_string_literal: true

class WaresBlade < DiceBot
  # ゲームシステムの識別子
  ID = 'WaresBlade'

  # ゲームシステム名
  NAME = 'ワースブレイド'

  # ゲームシステム名の読みがな
  SORT_KEY = 'わあすふれいと'

  # ダイスボットの使い方
  HELP_MESSAGE = "nD10>=m 方式の判定で成否、完全成功、完全失敗を自動判定します。\n"

  def check_nD10(total_n, dice_n, signOfInequality, diff, dice_cnt, _dice_max, _n1, _n_max) # ゲーム別成功度判定(nD10)
    return '' unless signOfInequality == '>='

    if dice_n == 10 * dice_cnt

      return ' ＞ 完全成功'

    elsif dice_n == 1 * dice_cnt

      return ' ＞ 絶対失敗'

    else

      if total_n >= diff
        return ' ＞ 成功'
      else
        return ' ＞ 失敗'
      end

    end
  end
end
