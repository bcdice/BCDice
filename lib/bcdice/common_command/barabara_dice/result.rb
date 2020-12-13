# frozen_string_literal: true

require "bcdice/result"

module BCDice
  module CommonCommand
    module BarabaraDice
      # バラバラロールの結果を表すクラス
      class Result < ::BCDice::Result
        # @return [Integer] 成功数
        attr_accessor :success_num

        # @param text [String, nil] 結果の文章
        def initialize(text = nil)
          super(text)

          @success_num = 0
        end
      end
    end
  end
end
