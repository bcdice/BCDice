# frozen_string_literal: true

module BCDice
  module Format
    module_function

    # 比較演算子を文字列表記にする
    #
    # @param op [Symbol]
    # @return [String, nil]
    def comparison_operator(op)
      case op
      when :==
        "="
      when :'!='
        "<>"
      when Symbol
        op.to_s
      end
    end

    # 修正値を文字列表記にする
    #
    # @param number [Integer, nil]
    # @return [String]
    def modifier(number)
      if number.nil?
        nil
      elsif number == 0
        ""
      elsif number > 0
        "+#{number}"
      else
        number.to_s
      end
    end
  end
end
