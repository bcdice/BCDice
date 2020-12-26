# frozen_string_literal: true

module BCDice
  # 入力文字列に対して前処理を行う
  #
  # @example
  #   Preprocessor.process(
  #     "1d6+4D+(3*4) 切り取られる部分",
  #     game_system
  #   ) #=> "1d6+4D6+7"
  class Preprocessor
    # @param (see #initialize)
    # @return [String]
    def self.process(text, game_system)
      Preprocessor.new(text, game_system).process()
    end

    # @param text [String]
    # @param game_system [Base]
    def initialize(text, game_system)
      @text = text
      @game_system = game_system
    end

    # @return [String]
    def process
      trim_after_whitespace()
      replace_parentheses()

      @text = @game_system.change_text(@text)

      replace_implicit_d()

      return @text
    end

    private

    # 空白より前だけを取る
    def trim_after_whitespace()
      @text = @text.strip.split(/\s/, 2).first
    end

    # カッコ書きの数式を事前計算する
    def replace_parentheses
      loop do
        prev = @text
        @text = @text.gsub(%r{\([\d/+*\-]+\)}) do |expr|
          ae = ArithmeticEvaluator.new(expr, round_type: @game_system.round_type)
          val = ae.eval
          ae.error? ? expr : val
        end
        break if prev == @text
      end
    end

    # nDをゲームシステムに応じて置き換える
    def replace_implicit_d
      @text = @text.gsub(/(\d+)D([^\w]|$)/i) do
        times = Regexp.last_match(1)
        sides = @game_system.sides_implicit_d
        trailer = Regexp.last_match(2)

        "#{times}D#{sides}#{trailer}"
      end
    end
  end
end
