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
    #
    # "choise"の後に数を指定することで、列挙した要素から重複なしで複数個を選ぶ
    #   choice2[A,B,C] -> "A", "B", "C" から重複なしで2個選ぶ
    #
    # 指定したい要素が「AからD」のように連続する項目の場合に「A-D」と省略して記述できる
    # 略記の展開はアルファベット1文字もしくは数字の範囲に限り、略記1つを指定したときのみ展開される
    #   choice[A-D] -> choice[A,B,C,D] と等価
    #   choice[b-g] -> choice[b,c,d,e,f,g] と等価
    #   choice[3-7] -> choice[3,4,5,6,7] と等価
    #   choice[A-D,Z] -> 展開されない。 "A-D", "Z" から選ぶ
    #   choice[D-A] -> 展開されない。
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

      DELIMITER_CHAR = {
        bracket: ", ",
        paren: ", ",
        space: " ",
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

          takes = scanner.scan(/\d+/)&.to_i || 1
          if takes == 0
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
          if items.size == 1
            items = parse_multi_item_shorthand(items.first)
          end

          if items.empty? || items.size < takes
            return nil
          end

          new(
            secret: secret,
            block_delimiter: type,
            takes: takes,
            items: items
          )
        end

        def parse_multi_item_shorthand(str)
          parse_multi_nums_shorthand(str) || parse_multi_chars_shorthand(str) || []
        end

        def parse_multi_nums_shorthand(str)
          m = /^(\d+)-(\d+)$/.match(str)
          unless m
            return nil
          end

          first = m[1].to_i
          last = m[2].to_i
          if first > last
            return nil
          end

          return first.upto(last).to_a
        end

        def parse_multi_chars_shorthand(str)
          m = /^([a-z])-([a-z])$/.match(str) || /^([A-Z])-([A-Z])$/.match(str)
          unless m
            return nil
          end

          first = m[1]
          last = m[2]
          if first > last
            return nil
          end

          return first.upto(last).to_a
        end
      end

      # @param secret [Boolean]
      # @param block_delimiter [BlockDelimiter::BRACKET, BlockDelimiter::PAREN, BlockDelimiter::SPACE]
      # @param takes [Integer] 何個チョイスするか
      # @param items [Array<String>]
      def initialize(secret:, block_delimiter:, takes:, items:)
        @secret = secret
        @block_delimiter = block_delimiter
        @takes = takes
        @items = items
      end

      # @param randomizer [Randomizer]
      # @return [Result]
      def roll(randomizer)
        if @items.size > 100
          return Result.new("項目数は100以下としてください")
        end

        items = @items.dup
        chosens = []
        @takes.times do
          index = randomizer.roll_index(items.size)
          chosens << items.delete_at(index)
        end

        Result.new.tap do |r|
          chosen = chosens.join(DELIMITER_CHAR[@block_delimiter])

          r.secret = @secret
          r.text = "(#{expr()}) ＞ #{chosen}"
        end
      end

      def expr
        takes = @takes == 1 ? nil : @takes

        case @block_delimiter
        when BlockDelimiter::SPACE
          "choice#{takes} #{@items.join(' ')}"
        when BlockDelimiter::BRACKET
          "choice#{takes}[#{@items.join(',')}]"
        when BlockDelimiter::PAREN
          "choice#{takes}(#{@items.join(',')})"
        end
      end
    end
  end
end
