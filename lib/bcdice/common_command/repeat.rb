# frozen_string_literal: true

require "strscan"

module BCDice
  module CommonCommand
    # リピート
    #
    # 繰り返し回数を指定して、特定のコマンドを複数回実行する
    # 例）
    #   x5 choice[A,B,C,D] #=> `choice[A,B,C,D]`を5回実行する
    #   rep2 CC<=75        #=> `CC<=75`を2回実行する
    #   repeat10 2D6+5     #=> `2D6+6`を10回実行する
    #
    # このコマンドを入れ子させることは許容しない。繰り返し回数の爆発に繋がるためである。
    # 以下は実行時にエラーとなる。
    #   x10 repeat100 100D100
    class Repeat
      PREFIX_PATTERN = /(repeat|rep|x)\d+/.freeze

      REPEAT_LIMIT = 100

      class << self
        def eval(command, game_system, randomizer)
          cmd = parse(command)
          cmd&.roll(game_system, randomizer)
        end

        private

        def parse(command)
          scanner = StringScanner.new(command)

          secret = !scanner.scan(/s/i).nil?
          keyword = scanner.scan(/repeat|rep|x/i)
          repeat_times = scanner.scan(/\d+/)&.to_i
          whitespace = scanner.scan(/\s+/)
          if keyword.nil? || repeat_times.nil? || whitespace.nil?
            return nil
          end

          trailer = scanner.post_match
          if trailer.nil? || trailer.empty?
            return nil
          end

          new(
            secret: secret,
            times: repeat_times,
            trailer: trailer
          )
        end
      end

      def initialize(secret:, times:, trailer:)
        @secret = secret
        @times = times
        @trailer = trailer
      end

      def roll(game_system, randomizer)
        err = validate()
        return err if err

        results = Array.new(@times) do
          cmd = game_system.class.new(@trailer)
          cmd.randomizer = randomizer
          cmd.eval()
        end

        if results.count(nil) == @times
          return result_with_text("繰り返し対象のコマンドが実行できませんでした (#{@trailer})")
        end

        text = results.map.with_index(1) { |r, index| "\##{index}\n#{r.text}" }.join("\n\n")
        secret = @secret || results.any?(&:secret?)

        Result.new.tap do |r|
          r.secret = secret
          r.text = text
        end
      end

      private

      def validate
        if /\A(repeat|rep|x)\d+/.match?(@trailer)
          result_with_text("Repeatコマンドの重複はできません")
        elsif @times < 1 || REPEAT_LIMIT < @times
          result_with_text("繰り返し回数は1以上、#{REPEAT_LIMIT}以下が指定可能です")
        end
      end

      def result_with_text(text)
        Result.new.tap do |r|
          r.secret = @secret
          r.text = text
        end
      end
    end
  end
end
