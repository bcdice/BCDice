# -*- coding: utf-8 -*-

require 'utils/ArithmeticEvaluator'
require 'utils/normalize'
require 'utils/format'
require 'utils/modifier_formatter'

# 上方無限ロール
class UpperDice
  include ModifierFormatter

  def initialize(bcdice, diceBot)
    @bcdice = bcdice
    @diceBot = diceBot
    @nick_e = @bcdice.nick_e
  end

  # 上方無限ロールを実行する
  #
  # @param string [String]
  # @return [String]
  def rollDice(string)
    string = string.gsub(/-\d+U\d+/i, '') # 上方無限の引き算しようとしてる部分をカット

    unless (m = /^S?(\d+U\d+(?:\+\d+U\d+)*)(?:\[(\d+)\])?([\+\-\d]*)(?:([<>=]+)(\d+))?(?:@(\d+))?/i.match(string))
      return '1'
    end

    @command = m[1]
    @cmp_op = Normalize.comparison_operator(m[4])
    @target_number = @cmp_op ? m[5].to_i : nil
    @reroll_threshold = reroll_threshold(m[2] || m[6])

    @modify_number = m[3] ? ArithmeticEvaluator.new.eval(m[3], @diceBot.fractionType.to_sym) : 0

    if @reroll_threshold <= 1
      return "#{@nick_e}: (#{expr()}) ＞ 無限ロールの条件がまちがっています"
    end

    roll_list = []
    @command.split('+').each do |u|
      times, sides = u.split("U", 2).map(&:to_i)
      roll_list.concat(roll(times, sides))
    end

    result =
      if @cmp_op
        success_count = roll_list.count do |e|
          x = e[:sum] + @modify_number
          if @cmp_op == :!=
            # Ruby 1.8のケア
            x != @target_number
          else
            x.send(@cmp_op, @target_number)
          end
        end
        "成功数#{success_count}"
      else
        sum_list = roll_list.map { |e| e[:sum] }
        total = sum_list.inject(0, :+) + @modify_number
        max = sum_list.map { |i| i + @modify_number }.max
        "#{max}/#{total}(最大/合計)"
      end

    sequence = [
      "#{@nick_e}: (#{expr()})",
      dice_text(roll_list) + format_modifier(@modify_number),
      result
    ]

    return sequence.join(" ＞ ")
  end

  private

  # ダイスロールし、ダイスボットのソート設定に応じてソートする
  #
  # @param times [Integer] ダイスの個数
  # @param sides [Integer] ダイスの面数
  # @return [Array<Hash>]
  def roll(times, sides)
    if @diceBot.upplerRollThreshold == "Max"
      @reroll_threshold = sides
    end

    ret = Array.new(times) { roll_ones(sides) }
    ret.map! { |e| {:sum => e.inject(0, :+), :list => e} }
    if @diceBot.sortType & 2 != 0
      ret.sort_by! { |e| e[:sum] }
    end

    return ret
  end

  # 一つだけダイスロールする
  #
  # @param sides [Integer] ダイスの面数
  # @return [Array<Integer>]
  def roll_ones(sides)
    dice_list = []

    loop do
      value, = @bcdice.roll(1, sides)
      dice_list.push(value)
      break if value < @reroll_threshold
    end

    return dice_list
  end

  # ダイスロールの結果を文字列に変換する
  # 振り足しがなければその数値、振り足しがあれば合計と各ダイスの出目を出力する
  #
  # @param roll_list [Array<Hash>]
  # @return [String]
  def dice_text(roll_list)
    roll_list.map do |e|
      if e[:list].size == 1
        e[:sum]
      else
        "#{e[:sum]}[#{e[:list].join(',')}]"
      end
    end.join(",")
  end

  # 振り足しの閾値を得る
  #
  # @param target [String]
  # @return [Integer]
  def reroll_threshold(target)
    if target
      target.to_i
    elsif @diceBot.upplerRollThreshold == "Max"
      2
    else
      @diceBot.upplerRollThreshold
    end
  end

  # パース済みのコマンドを文字列で表示する
  #
  # @return [String]
  def expr
    "#{@command}[#{@reroll_threshold}]#{format_modifier(@modify_number)}#{Format.comparison_operator(@cmp_op)}#{@target_number}"
  end
end
