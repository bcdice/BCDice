class BCDice
  module CommonCommand
    class Calc
      def initialize(command, _randomizer, _game_system)
        @command = command

        @is_secret = false
      end

      def secret?
        @is_secret
      end

      def eval
        m = /^(S)?C(-?\d+)$/i.match(@command)
        unless m
          return nil
        end

        @is_secret = !m[1].nil?
        value = m[2].to_i
        return ": 計算結果 ＞ #{value}"
      end
    end
  end
end
