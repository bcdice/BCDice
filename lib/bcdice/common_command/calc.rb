module BCDice
  module CommonCommand
    class Calc
      # @param command [String]
      # @param _randomizer [Randomizer]
      # @param game_system [Base]
      def initialize(command, _randomizer, game_system)
        @command = command
        @game_system = game_system

        @is_secret = false
      end

      # @return [Boolean]
      def secret?
        @is_secret
      end

      # @return [String, nil]
      def eval
        m = %r{^(S)?C([\+\-\*/\d\(\)]+)$}i.match(@command)
        unless m
          return nil
        end

        @is_secret = !m[1].nil?
        expr = ArithmeticEvaluator.new(m[2], round_type: @game_system.round_type)
        value = expr.eval()
        if expr.error?
          return nil
        end

        return "計算結果 ＞ #{value}"
      end
    end
  end
end
