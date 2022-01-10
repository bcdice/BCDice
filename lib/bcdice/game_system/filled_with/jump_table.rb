# frozen_string_literal: true

module BCDice
  module GameSystem
    class FilledWith < Base
      module JumpTable
        # 表を振った結果を独自の書式で整形する
        # @param table_name [String] 表の名前
        # @param number [String] 出目の文字列
        # @param result [String] 結果の文章
        # @return [String]
        def format_table_roll_result(table_name, number, result)
          "#{table_name}(#{number}):#{result}"
        end

        # ジャンプする項目を含む表を振る
        # @param table_name [String] 表の名前
        # @param table [DiceTable::RangeTable] 振る対象の表
        # @return [Result]
        def roll_jump_table(table_name, table)
          # 出目の配列
          values = []

          loop do
            roll_result = table.roll(@randomizer)
            values.concat(roll_result.values)

            content = roll_result.content
            case content
            when String
              return Result.new(format_table_roll_result(table_name, values.join, content))
            when Proc
              # 次の繰り返しで指定された表を参照する
              table = content.call
            else
              raise TypeError
            end
          end
        end
      end
    end
  end
end
