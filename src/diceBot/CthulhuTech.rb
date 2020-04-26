# -*- coding: utf-8 -*-
# frozen_string_literal: true

class CthulhuTech < DiceBot
  # ゲームシステムの識別子
  ID = 'CthulhuTech'

  # ゲームシステム名
  NAME = 'クトゥルフテック'

  # ゲームシステム名の読みがな
  SORT_KEY = 'くとうるふてつく'

  # ダイスボットの使い方
  HELP_MESSAGE = <<INFO_MESSAGE_TEXT
・行為判定（test）：nD10+m>=d
　n個のダイスを使用して、修正値m、難易度dで行為判定（test）を行います。
　修正値mは省略可能、複数指定可能（例：+2-4）です。
　成功、失敗、クリティカル、ファンブルを自動判定します。
　例）2D10>=12　4D10+2>=28　5D10+2-4>=32

・対抗判定（contest）：nD10+m>d
　行為判定と同様ですが、防御側有利のため「>=」ではなく「>」を入力します。
　ダメージダイスも表示します。
INFO_MESSAGE_TEXT

  def initialize
    super
    @sendMode = 2
    @sortType = 1
  end

  def check_nD10(total, dice_total, dice_list, cmp_op, target)
    if cmp_op == :>=
      # 通常のテスト
      @isCombatTest = false
      return check_nD10_nomalTest(total, dice_total, dice_list, cmp_op, target)
    elsif cmp_op == :>
      # コンバットテスト
      @isCombatTest = true
      return check_nD10_combatTest(total, dice_total, dice_list, cmp_op, target)
    end
  end

  def check_nD10_nomalTest(total, _dice_total, dice_list, _cmp_op, target)
    if dice_list.count(1) >= (dice_list.size + 1) / 2
      return " ＞ ファンブル"
    end

    isSuccess = false
    if @isCombatTest
      isSuccess = (total > target)
    else
      isSuccess = (total >= target)
    end

    unless isSuccess
      return " ＞ 失敗"
    end

    if total >= target + 10
      return " ＞ クリティカル"
    end

    return " ＞ 成功"
  end

  def check_nD10_combatTest(total, dice_total, dice_list, cmp_op, target)
    result = check_nD10_nomalTest(total, dice_total, dice_list, cmp_op, target)

    case result
    when " ＞ クリティカル", " ＞ 成功"
      result += getDamageDice(total, target)
    end

    return result
  end

  def getDamageDice(total_n, diff)
    debug('getDamageDice total_n, diff', total_n, diff)
    damageDiceCount = ((total_n - diff) / 5.0).ceil
    debug('damageDiceCount', damageDiceCount)
    damageDice = "(#{damageDiceCount}d10)" # ダメージダイスの表示

    return damageDice
  end

  # ダイス目文字列からダイス値を変更する場合の処理
  # クトゥルフ・テックの判定用ダイス計算
  def changeDiceValueByDiceText(dice_now, dice_str, isCheckSuccess, dice_max)
    debug("changeDiceValueByDiceText dice_now, dice_str, isCheckSuccess, dice_max", dice_now, dice_str, isCheckSuccess, dice_max)
    if isCheckSuccess && (dice_max == 10)
      debug('cthulhutech_check(dice_str) called')
      debug('dice_str, dice_now', dice_str, dice_now)
      dice_now = cthulhutech_check(dice_str)
    end
    debug('dice_str, dice_now', dice_str, dice_now)

    return dice_now
  end

  ####################           CthulhuTech         ########################
  # CthulhuTechの判定用ダイス計算
  def cthulhutech_check(dice_str)
    dice_aRR = dice_str.split(/,/).collect { |i| i.to_i }

    dice_num = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
    max_num = 0

    dice_aRR.each do |dice_n|
      dice_num[(dice_n - 1)] += 1

      if dice_n > max_num # 1.個別のダイスの最大値
        max_num = dice_n
      end
    end

    if dice_aRR.length >= 2 # ダイスが2個以上ロールされている
      10.times do |i|
        if dice_num[i] > 1 # 2.同じ出目の合計値
          dice_now = dice_num[i] * (i + 1)
          max_num = dice_now if dice_now > max_num
        end
      end

      if dice_aRR.length >= 3 # ダイスが3個以上ロールされている
        10.times do |i|
          break if  dice_num[i + 2].nil?

          next unless dice_num[i] > 0

          next unless (dice_num[i + 1] > 0) && (dice_num[i + 2] > 0) # 3.連続する出目の合計

          dice_now = i * 3 + 6 # ($i+1) + ($i+2) + ($i+3) = $i*3 + 6

          ((i + 3)...10).step do |i2|
            break if dice_num[i2] == 0

            dice_now += i2 + 1
          end

          max_num = dice_now if dice_now > max_num
        end
      end
    end

    return max_num
  end
end
