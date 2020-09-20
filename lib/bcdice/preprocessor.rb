module BCDice
  # 入力文字列に対して前処理を行う
  #
  # @example
  #   Preprocessor.process(
  #     "1d6+[2D6]+[40..50]+4D+(3*4) 切り取られる部分",
  #     randomizer,
  #     game_system
  #   ) #=> "1d6+3+46+4D6+7"
  class Preprocessor
    # @param (see #initialize)
    # @return [String]
    def self.process(text, randomizer, game_system)
      Preprocessor.new(text, randomizer, game_system).process()
    end

    # @param text [String]
    # @param randomizer [Randomizer]
    # @param game_system [Base]
    def initialize(text, randomizer, game_system)
      @text = text
      @randomizer = randomizer
      @game_system = game_system
    end

    # @return [String]
    def process
      trim_after_whitespace()
      replace_preroll()
      replace_range()
      replace_parentheses()

      @text = @game_system.change_text(@text)

      replace_implicit_d6()

      return @text
    end

    private

    # 空白より前だけを取る
    def trim_after_whitespace()
      @text = @text.strip.split(/\s/, 2).first
    end

    # [1D6]のような部分を事前ダイスロールする
    def replace_preroll()
      @text = @text.gsub(/\[\d+D\d+\]/i) do |matched|
        # Remove '[' and ']'
        command = matched[1..-2].upcase
        times, sides = command.split("D").map(&:to_i)

        @randomizer.roll_sum(times, sides)
      end
    end

    # [1...6]のような部分を事前ダイスロールする
    def replace_range
      @text = @text.gsub(/\[(\d+)\.\.\.(\d+)\]/) do |matched|
        first = Regexp.last_match(1).to_i
        last = Regexp.last_match(2).to_i

        if first > last
          matched
        else
          steps = last - first + 1
          dice = @randomizer.roll_once(steps)

          first + dice - 1
        end
      end
    end

    # カッコ書きの数式を事前計算する
    def replace_parentheses
      @text = @text.gsub(%r{\([\d/\+\*\-\(\)]+\)}) do |expr|
        ArithmeticEvaluator.eval(expr, round_type: @game_system.round_type)
      end
    end

    # nDをnD6に置き換える
    def replace_implicit_d6
      @text = @text.gsub(/(\d+)D([^\w]|$)/i) { "#{Regexp.last_match(1)}D6#{Regexp.last_match(2)}" }
    end
  end
end
