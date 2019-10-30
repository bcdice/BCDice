# -*- coding: utf-8 -*-

# 表を表すクラス
class Table
  # @param [String] name 表の名前
  # @param [String] type 表の振り方の種類 '1D6'など
  # @param [Array] table 表本体
  def initialize(name, type, table)
    @name = name
    @table = table.freeze

    if (m = /(\d+)D(\d+)/i.match(type))
      @type = :d
      @times = m[1].to_i
      @sides = m[2].to_i
    else
      raise ArgumentError, "Unexpected table type: #{type}"
    end
  end

  # 表を振る
  # @param [BCDice] bcdice
  # @return [String | nil] 結果
  def roll(bcdice)
    case @type
    when :d
      roll_d(bcdice)
    end
  end

  private

  # 加算ダイスで表を振る
  # @param [BCDice] bcdice
  # @return [String] 結果
  def roll_d(bcdice)
    value, = bcdice.roll(@times, @sides)
    index = value - @times

    return "#{@name}(#{value}) ＞ #{@table[index]}"
  end
end
