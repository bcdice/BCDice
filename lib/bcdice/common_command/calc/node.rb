# frozen_string_literal: true

module BCDice
  module CommonCommand
    module Calc
      module Node
        class Command
          def initialize(secret:, expr:)
            @secret = secret
            @expr = expr
          end

          def eval(round_type)
            value = @expr.eval(round_type)

            Result.new.tap do |r|
              r.secret = @secret
              r.text = "計算結果 ＞ #{value}"
            end
          end
        end
      end
    end
  end
end
