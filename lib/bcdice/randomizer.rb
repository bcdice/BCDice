module BCDice
  class Randomizer
    UPPER_LIMIT_DICE_TIMES = 200
    UPPER_LIMIT_DICE_SIDES = 1000

    def initialize
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
      if times <= 0 || times > UPPER_LIMIT_DICE_TIMES
        return []
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
    # @param sides [Integer] ダイスの面数
    # @return [Integer] 1以上 *sides* 以下の値のいずれか
    def roll_once(sides)
      if sides <= 0 || sides > UPPER_LIMIT_DICE_SIDES
        return 0
      end

      dice = rand_inner(sides)
      push_to_detail(:normal, sides, dice)

      return dice
    end

    # ダイス表などでindexを参照する用のダイスロール
    # @param sides [Integer]
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

    # D66のダイスロールを行う
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

    # @param sides [Integer]
    # @return [Integer] 1以上sides以下の整数
    def rand_inner(sides)
      dice = random(sides)

      @rand_results << [dice, sides]
      return dice
    end

    # モックで上書きする用
    # @param sides [Integer]
    # @return [Integer] 1以上sides以下の整数
    def random(sides)
      Kernel.rand(sides) + 1
    end

    DetailedRandResult = Struct.new(:kind, :sides, :value)

    # @param [Symbol] kind
    # @param [Integer] sides
    # @param [Integer] value
    def push_to_detail(kind, sides, value)
      detail = DetailedRandResult.new(kind, sides, value)
      @detailed_rand_results.push(detail)
    end
  end
end
