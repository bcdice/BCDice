require "bcdice/normalize"
require "bcdice/format"

module BCDice
  module CommonCommand
    # 個数振り足しダイス
    #
    # ダイスを振り、条件を満たした出目の個数だけダイスを振り足す。振り足しがなくなるまでこれを繰り返す。
    # 成功条件を満たす出目の個数を調べ、成功数を表示する。
    #
    # 例
    #   2R6+1R10[>3]>=5
    #   2R6+1R10>=5@>3
    #
    # 振り足し条件は角カッコかコマンド末尾の @ で指定する。
    # [>3] の場合、3より大きい出目が出たら振り足す。
    # [3] のように数値のみ指定されている場合、成功条件の比較演算子を流用する。
    # 上記の例の時、出目が
    #   "2R6"  -> [5,6] [5,4] [1,3]
    #   "1R10" -> [9] [1]
    # だとすると、 >=5 に該当するダイスは5つなので成功数5となる。
    #
    # 成功条件が書かれていない場合、成功数0として扱う。
    # 振り足し条件が数値のみ指定されている場合、比較演算子は >= が指定されたとして振舞う。
    class RerollDice
      PREFIX_PATTERN = /\d+R\d+/.freeze
      REROLL_LIMIT = 10000

      class << self
        def eval(command, game_systemm, randomizer)
          command = parse(command, game_systemm)
          command&.eval(randomizer)
        end

        private

        # @param command [String]
        # @param game_system [BCDice::Base]
        # @return [Command, nil]
        def parse(command, game_system)
          m = /^S?(\d+R\d+(?:\+\d+R\d+)*)(?:\[([<>=]+)?(\d+)\])?(?:([<>=]+)(\d+))?(?:@([<>=]+)?(\d+))?$/.match(command)
          unless m
            return nil
          end

          new(
            source: command,
            secret: command.start_with?("S"),
            notations: notations(m[1]),
            cmp_op: Normalize.comparison_operator(m[4]) || game_system.default_cmp_op,
            target_number: m[5]&.to_i,
            reroll_cmp_op: decide_reroll_cmp_op(m),
            reroll_threshold: m[3]&.to_i || m[7]&.to_i,
            game_system: game_system
          )
        end

        def notations(notation)
          notation.split("+").map do |xRn|
            xRn.split("R", 2).map(&:to_i)
          end
        end

        # @param m [MatchData]
        # @return [Symbol]
        def decide_reroll_cmp_op(m)
          bracket_op = m[2]
          bracket_number = m[3]
          at_op = m[6]
          at_number = m[7]
          cmp_op = m[4]

          op =
            if bracket_op && bracket_number
              bracket_op
            elsif at_op && at_number
              at_op
            else
              cmp_op
            end

          Normalize.comparison_operator(op) || :>=
        end
      end

      def initialize(source: sourcce, secret:, notations:, cmp_op:, target_number:, reroll_cmp_op:, reroll_threshold:, game_system:)
        @source = source
        @secret = secret
        @notations = notations
        @cmp_op = cmp_op
        @target_number = target_number
        @reroll_cmp_op = reroll_cmp_op
        @reroll_threshold = reroll_threshold
        @game_system = game_system
      end

      def eval(randomizer)
        dice_queue = @notations.map { |times, sides| [times, sides, 0] }
        depth_zero_size = @notations.map { |times, _| times }.sum()

        unless valid_command?(dice_queue)
          return result_with_text(msg_invalid_reroll_number(@source))
        end

        dice_list_list = roll(randomizer, dice_queue)

        dice_list = dice_list_list.flatten
        one_count = dice_list.take(depth_zero_size).count(1) # 振り足し分は出目1の個数をカウントしない
        success_count =
          if cmp_op
            dice_list.count { |val| val.send(cmp_op, target_number) }
          else
            0
          end

        sequence = [
          expr(),
          dice_list_list.map { |list| list.join(",") }.join(" + "),
          "成功数#{success_count}",
          @game_system.grich_text(one_count, dice_list.size, success_count),
        ].compact

        result_with_text(sequence.join(" ＞ "))
      end

      private

      def cmp_op
        @cmp_op || @game_system.default_cmp_op
      end

      def target_number
        @target_number || @game_system.default_target_number
      end

      def reroll_threshold
        @reroll_threshold || @game_system.reroll_dice_reroll_threshold || target_number
      end

      def valid_command?(dice_queue)
        reroll_threshold && dice_queue.all? { |d| valid_reroll_rule?(d[1], @reroll_cmp_op, reroll_threshold) }
      end

      def roll(randomizer, dice_queue)
        dice_list_list = []
        loop_count = 0

        while !dice_queue.empty? && loop_count < REROLL_LIMIT
          # xRn
          x, n, depth = dice_queue.shift
          loop_count += 1

          dice_list = randomizer.roll_barabara(x, n)
          dice_list.sort! if @game_system.sort_barabara_dice?
          dice_list_list.push(dice_list)

          reroll_count = dice_list.count() { |val| val.send(@reroll_cmp_op, reroll_threshold) }
          if reroll_count > 0
            dice_queue.push([reroll_count, n, depth + 1])
          end
        end

        return dice_list_list
      end

      # @return [String]
      def expr()
        notation = @notations.map { |x, n| "#{x}R#{n}" } .join("+")
        reroll_cmp_op_text = Format.comparison_operator(@reroll_cmp_op) if cmp_op != @reroll_cmp_op
        cmp_op_text = Format.comparison_operator(cmp_op)

        "(#{notation}[#{reroll_cmp_op_text}#{reroll_threshold}]#{cmp_op_text}#{target_number})"
      end

      # @param command [String]
      # @return [String]
      def msg_invalid_reroll_number(command)
        "#{command} ＞ 条件が間違っています。2R6>=5 あるいは 2R6[5] のように振り足し目標値を指定してください。"
      end

      # @param sides [Integer]
      # @param cmp_op [Symbol]
      # @param reroll_threshold [Integer]
      # @return [Boolean]
      def valid_reroll_rule?(sides, cmp_op, reroll_threshold) # 振り足しロールの条件確認
        case cmp_op
        when :<=
          reroll_threshold < sides
        when :<
          reroll_threshold <= sides
        when :>=
          reroll_threshold > 1
        when :>
          reroll_threshold >= 1
        when :'!='
          (1..sides).include?(reroll_threshold)
        else
          true
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
