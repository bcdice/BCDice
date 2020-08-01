# -*- coding: utf-8 -*-
# frozen_string_literal: true

require "utils/normalize"
require "utils/format"
require "utils/command_parser"

class NightWizard < DiceBot
  # ゲームシステムの識別子
  ID = 'NightWizard'

  # ゲームシステム名
  NAME = 'ナイトウィザード The 2nd Edition'

  # ゲームシステム名の読みがな
  SORT_KEY = 'ないとういさあと2'

  # ダイスボットの使い方
  HELP_MESSAGE = <<INFO_MESSAGE_TEXT
・判定用コマンド　(nNW+m@x#y)
　"(基本値)NW(常時および常時に準じる特技等及び状態異常（省略可）)@(クリティカル値)#(ファンブル値)（常時以外の特技等及び味方の支援効果等の影響（省略可））"でロールします。
　Rコマンド(2R6m[n,m]c[x]f[y]>=t tは目標値)に読替されます。
　クリティカル値、ファンブル値が無い場合は1や13などのあり得ない数値を入れてください。
　例）12NW-5@7#2　　1NW　　50nw+5@7,10#2,5　50nw-5+10@7,10#2,5+15+25
INFO_MESSAGE_TEXT

  setPrefixes(['([-+]?\d+)?NW.*', '2R6.*'])

  def initialize
    super
    @sendMode = 2
    @nw_command = "NW"
  end

  def rollDiceCommand(string)
    cmd = parse_nw(string) || parse_2r6(string)
    unless cmd
      return nil
    end

    total, out_str = nw_dice(cmd.active_modify_number, cmd.passive_modify_number, cmd.critical_numbers, cmd.fumble_numbers)
    result =
      if cmd.cmp_op
        total.send(cmd.cmp_op, cmd.target_number) ? "成功" : "失敗"
      end

    sequence = [
      "(#{cmd})",
      out_str,
      result,
    ].compact
    return sequence.join(" ＞ ")
  end

  private

  class Parsed
    attr_accessor :critical_numbers, :fumble_numbers, :prana, :passive_modify_number, :cmp_op, :target_number
  end

  class ParsedNW < Parsed
    attr_accessor :base, :modify_number

    def initialize(command)
      @command = command
    end

    def active_modify_number
      @base + @modify_number
    end

    def to_s
      base = @base.zero? ? nil : @base
      modify_number = Format.modify_number(@modify_number)
      passive_modify_number = Format.modify_number(@passive_modify_number)

      return "#{base}#{@command}#{modify_number}@#{@critical_numbers.join(',')}##{@fumble_numbers.join(',')}#{passive_modify_number}#{@cmp_op}#{@target_number}"
    end
  end

  class Parsed2R6 < Parsed
    attr_accessor :active_modify_number

    def to_s
      "2R6M[#{@active_modify_number},#{@passive_modify_number}]C[#{@critical_numbers.join(',')}]F[#{@fumble_numbers.join(',')}]#{@cmp_op}#{@target_number}"
    end
  end

  def parse_nw(string)
    m = /^([-+]?\d+)?#{@nw_command}((?:[-+]\d+)+)?(?:@(\d+(?:,\d+)*))?(?:#(\d+(?:,\d+)*))?((?:[-+]\d+)+)?(?:([>=]+)(\d+))?$/.match(string)
    unless m
      return nil
    end

    ae = ArithmeticEvaluator.new

    command = ParsedNW.new(@nw_command)
    command.base = m[1].to_i
    command.modify_number = m[2] ? ae.eval(m[2]) : 0
    command.critical_numbers = m[3] ? m[3].split(',').map(&:to_i) : [10]
    command.fumble_numbers = m[4] ? m[4].split(',').map(&:to_i) : [5]
    command.passive_modify_number = m[5] ? ae.eval(m[5]) : 0
    command.cmp_op = Normalize.comparison_operator(m[6])
    command.target_number = m[7] && m[7].to_i

    return command
  end

  def parse_2r6(string)
    m = /^2R6m\[([-+]?\d+(?:[-+]\d+)*)(?:,([-+]?\d+(?:[-+]\d+)*))?\](?:c\[(\d+(?:,\d+)*)\])?(?:f\[(\d+(?:,\d+)*)\])?(?:([>=]+)(\d+))?/i.match(string)
    unless m
      return nil
    end

    ae = ArithmeticEvaluator.new

    command = Parsed2R6.new
    command.active_modify_number = ae.eval(m[1])
    command.passive_modify_number = m[2] ? ae.eval(m[2]) : 0
    command.critical_numbers = m[3] ? m[3].split(',').map(&:to_i) : [10]
    command.fumble_numbers = m[4] ? m[4].split(',').map(&:to_i) : [5]
    command.cmp_op = Normalize.comparison_operator(m[5])
    command.target_number = m[6] && m[6].to_i

    return command
  end

  def nw_dice(base, modify, critical_numbers, fumble_numbers)
    @criticalValues = critical_numbers
    @fumbleValues = fumble_numbers
    total = 0
    output = ""

    debug('@criticalValues', @criticalValues)
    debug('@fumbleValues', @fumbleValues)

    dice_n, dice_str, = roll(2, 6, 0)

    total = 0

    if @fumbleValues.include?(dice_n)
      fumble_text, total = getFumbleTextAndTotal(base, modify, dice_str)
      output = "#{fumble_text} ＞ ファンブル ＞ #{total}"
    else
      total = base + modify
      total, output = checkCritical(total, dice_str, dice_n)
    end

    return total, output
  end

  def getFumbleTextAndTotal(base, _modify, dice_str)
    total = base
    total += -10
    text = "#{base}-10[#{dice_str}]"
    return text, total
  end

  def checkCritical(total, dice_str, dice_n)
    debug("addRollWhenCritical begin total, dice_str", total, dice_str)
    output = total.to_s

    criticalText = ""
    criticalValue = getCriticalValue(dice_n)

    while criticalValue
      total += 10
      output += "+10[#{dice_str}]"

      criticalText = "＞ クリティカル "
      dice_n, dice_str, = roll(2, 6, 0)

      criticalValue = getCriticalValue(dice_n)
      debug("criticalValue", criticalValue)
    end

    total += dice_n
    output += "+#{dice_n}[#{dice_str}] #{criticalText}＞ #{total}"

    return total, output
  end

  def getCriticalValue(dice_n)
    return @criticalValues.include?(dice_n)
  end
end
