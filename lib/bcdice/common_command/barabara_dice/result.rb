# frozen_string_literal: true

require "bcdice/result"

module BCDice
  module CommonCommand
    module BarabaraDice
      # バラバラロールの結果を表すクラス
      class Result < ::BCDice::Result
        # @return [Array<Array<Integer>>] 出目のグループの配列
        attr_accessor :last_dice_list_list
        # @return [Array<Integer>] すべての出目が格納される配列
        attr_accessor :last_dice_list
        # @return [Integer] 成功数
        attr_accessor :success_num

        # @param text [String, nil] 結果の文章
        def initialize(text = nil)
          super(text)

          @last_dice_list_list = []
          @last_dice_list = []
          @success_num = 0
        end
      end
    end
  end
end
