# frozen_string_literal: true

module BCDice
  module Deprecated
    # 2D6などの特定の加算ダイスの結果をゲームシステムごとにカスタマイズするための
    # @deprecate Base#result_2d6 等を利用してください
    module Checker
      private

      # @param total [Integer] コマンド合計値
      # @param rand_results [Array<CommonCommand::AddDice::Randomizer::RandResult>] ダイスの一覧
      # @param cmp_op [Symbol] 比較演算子
      # @param target [Integer, String] 目標値の整数か'?'
      # @return [Result, nil]
      def check_result_legacy(total, rand_results, cmp_op, target)
        sides_list = rand_results.map(&:sides)
        value_list = rand_results.map(&:value)
        dice_total = value_list.sum()

        ret =
          case sides_list
          when [100]
            check_1D100(total, dice_total, cmp_op, target)
          when [20]
            check_1D20(total, dice_total, cmp_op, target)
          when [6, 6]
            check_2D6(total, dice_total, value_list, cmp_op, target)
          end

        return Result.new(ret.delete_prefix(" ＞ ")) unless ret.nil? || ret.empty?

        ret =
          case sides_list.uniq
          when [10]
            check_nD10(total, dice_total, value_list, cmp_op, target)
          when [6]
            check_nD6(total, dice_total, value_list, cmp_op, target)
          end

        return Result.new(ret.delete_prefix(" ＞ ")) unless ret.nil? || ret.empty?

        return nil
      end

      # @param total [Integer]
      # @param dice_total [Integer]
      # @param cmp_op [Symbol]
      # @param target
      # @return [String, nil]
      # @deprecate Base#result_1d100 を使ってください
      def check_1D100(total, dice_total, cmp_op, target); end

      # @param (see #check_1D100)
      # @return [String, nil]
      # @deprecate Base#result_1d20 を使ってください
      def check_1D20(total, dice_total, cmp_op, target); end

      # @param total [Integer]
      # @param dice_total [Integer]
      # @param dice_list [Array<Integer>]
      # @param cmp_op [Symbol]
      # @param target
      # @return [String, nil]
      # @deprecate Base#result_nd10 を使ってください
      def check_nD10(total, dice_total, dice_list, cmp_op, target); end

      # @param (see #check_nD10)
      # @return [String, nil]
      # @deprecate Base#result_2d6 を使ってください
      def check_2D6(total, dice_total, dice_list, cmp_op, target); end

      # @param (see #check_nD10)
      # @return [String, nil]
      # @deprecate Base#result_nd6 を使ってください
      def check_nD6(total, dice_total, dice_list, cmp_op, target); end
    end
  end
end
