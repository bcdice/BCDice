module BCDice
  class Preprocessor
    def self.process(text, randomizer, game_system)
      Preprocessor.new(text, randomizer, game_system).process()
    end

    def initialize(text, randomizer, game_system)
      @text = text
      @randomizer = randomizer
      @game_system = game_system
    end

    def process
      trim_after_whitespace()
      replace_preroll()
      replace_range()
      replace_parentheses()

      @text = @game_system.changeText(@text)

      replace_implicit_d6()

      return @text
    end

    private

    def trim_after_whitespace()
      @text = @text.strip.split(/\s/, 2).first
    end

    def replace_preroll()
      @text = @text.gsub(/\[\d+D\d+\]/i) do |matched|
        # Remove '[' and ']'
        command = matched[1..-2].upcase
        times, sides = command.split("D").map(&:to_i)
        rolled, = @randomizer.roll(times, sides)

        rolled
      end
    end

    def replace_range
      @text = @text.gsub(/\[(\d+)\.\.\.(\d+)\]/) do |matched|
        first = Regexp.last_match(1).to_i
        last = Regexp.last_match(2).to_i

        if first > last
          matched
        else
          steps = last - first + 1
          dice, = @randomizer.roll(1, steps)

          first + dice - 1
        end
      end
    end

    def replace_parentheses
      @text = @text.gsub(%r{\([\d/\+\*\-\(\)]+\)}) do |expr|
        ArithmeticEvaluator.new.eval(expr, @game_system.round_type)
      end
    end

    def replace_implicit_d6
      @text = @text.gsub(/(\d+)D([^\w]|$)/i) { "#{Regexp.last_match(1)}D6#{Regexp.last_match(2)}" }
    end
  end
end
