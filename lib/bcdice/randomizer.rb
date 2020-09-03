module BCDice
  class Randomizer
    DICE_MAXCNT = 200
    DICE_MAXNUM = 1000

    def initialize
      @rands = nil
      @rand_results = []
      @detailed_rand_results = []
    end

    attr_reader :rand_results, :detailed_rand_results

    def roll(dice_cnt, dice_max, dice_sort = false)
      dice_cnt = dice_cnt.to_i
      dice_max = dice_max.to_i

      total = 0
      dice_str = ""
      numberSpot1 = 0
      cnt_max = 0
      n_max = 0
      cnt_suc = 0
      rerollCount = 0

      unless (dice_cnt <= DICE_MAXCNT) && (dice_max <= DICE_MAXNUM)
        return total, dice_str, numberSpot1, cnt_max, n_max, cnt_suc, rerollCount
      end

      dice_list = Array.new(dice_cnt) { rand(dice_max) + 1 }
      dice_list.sort! if dice_sort

      total = dice_list.sum()
      dice_str = dice_list.join(",")
      numberSpot1 = dice_list.count(1)
      cnt_max = dice_list.count(dice_max)
      n_max = dice_list.max()

      return total, dice_str, numberSpot1, cnt_max, n_max, 0, 0
    end

    # @param times [Integer] 振るダイスの個数
    # @param sides [Integer] ダイスの面数
    # @return [Array<Integer>] ダイスの出目一覧
    def roll_barabara(times, sides)
      _, dice_list = roll(times, sides)
      return dice_list.split(",").map(&:to_i)
    end

    # 1回だけダイスロールを行う
    #
    # @params sides [Integer] ダイスの面数
    # @return [Integer] 1以上 *sides* 以下の値のいずれか
    def roll_once(sides)
      rand_inner(sides) + 1
    end

    # @params [Integer] max
    # @return [Integer] 0以上max未満の整数
    def rand_inner(max)
      value = 0
      if @rands.nil?
        value = randNomal(max)
      else
        value = randFromRands(max)
      end

      @rand_results << [(value + 1), max]

      return value
    end

    DetailedRandResult = Struct.new(:kind, :sides, :value)

    # @params [Integer] max
    # @return [Integer] 0以上max未満の整数
    def rand(max)
      ret = rand_inner(max)

      push_to_detail(:normal, max, ret + 1)
      return ret
    end

    # 十の位をd10を使って決定するためのダイスロール
    # @return [Integer] 0以上90以下で10の倍数となる整数
    def roll_tens_d10()
      # rand_innerの戻り値を10倍すればすむ話なのだが、既存のテストとの互換性の為に処理をする
      r = rand_inner(10) + 1
      if r == 10
        r = 0
      end

      ret = r * 10

      push_to_detail(:tens_d10, 10, ret)
      return ret
    end

    # d10を0~9として扱うダイスロール
    # @return [Integer] 0以上9以下の整数
    def roll_d9()
      ret = rand_inner(10)

      push_to_detail(:d9, 10, ret)
      return ret
    end

    def setRandomValues(rands)
      @rands = rands
    end

    # @params [Symbol] kind
    # @params [Integer] sides
    # @params [Integer] value
    def push_to_detail(kind, sides, value)
      detail = DetailedRandResult.new(kind, sides, value)
      @detailed_rand_results.push(detail)
    end

    def randNomal(max)
      Kernel.rand(max)
    end

    def randFromRands(targetMax)
      nextRand = @rands.shift

      if nextRand.nil?
        # return randNomal(targetMax)
        raise "nextRand is nil, so @rands is empty!! @rands:#{@rands.inspect}"
      end

      value, max = nextRand
      value = value.to_i
      max = max.to_i

      if  max != targetMax
        # return randNomal(targetMax)
        raise "invalid max value! [ #{value} / #{max} ] but NEED [ #{targetMax} ] dice"
      end

      return (value - 1)
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
  end
end
