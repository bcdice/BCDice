module BCDice
  class Randomizer
    UPPER_LIMIT_DICE_TIMES = 200
    UPPER_LIMIT_DICE_SIDES = 1000

    def initialize
      @rands = nil
      @rand_results = []
      @detailed_rand_results = []
    end

    attr_reader :rand_results, :detailed_rand_results

    # 複数個のダイスを振る
    #
    # @param times [Integer] 振るダイスの個数
    # @param sides [Integer] ダイスの面数
    # @return [Array<Integer>] ダイスの出目一覧
    def roll_barabara(times, sides)
      if times > UPPER_LIMIT_DICE_TIMES || sides > UPPER_LIMIT_DICE_SIDES
        return [0]
      end

      Array.new(times) { roll_once(sides) }
    end

    # 複数個のダイスを振って、その合計を求める
    #
    # @param times [Integer] 振るダイスの個数
    # @param sides [Integer] ダイスの面数
    # @return [Integer] 出目の合計
    def roll_sum(times, sides)
      roll_barabara(times, sides).sum()
    end

    # 1回だけダイスロールを行う
    #
    # @params sides [Integer] ダイスの面数
    # @return [Integer] 1以上 *sides* 以下の値のいずれか
    def roll_once(sides)
      if sides > UPPER_LIMIT_DICE_SIDES
        return 0
      end

      dice = rand_inner(sides)
      push_to_detail(:normal, sides, dice)

      return dice
    end

    # @params sides [Integer]
    # @return [Integer] 0以上 *sides* 未満の整数
    def roll_index(sides)
      roll_once(sides) - 1
    end

    # 十の位をd10を使って決定するためのダイスロール
    # @return [Integer] 0以上90以下で10の倍数となる整数
    def roll_tens_d10()
      # rand_innerの戻り値を10倍すればすむ話なのだが、既存のテストとの互換性の為に処理をする
      dice = rand_inner(10)
      if dice == 10
        dice = 0
      end

      ret = dice * 10

      push_to_detail(:tens_d10, 10, ret)
      return ret
    end

    # d10を0~9として扱うダイスロール
    # @return [Integer] 0以上9以下の整数
    def roll_d9()
      dice = rand_inner(10) - 1

      push_to_detail(:d9, 10, dice)
      return dice
    end

    def setRandomValues(rands)
      @rands = rands
    end

    # @param sort_type [Symbol] BCDice::D66SortType
    # @return [Integer]
    def roll_d66(sort_type)
      dice_list = Array.new(2) { roll_once(6) }

      case sort_type
      when D66SortType::ASC
        dice_list.sort!
      when D66SortType::DESC
        dice_list.sort!.reverse!
      end

      return dice_list[0] * 10 + dice_list[1]
    end

    private

    # @params sides [Integer]
    # @return [Integer] 1以上sides以下の整数
    def rand_inner(sides)
      dice =
        if @rands.nil?
          Kernel.rand(sides) + 1
        else
          rand_from_pool(sides)
        end

      @rand_results << [dice, sides]

      return dice
    end

    # @params sides [Integer]
    # @return [Integer]
    def rand_from_pool(sides)
      dice, expected_sides = @rands.shift

      if dice.nil?
        raise "@rands is empty!"
      elsif sides != expected_sides
        raise "unexpected sides at [#{dice}/#{expected_sides}], side (given #{sides}, expected #{expected_sides})"
      end

      return dice
    end

    DetailedRandResult = Struct.new(:kind, :sides, :value)

    # @params [Symbol] kind
    # @params [Integer] sides
    # @params [Integer] value
    def push_to_detail(kind, sides, value)
      detail = DetailedRandResult.new(kind, sides, value)
      @detailed_rand_results.push(detail)
    end
  end
end
