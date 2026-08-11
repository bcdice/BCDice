# frozen_string_literal: true

module BCDice
  module DiceTable
    # 表を連続して振る際にテキストを付加する
    class ChainWithText
      # 次のテーブルに遷移する前に表示するテキスト
      # @return [String]
      attr_reader :text

      # 次のテーブル
      # @return [#roll]
      attr_reader :table

      # @param text [String]
      # @param table [#roll]
      # @return [ChainWithText]
      def initialize(text, table)
        @text = text
        @table = table
      end
    end
  end
end
