# frozen_string_literal: true

require "strscan"

module BCDice
  module CommonCommand
    # チョイスコマンド
    #
    # 列挙された項目の中から一つを選んで出力する。
    #
    # フォーマットは以下の通り
    # choice[A,B,C,D]
    # choice(A,B,C,D)
    # choice A B C D
    # choice(新クトゥルフ神話TRPG, ソード・ワールド2.5, Dungeons & Dragons)
    #
    # "choice"の次の文字によって区切り文字が変化する
    #   "[" -> "," で区切る
    #   "(" -> "," で区切る
    #   " " -> /\s+/ にマッチする文字列で区切る
    #
    # 各項目の前後に空白文字があった場合は除去される
    #   choice[A, B,  C , D   ] は choice[A,B,C,D] と等価
    #
    # 項目が空文字列である場合、その項目は無視する
    #   choice[A,,C] は choice[A,C] と等価
    #
    # フォーマットを選ぶことで、項目の文字列に()や,を含めることができる
    #   choice A,B X,Y -> "A,B" と "X,Y" から選ぶ
    #   choice(A[], B[], C[]) -> "A[]", "B[]", "C[]" から選ぶ
    #   choice[A(), B(), C()] -> "A()", "B()", "C()" から選ぶ
    class Choice
      PREFIX_PATTERN = /choice/.freeze

      module BlockDelimiter
        BRACKET = :bracket # "["
        PAREN = :paren # "("
        SPACE = :space # /\s/
      end

      DELIMITER = {
        bracket: /,/,
        paren: /,/,
        space: /\s+/,
      }.freeze

      TERMINATION = {
        bracket: /\]/,
        paren: /\)/,
        space: /$/,
      }.freeze

      SUFFIX = {
        bracket: "]",
        paren: ")",
        space: "",
      }.freeze

      class << self
        # @param command [String]
        # @param _game_system [BCDice::Base]
        # @param randomizer [Randomizer]
        # @return [Result, nil]
        def eval(command, _game_system, randomizer)
          cmd = parse(command)
          cmd&.roll(randomizer)
        end

        private

        def parse(command)
          scanner = StringScanner.new(command)
          scanner.skip(/\s+/)

          secret = !scanner.scan(/S/i).nil?
          unless scanner.scan(/choice/i)
            return nil
          end

          type =
            case scanner.scan(/\(|\[|\s+/)
            when "["
              BlockDelimiter::BRACKET
            when "("
              BlockDelimiter::PAREN
            when String
              BlockDelimiter::SPACE
            else
              return nil
            end

          delimiter = DELIMITER[type]
          termination = TERMINATION[type]

          items = []
          while (item = scanner.scan_until(delimiter))
            items.push(item.delete_suffix(","))
          end

          last_item = scanner.scan_until(termination)
          unless last_item
            return nil
          end

          items.push(last_item.delete_suffix(SUFFIX[type]))

          items = items.map(&:strip).reject(&:empty?)

          new(
            secret: secret,
            block_delimiter: type,
            items: items
          )
        end
      end

      # @param secret [Boolean]
      # @param block_delimiter [BlockDelimiter::BRACKET, BlockDelimiter::PAREN, BlockDelimiter::SPACE]
      # @param items [Array<String>]
      def initialize(secret:, block_delimiter:, items:)
        @secret = secret
        @block_delimiter = block_delimiter
        @items = items
      end

      # @param randomizer [Randomizer]
      # @return [Result]
      def roll(randomizer)
        index = randomizer.roll_index(@items.size)
        chosen = @items[index]

        Result.new.tap do |r|
          r.secret = @secret
          r.text = "(#{expr()}) ＞ #{chosen}"
        end
      end

      def expr
        case @block_delimiter
        when BlockDelimiter::SPACE
          "choice #{@items.join(' ')}"
        when BlockDelimiter::BRACKET
          "choice[#{@items.join(',')}]"
        when BlockDelimiter::PAREN
          "choice(#{@items.join(',')})"
        end
      end
    end
  end
end
