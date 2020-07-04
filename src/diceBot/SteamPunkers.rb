# -*- coding: utf-8 -*-

class SteamPunkers < DiceBot
  ID = 'SteamPunkers'.freeze
  NAME = 'スチームパンカーズ'.freeze
  SORT_KEY = 'すちいむはんかあす'.freeze

  HELP_MESSAGE = <<MESSAGETEXT.freeze
SP(判定ダイス数)>=(目標値)
SP4>=3のように入力し、5が出たらヒット数1，6が出たらヒット数2として成功数を数えます。
≪スチームパンク！≫による振り直しのため、出力には失敗ダイス数を表示します。
例：(SP4>=3) ＞ [3,4,1,6] ＞ 成功数:2 ＞ 失敗 (失敗数:3)
MESSAGETEXT

  setPrefixes(['SP.*'])

  def rollDiceCommand(command)
    m = /^SP(\d+)(?:>=(\d+))?$/i.match(command)
    unless m
      return nil
    end

    dice_count = m[1].to_i
    target_number = m[2] && m[2].to_i

    _, dice_list_text, = roll(dice_count, 6)
    dice_list = dice_list_text.split(',').map(&:to_i)

    successes = dice_list.count(6) * 2 + dice_list.count(5)
    failures = dice_list.count { |x| x <= 4 }

    result =
      if dice_list.all? { |x| x == 1 }
        "ファンブル"
      elsif target_number
        successes >= target_number ? "成功" : "失敗"
      end

    sequence = [
      "(#{command})",
      "[#{dice_list_text}]",
      "成功数:#{successes}, 失敗数:#{failures}",
      result
    ].compact

    return sequence.join(" ＞ ")
  end
end
