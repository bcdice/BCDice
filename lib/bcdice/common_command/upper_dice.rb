require "bcdice/arithmetic_evaluator"
require "bcdice/normalize"
require "bcdice/format"

module BCDice
  module CommonCommand
    # 上方無限ロール
    #
    # ダイスを1つ振る、その出目が閾値より大きければダイスを振り足すのを閾値未満の出目が出るまで繰り返す。
    # これを指定したダイス数だけおこない、それぞれのダイスの合計値を求める。
    # それらと目標値を比較し、成功した数を表示する。
    #
    # フォーマットは以下の通り
    # 2U4+1U6[4]>=6
    # 2U4+1U6>=6@4
    #
    # 閾値は角カッコで指定するか、コマンドの末尾に @6 のように指定する。
    # 閾値の指定が重複した場合、角カッコが優先される。
    # この時、出目が
    #   "2U4" -> 3[3], 10[4,4,2]
    #   "1U6" -> 6[4,2]
    # だとすると、 >=6 に該当するダイスは2つなので成功数2となる。
    #
    # 2U4[4]+10>=6 のように修正値を指定できる。修正値は全てのダイスに補正を加え、以下のようになる。
    #   "2U4" -> 3[3]+10=13, 10[4,4,2]+10=20
    #
    # 比較演算子が書かれていない場合、ダイスの最大値と全ダイスの合計値が出力される。
    # 全ダイスの合計値には補正値が1回だけ適用される
    # 2U4[4]+10
    #   "2U4" -> 3[3]+10=13, 10[4,4,2]+10=20
    #   最大値：20
    #   合計値：23 = 3[3]+10[4,4,2]+10
    class UpperDice
      PREFIX_PATTERN = /\d+U\d+/.freeze

      class << self
        # @param command [String]
        # @param game_system [BCDice::Base]
        # @param randomizer [BCDice::Randomizer]
        # @return [UpperDice, nil]
        def eval(command, game_system, randomizer)
          command = parse(command, game_system)
          command&.eval(randomizer)
        end

        private

        def parse(command, game_system)
          m = /^S?(\d+U\d+(?:\+\d+U\d+)*)(?:\[(\d+)\])?([\+\-\d]*)(?:([<>=]+)(\d+))?(?:@(\d+))?/i.match(command)
          unless m
            return nil
          end

          reroll_threshold = m[2]&.to_i || m[6]&.to_i || game_system.upper_dice_reroll_threshold.to_i

          new(
            secret: command.start_with?("S"),
            notations: notations(m[1], reroll_threshold, game_system.sort_barabara_dice?),
            modifier: ArithmeticEvaluator.eval(m[3], round_type: game_system.round_type),
            cmp_op: Normalize.comparison_operator(m[4]),
            target_number: m[5]&.to_i,
            reroll_threshold: reroll_threshold
          )
        end

        def notations(str, reroll_threshold, should_sort)
          str.split("+").map do |notation|
            roll_times, sides = notation.split("U", 2).map(&:to_i)
            Notation.new(roll_times, sides, reroll_threshold, should_sort)
          end
        end
      end

      class Notation
        # @param roll_times [Integer]
        # @param sides [Integer]
        # @param reroll_threshold [Integer]
        # @param should_sort [Boolean]
        def initialize(roll_times, sides, reroll_threshold, should_sort)
          @roll_times = roll_times
          @sides = sides
          @reroll_threshold = reroll_threshold
          @should_sort = should_sort
        end

        # @param randomizer [BCDice::Randomizer]
        # @return [Array<Hash>]
        def roll(randomizer)
          ret = Array.new(roll_times) do
            list = roll_ones(randomizer)
            {sum: list.sum(), list: list}
          end

          if should_sort
            ret = ret.sort_by { |e| e[:sum] }
          end

          return ret
        end

        def to_s
          "#{@roll_times}U#{@sides}"
        end

        private

        attr_reader :roll_times, :sides, :reroll_threshold, :should_sort

        def roll_ones(randomizer)
          dice_list = []

          loop do
            value = randomizer.roll_once(sides)
            dice_list.push(value)
            break if value < reroll_threshold
          end

          return dice_list
        end
      end

      # @param secret [Boolean]
      # @param notations [Array<Notation>]
      # @param modifier [Integer]
      # @param cmp_op [Symbol, nil]
      # @param target_number [Integer, nil]
      # @param reroll_threshold [Integer]
      def initialize(secret:, notations:, modifier:, cmp_op:, target_number:, reroll_threshold:)
        @secret = secret
        @notations = notations
        @modifier = modifier
        @cmp_op = cmp_op
        @target_number = target_number
        @reroll_threshold = reroll_threshold
      end

      # 上方無限ロールを実行する
      #
      # @param randomizer [Randomizer]
      # @return [Result, nil]
      def eval(randomizer)
        if @reroll_threshold <= 1
          return Result.new.tap do |r|
            r.secret = @secret
            r.text = "(#{expr()}) ＞ 無限ロールの条件がまちがっています"
          end
        end

        roll_list = @notations.map { |n| n.roll(randomizer) }.reduce([], :concat)

        result =
          if @cmp_op
            result_success_count(roll_list)
          else
            result_max_sum(roll_list)
          end

        sequence = [
          "(#{expr()})",
          dice_text(roll_list) + Format.modifier(@modifier),
          result
        ]

        Result.new.tap do |r|
          r.secret = @secret
          r.text = sequence.join(" ＞ ")
        end
      end

      private

      def result_success_count(roll_list)
        success_count = roll_list.count do |e|
          x = e[:sum] + @modifier
          x.send(@cmp_op, @target_number)
        end

        "成功数#{success_count}"
      end

      def result_max_sum(roll_list)
        sum_list = roll_list.map { |e| e[:sum] }
        total = sum_list.sum() + @modifier
        max = sum_list.map { |i| i + @modifier }.max

        "#{max}/#{total}(最大/合計)"
      end

      # ダイスロールの結果を文字列に変換する
      # 振り足しがなければその数値、振り足しがあれば合計と各ダイスの出目を出力する
      #
      # @param roll_list [Array<Hash>]
      # @return [String]
      def dice_text(roll_list)
        roll_list.map do |e|
          if e[:list].size == 1
            e[:sum]
          else
            "#{e[:sum]}[#{e[:list].join(',')}]"
          end
        end.join(",")
      end

      # パース済みのコマンドを文字列で表示する
      #
      # @return [String]
      def expr
        "#{@notations.join('+')}[#{@reroll_threshold}]#{Format.modifier(@modifier)}#{Format.comparison_operator(@cmp_op)}#{@target_number}"
      end
    end
  end
end
