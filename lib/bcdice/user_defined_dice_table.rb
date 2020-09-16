module BCDice
  # テキストで定義したダイス表を実行するクラス
  #
  # @example
  #   text = <<~TEXT
  #     飲み物表
  #     1D6
  #     1:水
  #     2:緑茶
  #     3:麦茶
  #     4:コーラ
  #     5:オレンジジュース
  #     6:選ばれし者の知的飲料
  #   TEXT
  #   table = BCDice::UserDefinedDiceTable.new(text)
  #   table.valid()? #=> true
  #   table.roll()   #=> "飲み物表(6) ＞ 選ばれし者の知的飲料"
  #
  class UserDefinedDiceTable
    def initialize(text)
      @text = text
      @randomizer = Randomizer.new
    end

    attr_accessor :randomizer

    # @return [String, nil]
    def roll
      parse()
      index = roll_index()
      unless index
        return nil
      end

      key = "#{index}:"
      row = @rows.find { |l| l.start_with?(key) }
      unless row
        return nil
      end

      chosen = row.delete_prefix(key).gsub('\n', "\n").strip
      return "#{@name}(#{index}) ＞ #{chosen}"
    end

    # 有効なダイス表かをチェックする。テキスト形式のミスだけではなく、抜けている出目や範囲外の出目がないか確認する。
    # @return [Boolean]
    def valid?
      parse()

      has_index = @rows.all? { |row| /^\d+:/.match?(row) }
      unless has_index
        return false
      end

      index_list = @rows.map(&:to_i).uniq.sort

      case @type
      when /^\d+D\d+$/
        valid_d?(index_list)
      when "D66", "D66N"
        valid_d66?(index_list)
      when "D66A", "D66S"
        valid_d66_asc_sort?(index_list)
      when "D66D"
        valid_d66_desc_sort?(index_list)
      else
        false
      end
    end

    private

    # @return [Integer, nil]
    def roll_index
      if (m = /^(\d+)D(\d+)$/.match(@type))
        times = m[1].to_i
        sides = m[2].to_i
        return @randomizer.roll_sum(times, sides)
      end

      case @type
      when "D66", "D66N"
        @randomizer.roll_d66(D66SortType::NO_SORT)
      when "D66A", "D66S"
        @randomizer.roll_d66(D66SortType::ASC)
      when "D66D"
        @randomizer.roll_d66(D66SortType::DESC)
      end
    end

    def parse
      lines = @text.split(/\R/).map(&:rstrip).reject(&:empty?)
      @name = lines.shift
      @type = lines.shift.upcase
      @rows = lines
    end

    def valid_d?(index_list)
      m = /^(\d+)D(\d+)$/.match(@type)
      times = m[1].to_i
      sides = m[2].to_i

      expected_size = times * sides - times + 1
      if index_list.size != expected_size
        return false
      end

      return index_list.first == times && index_list.last == times * sides
    end

    def valid_d66?(index_list)
      if index_list.size != 36
        return false
      end

      expected_index = (1..6).map do |tens|
        (1..6).map { |ones| tens * 10 + ones }
      end.flatten

      return index_list == expected_index
    end

    def valid_d66_asc_sort?(index_list)
      if index_list.size != 21
        return false
      end

      expected_index = (1..6).map do |tens|
        (tens..6).map { |ones| tens * 10 + ones }
      end.flatten

      return index_list == expected_index
    end

    def valid_d66_desc_sort?(index_list)
      if index_list.size != 21
        return false
      end

      expected_index = (1..6).map do |ones|
        (ones..6).map { |tens| tens * 10 + ones }
      end.flatten.sort

      return index_list == expected_index
    end
  end
end
