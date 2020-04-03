# -*- coding: utf-8 -*-

class AddDice
  class Randomizer
    attr_reader :dicebot, :cmp_op, :dice_list, :sides

    def initialize(bcdice, dicebot, cmp_op)
      @bcdice = bcdice
      @dicebot = dicebot
      @cmp_op = cmp_op
      @sides = 0
      @dice_list = []
    end

    def roll(times, sides, critical)
      total = 0
      results_list = []

      loop_count = 0
      queue = [times]
      while !queue.empty?
        times = queue.shift
        val, dice_list = roll_once(times, sides)

        total += val
        results_list.push(dice_list)

        enqueue_reroll(dice_list, queue, times)
        @dicebot.check2dCritical(critical, val, queue, loop_count)
        loop_count += 1
      end

      total = @dicebot.changeDiceValueByDiceText(total, results_list.flatten, @cmp_op, sides)

      text = total.to_s
      results_list.each do |list|
        text += '[' + list.join(',') + ']'
      end

      [total, text]
    end

    private

    def roll_once(times, sides)
      @sides = sides if @sides < sides

      if sides == 66
        return rollD66(dice_wk)
      end

      _, dice_list, = @bcdice.roll(times, sides, @dicebot.sortType & 1)
      dice_list = dice_list.split(",").map(&:to_i)
      @dice_list.concat(dice_list)

      total = dice_list.inject(&:+) || 0
      return [total, dice_list]
    end

    def roll_d66(times)
      dice_list = Array.new(times) { @bcdice.getD66Value() }
      @dice_list.concat(dice_list)

      total = dice_list.inject(&:+)
      return [total, dice_list]
    end

    def double_check?
      if @dicebot.sameDiceRerollCount != 0 # 振り足しありのゲームでダイスが二個以上
        if @dicebot.sameDiceRerollType <= 0 # 判定のみ振り足し
          return true if @cmp_op
        elsif  @dicebot.sameDiceRerollType <= 1 # ダメージのみ振り足し
          debug('ダメージのみ振り足し')
          return true unless @cmp_op
        else # 両方振り足し
          return true
        end
      end

      return false
    end

    def enqueue_reroll(dice_list, dice_queue, roll_times)
      unless double_check? && (roll_times >= 2)
        return
      end

      count_bucket = {}

      dice_list.each do |val|
        count_bucket[val] ||= 0
        count_bucket[val] += 1
      end

      reroll_threshold = @dicebot.sameDiceRerollCount == 1 ? roll_times : @dicebot.sameDiceRerollCount
      count_bucket.each do |_, num|
        if num >= reroll_threshold
          dice_queue.push(num)
        end
      end
    end
  end
end
