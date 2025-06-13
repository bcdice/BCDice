# frozen_string_literal: true

module BCDice
  module DiceTable
    # D66を振って出目を昇順/降順にして表を参照する
    class D66Table
      # @param key [String]
      # @param locale [Symbol]
      # @return [D66Table]
      def self.from_i18n(key, locale)
        table = I18n.t(key, locale: locale)
        sort_type = D66SortType.const_get(table[:d66_sort_type])

        new(table[:name], sort_type, table[:items])
      end

      # @param [String] name 表の名前
      # @param [Symbol] sort_type 出目入れ替えの方式 BCDice::D66SortType
      # @param [Hash] items 表の項目 Key は数値
      def initialize(name, sort_type, items)
        @name = name
        @sort_type = sort_type
        @items = items.freeze
      end

      # 表を振る
      # @param randomizer [#roll_barabara] ランダマイザ
      # @return [String] 結果
      def roll(randomizer)
        dice = randomizer.roll_barabara(2, 6)

        case @sort_type
        when D66SortType::ASC
          dice.sort!
        when D66SortType::DESC
          dice.sort!.reverse!
        end

        key = dice[0] * 10 + dice[1]
        chosen = @items[key]

        RollResult.new_with_chain(@name, key, chosen, randomizer)
      end

      def choice(key)
        RollResult.new(@name, key, @items[key])
      end
    end
  end
end
