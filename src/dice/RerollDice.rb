# -*- coding: utf-8 -*-

require "utils/normalize"
require "utils/format"

# 個数振り足しダイス
class RerollDice
  def initialize(bcdice, diceBot)
    @bcdice = bcdice
    @diceBot = diceBot
    @nick_e = @bcdice.nick_e
  end

  def rollDice(string)
    output = rollDiceCatched(string)

    return "#{@nick_e}: #{output}"
  end

  def rollDiceCatched(string)
    debug('RerollDice.rollDice string', string)
    string = string.strip

    m = /^S?(\d+R\d+(?:\+\d+R\d+)*)(?:\[(\d+)\])?(?:([<>=]+)(\d+))?(?:@(\d+))?$/.match(string)
    unless m
      debug("is invaild rdice", string)
      return '1'
    end

    notation = m[1]
    cmp_op = Normalize.comparison_operator(m[3])
    target_number = cmp_op ? m[4].to_i : nil
    unless cmp_op
      cmp_op, target_number = target_from_default()
    end

    reroll_cmp_op = cmp_op || :>=
    reroll_threshold = decide_reroll_threthold(m[2] || m[5], target_number)

    unless reroll_threshold
      return "#{string} ＞ #{msg_invalid_reroll_number}"
    end

    dice_queue = []
    notation.split("+").each do |xRn|
      x, n = xRn.split("R").map(&:to_i)
      unless valid_reroll_rule?(n, cmp_op, target_number)
        return "#{string} ＞ #{msg_invalid_reroll_number}"
      end

      dice_queue.push([x, n, 0])
    end

    success_count = 0
    dice_str_list = []
    dice_cnt_total = 0
    one_count = 0
    loop_count = 0

    dice_total_count = 0

    while !dice_queue.empty? && @diceBot.should_reroll?(loop_count)
      # xRn
      x, n, depth = dice_queue.shift
      loop_count += 1
      dice_total_count += x

      dice_list = roll_(x, n)
      success_count += dice_list.count() { |val| val.send(cmp_op, target_number) } if cmp_op
      reroll_count = dice_list.count() { |val| val.send(reroll_cmp_op, reroll_threshold) }

      dice_str_list.push(dice_list.join(","))

      if depth.zero?
        one_count += dice_list.count(1)
      end

      if reroll_count > 0
        dice_queue.push([reroll_count, n, depth + 1])
      end
    end

    cmp_op_text = Format.comparison_operator(cmp_op)
    grich_text = @diceBot.getGrichText(one_count, dice_total_count, success_count)

    sequence = [
      "(#{notation}[#{reroll_threshold}]#{cmp_op_text}#{target_number})",
      dice_str_list.join(" + "),
      "成功数#{success_count}",
      trim_prefix(" ＞ ", grich_text),
    ].compact

    return sequence.join(" ＞ ")
  end

  private

  # @return [Array<(Symbol, Integer)>]
  # @return [Array<(nil, nil)>]
  def target_from_default
    m = /^([<>=]+)(\d+)$/.match(@diceBot.defaultSuccessTarget)
    unless m
      return nil, nil
    end

    cmp_op = Normalize.comparison_operator(m[1])
    target_number = cmp_op ? m[2].to_i : nil
    return cmp_op, target_number
  end

  # @param captured_threthold [String, nil]
  # @param target_number [Integer, nil]
  # @return [Integer]
  # @return [nil]
  def decide_reroll_threthold(captured_threthold, target_number)
    if captured_threthold
      captured_threthold.to_i
    elsif @diceBot.rerollNumber != 0
      @diceBot.rerollNumber
    else
      target_number
    end
  end

  def msg_invalid_reroll_number()
    "条件が間違っています。2R6>=5 あるいは 2R6[5] のように振り足し目標値を指定してください。"
  end

  # @param sides [Integer]
  # @param cmp_op [Symbol]
  # @param reroll_threshold [Integer]
  # @return [Boolean]
  def valid_reroll_rule?(sides, cmp_op, reroll_threshold) # 振り足しロールの条件確認
    case cmp_op
    when :<=
      reroll_threshold < sides
    when :<
      reroll_threshold <= sides
    when :>=
      reroll_threshold > 1
    when :>
      reroll_threshold >= 1
    when :'!='
      (1..sides).include?(reroll_threshold)
    else
      true
    end
  end

  def roll_(times, sides)
    _, dice_list, = @bcdice.roll(times, sides, (@diceBot.sortType & 2))
    dice_list.split(",").map(&:to_i)
  end

  def trim_prefix(prefix, string)
    if string.start_with?(prefix)
      string = string[prefix.size..-1]
    end

    if string.size.zero?
      nil
    else
      string
    end
  end
end
