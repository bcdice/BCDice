# frozen_string_literal: true

require "bcdice/arithmetic/node"

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
            value =
              begin
                @expr.eval(round_type)
              rescue ZeroDivisionError
                "ゼロ除算が発生したため計算できませんでした"
              end

            output =
              if @expr.is_a?(Arithmetic::Node::Parenthesis)
                @expr.output
              else
                "(#{@expr.output})"
              end

            Result.new.tap do |r|
              r.secret = @secret
              r.text = "c#{output} ＞ #{value}"
            end
          end
        end
      end
    end
  end
end
