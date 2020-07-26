# -*- coding: utf-8 -*-
# frozen_string_literal: true

class GoblinSlayer < DiceBot
  # ゲームシステムの識別子
  ID = 'GoblinSlayer'

  # ゲームシステム名
  NAME = 'ゴブリンスレイヤーTRPG'

  # ゲームシステム名の読みがな
  SORT_KEY = 'こふりんすれいやあTRPG'

  # ダイスボットの使い方
  HELP_MESSAGE = <<MESSAGETEXT
・判定　GS(x)>=y
　2d6の判定を行い、達成値を出力します。
　xは基準値、yは目標値です。いずれも省略可能です。
　yが設定されている場合、大成功/成功/失敗/大失敗を自動判定します。
　例）GS>=12　GS>11　GS(10)>14　GS10>=15　GS(10)　GS10　GS

・因果点の設定　SV(n)
　因果点をn点に設定します。
　因果点の設定を行わない場合、因果点は3点に設定されています。
　例）SV(3)　SV8

・因果点の上昇　AV(n)
　因果点をn点上昇させます。nは省略可能です。
　nを省略した場合、因果点を3点上昇させます。
　例）AV　AV(1)　AV1

・因果点の確認　GV
　因果点の現在値を確認します。
　例）GV

・祈念　MCPI(n)
　祈念を行います。
　nは【幸運】などによるボーナスです。この値は省略可能です。
　因果点の現在値を使用して祈念を行い、成功/失敗を自動判定します。
　その後、因果点の現在値を1点上昇させます。
　例）MCPI　MCPI(1)　MCPI2

・命中判定の効力値によるボーナス　DB(n)
　ダメージ効力表による威力へのボーナスを自動で求めます。
　nは命中判定の効力値です。
　例）DB(15)　DB12

※上記コマンドの計算内で割り算を行った場合、小数点以下は切り上げされます。
　ただしダイス出目を割り算した場合、小数点以下は切り捨てされます。
　例）入力：GS(8+3/2)　実行結果：(GS10) ＞ 10 + 3[1,2] ＞ 13
　　　入力：2d6/2    　実行結果：(2D6/2) ＞ 3[1,2]/2 ＞ 1

※因果点が関係するコマンド(SV, AV, GV, MCPI)では、シークレットダイスを使用できません。
MESSAGETEXT

  # 因果点は共有リソースなので因果点関係のコマンドはシークレットダイスを無効化
  setPrefixes(['GS\(\d+\)', 'GS.*', '^SV\d+', '^AV.*', '^GV', '^MCPI.*', 'DB\d+'])

  def initialize
    super
    @fractionType = "roundUp"
    @volition = 3 # 因果点
  end

  def rollDiceCommand(command)
    case command
    when /^GS/i
      return getCheckResult(command)
    when /^SV/i
      return setVolition(command)
    when /^AV/i
      return addVolition(command)
    when /^GV/i
      return getVolition(command)
    when /^MCPI/i
      return murmurChantPrayInvoke(command)
    when /^DB/i
      return damageBonus(command)
    else
      return nil
    end
  end

  def getCheckResult(command)
    m = /^GS([-\d]+)?((>=?)(\d+))?/i.match(command)
    unless m
      return nil
    end

    basis = m[1].to_i # 基準値
    target = m[4].to_i
    without_compare = m[2].nil? || target <= 0
    cmp_op = m[3]

    total, diceText, = roll(2, 6)
    achievement = basis + total # 達成値

    fumble = diceText == "1,1"
    critical = diceText == "6,6"

    result = " ＞ #{resultStr(achievement, target, cmp_op, fumble, critical)}"
    if without_compare && !fumble && !critical
      result = ""
    end
    basis_str = basis == 0 ? "" : "#{basis} + "

    return "(#{command}) ＞ #{basis_str}#{total}[#{diceText}] ＞ #{achievement}#{result}"
  end

  def setVolition(command)
    m = /SV([\d]+)/i.match(command)
    unless m
      return nil
    end

    num = m[1].to_i
    @volition = num
    return "因果点を設定 ＞ 因果点：#{@volition}点"
  end

  def addVolition(command)
    m = /AV([\d]+)?/i.match(command)
    unless m
      return nil
    end

    num = m[1].nil? ? 3 : m[1].to_i
    before = @volition
    @volition += num
    return "因果点を上昇 ＞ 因果点：#{before}点 → #{@volition}点"
  end

  def getVolition(command)
    m = /GV/i.match(command)
    unless m
      return nil
    end

    return "因果点を確認 ＞ 因果点：#{@volition}点"
  end

  def murmurChantPrayInvoke(command)
    if @volition >= 12
      return "因果点が12点以上の場合、因果点は使用できません。"
    end

    m = /MCPI([\d]+)?/i.match(command)
    unless m
      return nil
    end

    luck = m[1].to_i # 幸運
    total, diceText, = roll(2, 6)
    achievement = total + luck

    result = " ＞ #{resultStr(achievement, @volition, '>=', false, false)}"
    luck_str = luck == 0 ? "" : "+#{luck}"

    before = @volition
    @volition += 1
    return "祈念(2d6#{luck_str}) ＞ #{total}[#{diceText}]#{luck_str} ＞ #{achievement}#{result}, 因果点：#{before}点 → #{@volition}点"
  end

  def damageBonus(command)
    m = /DB([\d]+)/i.match(command)
    unless m
      return nil
    end

    num = m[1].to_i
    fmt = "命中判定の効力値によるボーナス ＞ "
    if num >= 40
      total, diceText, = roll(5, 6)
    elsif num >= 30
      total, diceText, = roll(4, 6)
    elsif num >= 25
      total, diceText, = roll(3, 6)
    elsif num >= 20
      total, diceText, = roll(2, 6)
    elsif num >= 15
      total, diceText, = roll(1, 6)
    else
      return fmt + "なし"
    end
    return fmt + "#{total}[#{diceText}] ＞ #{total}"
  end

  # 判定結果の文字列を返す
  # @param [Integer] achievement 達成値
  # @param [Integer] target 目標値
  # @param [String] cmp_op 達成値と目標値を比較する比較演算子
  # @param [Boolean] fumble ファンブルかどうか
  # @param [Boolean] critical クリティカルかどうか
  # @return [String]
  def resultStr(achievement, target, cmp_op, fumble, critical)
    return '大失敗' if fumble
    return '大成功' if critical
    if cmp_op == ">="
      return achievement >= target ? "成功" : "失敗"
    else
      return achievement > target ? "成功" : "失敗"
    end
  end
end
