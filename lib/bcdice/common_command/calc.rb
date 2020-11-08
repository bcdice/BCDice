module BCDice
  module CommonCommand
    module Calc
      PREFIX_PATTERN = /C/.freeze

      class << self
        def eval(command, game_system, _randomizer)
          m = %r{^(S)?C([\+\-\*/\d\(\)]+)$}i.match(command)
          return nil unless m

          expr = ArithmeticEvaluator.new(m[2], round_type: game_system.round_type)
          value = expr.eval()
          if expr.error?
            return nil
          end

          Result.new.tap do |r|
            r.secret = !m[1].nil?
            r.text = "計算結果 ＞ #{value}"
          end
        end
      end
    end
  end
end
