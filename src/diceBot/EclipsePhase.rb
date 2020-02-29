# -*- coding: utf-8 -*-
# frozen_string_literal: true

class EclipsePhase < DiceBot
  # ゲームシステムの識別子
  ID = 'EclipsePhase'

  # ゲームシステム名
  NAME = 'エクリプス・フェイズ'

  # ダイスボットの使い方
  HELP_MESSAGE =
    '1D100<=m 方式の判定で成否、クリティカル・ファンブルを自動判定'

  def check_1D100(total_n, _dice_n, signOfInequality, diff, _dice_cnt, _dice_max, _n1, _n_max)\
    return '' unless signOfInequality == '<='

    diceValue = total_n % 100 # 出目00は100ではなく00とする
    dice_ten_place = diceValue / 10
    dice_one_place = diceValue % 10

    debug("total_n", total_n)
    debug("dice_ten_place, dice_one_place", dice_ten_place, dice_one_place)

    if dice_ten_place == dice_one_place
      return ' ＞ 決定的失敗' if diceValue == 99
      return ' ＞ 00 ＞ 決定的成功' if diceValue == 0
      return ' ＞ 決定的成功' if total_n <= diff

      return ' ＞ 決定的失敗'
    end

    diff_threshold = 30

    if total_n <= diff
      return ' ＞ エクセレント' if total_n >= diff_threshold

      return ' ＞ 成功'
    else
      return ' ＞ シビア' if (total_n - diff) >= diff_threshold

      return ' ＞ 失敗'
    end
  end
end
