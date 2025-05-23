# frozen_string_literal: true

require "bcdice/base"
require "bcdice/game_system/sword_world/rating_parser"

module BCDice
  module GameSystem
    class SwordWorld < Base
      # ゲームシステムの識別子
      ID = 'SwordWorld'

      # ゲームシステム名
      NAME = 'ソード・ワールドRPG'

      # ゲームシステム名の読みがな
      SORT_KEY = 'そおとわあると'

      # ダイスボットの使い方
      HELP_MESSAGE = "・SW　レーティング表　(Kx[c]+m$f) (x:キー, c:クリティカル値, m:ボーナス, f:出目修正)\n"

      register_prefix('H?K')

      def initialize(command)
        super(command)
        @rating_table = 0
      end

      def result_2d6(total, dice_total, _dice_list, cmp_op, target)
        if dice_total >= 12
          Result.critical(translate('SwordWorld.critical'))
        elsif dice_total <= 2
          Result.fumble(translate('SwordWorld.fumble'))
        elsif cmp_op != :>= || target == "?"
          nil
        elsif total >= target
          Result.success(translate('success'))
        else
          Result.failure(translate('failure'))
        end
      end

      def eval_game_system_specific_command(command)
        rating(command)
      end

      private

      def rating_parser
        return RatingParser.new
      end

      ####################        SWレーティング表       ########################
      def rating(string) # レーティング表
        debug("rating string", string)
        command = rating_parser.parse(string)

        unless command
          debug("not matched")
          return '1'
        end

        # 2.0対応
        rate_sw2_0 = getSW2_0_RatingTable

        keyMax = rate_sw2_0.length - 1
        debug("keyMax", keyMax)
        if command.rate > keyMax
          return Result.new(translate('SwordWorld.keynumber_exceeds', keyMax: keyMax))
        end

        if command.infinite_roll?
          return Result.new(translate('SwordWorld.infinite_critical', min_critical: command.min_critical))
        end

        newRates = getNewRates(rate_sw2_0)

        output = "#{command} ＞ "

        diceResultTotals = []
        diceResults = []
        rateResults = []
        dice = 0
        diceOnlyTotal = 0
        totalValue = 0
        round = 0
        first_to = command.first_to
        first_modify = command.first_modify
        first_modify_ssp = command.first_modify_ssp

        loop do
          dice_raw, diceText = rollDice(command, round)
          dice = dice_raw

          if first_to != 0
            dice = dice_raw = first_to
            first_to = 0
          elsif first_modify != 0
            dice += first_modify
            first_modify = 0
          elsif first_modify_ssp != 0
            dice += first_modify_ssp if dice_raw <= 10
            first_modify_ssp = 0
          end

          # 出目がピンゾロの時にはそこで終了
          if dice_raw <= 2
            diceResultTotals << dice_raw.to_s
            diceResults << diceText.to_s
            rateResults << "**"

            round += 1
            break
          end

          dice += command.kept_modify if (command.kept_modify != 0) && (dice != 2)

          dice = 2 if dice < 2
          dice = 12 if dice > 12

          currentKey = (command.rate + round * command.rateup).clamp(0, keyMax)
          debug("currentKey", currentKey)
          rateValue = newRates[dice][currentKey]
          debug("rateValue", rateValue)

          totalValue += rateValue
          diceOnlyTotal += dice

          diceResultTotals << dice.to_s
          diceResults << diceText.to_s
          rateResults << (dice > 2 ? rateValue : "**")

          round += 1

          break unless dice >= command.critical
        end

        result_text, critical, fumble = getResultText(
          totalValue, command, diceResults, diceResultTotals,
          rateResults, diceOnlyTotal, round
        )
        output += result_text

        return Result.new.tap do |r|
          r.text = output
          r.critical = critical
          r.fumble = fumble
        end
      end

      def getSW2_0_RatingTable
        rate_sw2_0 = [
          # 0
          '*,0,0,0,1,2,2,3,3,4,4',
          '*,0,0,0,1,2,3,3,3,4,4',
          '*,0,0,0,1,2,3,4,4,4,4',
          '*,0,0,1,1,2,3,4,4,4,5',
          '*,0,0,1,2,2,3,4,4,5,5',
          '*,0,1,1,2,2,3,4,5,5,5',
          '*,0,1,1,2,3,3,4,5,5,5',
          '*,0,1,1,2,3,4,4,5,5,6',
          '*,0,1,2,2,3,4,4,5,6,6',
          '*,0,1,2,3,3,4,4,5,6,7',
          '*,1,1,2,3,3,4,5,5,6,7',
          # 11
          '*,1,2,2,3,3,4,5,6,6,7',
          '*,1,2,2,3,4,4,5,6,6,7',
          '*,1,2,3,3,4,4,5,6,7,7',
          '*,1,2,3,4,4,4,5,6,7,8',
          '*,1,2,3,4,4,5,5,6,7,8',
          '*,1,2,3,4,4,5,6,7,7,8',
          '*,1,2,3,4,5,5,6,7,7,8',
          '*,1,2,3,4,5,6,6,7,7,8',
          '*,1,2,3,4,5,6,7,7,8,9',
          '*,1,2,3,4,5,6,7,8,9,10',
          # 21
          '*,1,2,3,4,6,6,7,8,9,10',
          '*,1,2,3,5,6,6,7,8,9,10',
          '*,2,2,3,5,6,7,7,8,9,10',
          '*,2,3,4,5,6,7,7,8,9,10',
          '*,2,3,4,5,6,7,8,8,9,10',
          '*,2,3,4,5,6,8,8,9,9,10',
          '*,2,3,4,6,6,8,8,9,9,10',
          '*,2,3,4,6,6,8,9,9,10,10',
          '*,2,3,4,6,7,8,9,9,10,10',
          '*,2,4,4,6,7,8,9,10,10,10',
          # 31
          '*,2,4,5,6,7,8,9,10,10,11',
          '*,3,4,5,6,7,8,10,10,10,11',
          '*,3,4,5,6,8,8,10,10,10,11',
          '*,3,4,5,6,8,9,10,10,11,11',
          '*,3,4,5,7,8,9,10,10,11,12',
          '*,3,5,5,7,8,9,10,11,11,12',
          '*,3,5,6,7,8,9,10,11,12,12',
          '*,3,5,6,7,8,10,10,11,12,13',
          '*,4,5,6,7,8,10,11,11,12,13',
          '*,4,5,6,7,9,10,11,11,12,13',
          # 41
          '*,4,6,6,7,9,10,11,12,12,13',
          '*,4,6,7,7,9,10,11,12,13,13',
          '*,4,6,7,8,9,10,11,12,13,14',
          '*,4,6,7,8,10,10,11,12,13,14',
          '*,4,6,7,9,10,10,11,12,13,14',
          '*,4,6,7,9,10,10,12,13,13,14',
          '*,4,6,7,9,10,11,12,13,13,15',
          '*,4,6,7,9,10,12,12,13,13,15',
          '*,4,6,7,10,10,12,12,13,14,15',
          '*,4,6,8,10,10,12,12,13,15,15',
          # 51
          '*,5,7,8,10,10,12,12,13,15,15',
          '*,5,7,8,10,11,12,12,13,15,15',
          '*,5,7,9,10,11,12,12,14,15,15',
          '*,5,7,9,10,11,12,13,14,15,16',
          '*,5,7,10,10,11,12,13,14,16,16',
          '*,5,8,10,10,11,12,13,15,16,16',
          '*,5,8,10,11,11,12,13,15,16,17',
          '*,5,8,10,11,12,12,13,15,16,17',
          '*,5,9,10,11,12,12,14,15,16,17',
          '*,5,9,10,11,12,13,14,15,16,18',
          # 61
          '*,5,9,10,11,12,13,14,16,17,18',
          '*,5,9,10,11,13,13,14,16,17,18',
          '*,5,9,10,11,13,13,15,17,17,18',
          '*,5,9,10,11,13,14,15,17,17,18',
          '*,5,9,10,12,13,14,15,17,18,18',
          '*,5,9,10,12,13,15,15,17,18,19',
          '*,5,9,10,12,13,15,16,17,19,19',
          '*,5,9,10,12,14,15,16,17,19,19',
          '*,5,9,10,12,14,16,16,17,19,19',
          '*,5,9,10,12,14,16,17,18,19,19',
          # 71
          '*,5,9,10,13,14,16,17,18,19,20',
          '*,5,9,10,13,15,16,17,18,19,20',
          '*,5,9,10,13,15,16,17,19,20,21',
          '*,6,9,10,13,15,16,18,19,20,21',
          '*,6,9,10,13,16,16,18,19,20,21',
          '*,6,9,10,13,16,17,18,19,20,21',
          '*,6,9,10,13,16,17,18,20,21,22',
          '*,6,9,10,13,16,17,19,20,22,23',
          '*,6,9,10,13,16,18,19,20,22,23',
          '*,6,9,10,13,16,18,20,21,22,23',
          # 81
          '*,6,9,10,13,17,18,20,21,22,23',
          '*,6,9,10,14,17,18,20,21,22,24',
          '*,6,9,11,14,17,18,20,21,23,24',
          '*,6,9,11,14,17,19,20,21,23,24',
          '*,6,9,11,14,17,19,21,22,23,24',
          '*,7,10,11,14,17,19,21,22,23,25',
          '*,7,10,12,14,17,19,21,22,24,25',
          '*,7,10,12,14,18,19,21,22,24,25',
          '*,7,10,12,15,18,19,21,22,24,26',
          '*,7,10,12,15,18,19,21,23,25,26',
          # 91
          '*,7,11,13,15,18,19,21,23,25,26',
          '*,7,11,13,15,18,20,21,23,25,27',
          '*,8,11,13,15,18,20,22,23,25,27',
          '*,8,11,13,16,18,20,22,23,25,28',
          '*,8,11,14,16,18,20,22,23,26,28',
          '*,8,11,14,16,19,20,22,23,26,28',
          '*,8,12,14,16,19,20,22,24,26,28',
          '*,8,12,15,16,19,20,22,24,27,28',
          '*,8,12,15,17,19,20,22,24,27,29',
          '*,8,12,15,18,19,20,22,24,27,30',
        ]

        return rate_sw2_0
      end

      def getNewRates(rate_sw2_0)
        rate_3 = []
        rate_4 = []
        rate_5 = []
        rate_6 = []
        rate_7 = []
        rate_8 = []
        rate_9 = []
        rate_10 = []
        rate_11 = []
        rate_12 = []
        zeroArray = []

        rate_sw2_0.each do |rateText|
          rate_arr = rateText.split(/,/)
          zeroArray.push(0)
          rate_3.push(rate_arr[1].to_i)
          rate_4.push(rate_arr[2].to_i)
          rate_5.push(rate_arr[3].to_i)
          rate_6.push(rate_arr[4].to_i)
          rate_7.push(rate_arr[5].to_i)
          rate_8.push(rate_arr[6].to_i)
          rate_9.push(rate_arr[7].to_i)
          rate_10.push(rate_arr[8].to_i)
          rate_11.push(rate_arr[9].to_i)
          rate_12.push(rate_arr[10].to_i)
        end

        if @rating_table == 1
          # 完全版準拠に差し替え
          rate_12[31] = rate_12[32] = rate_12[33] = 10
        end

        newRates = [zeroArray, zeroArray, zeroArray, rate_3, rate_4, rate_5, rate_6, rate_7, rate_8, rate_9, rate_10, rate_11, rate_12]

        return newRates
      end

      def rollDice(_command, _round)
        dice_list = @randomizer.roll_barabara(2, 6)
        total = dice_list.sum()
        dice_str = dice_list.join(",")
        return total, dice_str
      end

      # @param rating_total [Integer]
      # @param command [SwordWorld::RatingParsed]
      # @param diceResults [Array<String>]
      # @param diceResultTotals [Array<String>]
      # @param rateResults  [Array<String>]
      # @param dice_total [Integer]
      # @param round [Integer]
      # @return [Array(String, Boolean, Boolean)] output, critical, fumble
      def getResultText(rating_total, command, diceResults, diceResultTotals,
                        rateResults, dice_total, round)
        sequence = []

        sequence.push("2D:[#{diceResults.join(' ')}]=#{diceResultTotals.join(',')}")

        if dice_total <= 2
          sequence.push(rateResults.join(','))
          sequence.push(translate("SwordWorld.fumble"))
          return sequence.join(" ＞ "), false, true
        end

        # rate回数が1回で、修正値がない時には途中式と最終結果が一致するので、途中式を省略する
        if rateResults.size > 1 || command.modifier != 0
          text = rateResults.join(',') + Format.modifier(command.modifier)
          if command.half
            text = "(#{text})/2"
            if command.modifier_after_half != 0
              text += Format.modifier(command.modifier_after_half)
            end
          elsif command.one_and_a_half
            text = "(#{text})*1.5"
            if command.modifier_after_one_and_a_half != 0
              text += Format.modifier(command.modifier_after_one_and_a_half)
            end
          end
          sequence.push(text)
        elsif command.half
          text = "#{rateResults.first}/2"
          if command.modifier_after_half != 0
            text += Format.modifier(command.modifier_after_half)
          end
          sequence.push(text)
        elsif command.one_and_a_half
          text = "#{rateResults.first}*1.5"
          if command.modifier_after_one_and_a_half != 0
            text += Format.modifier(command.modifier_after_one_and_a_half)
          end
          sequence.push(text)
        end

        if round > 1
          round_text = translate("SwordWorld.round_text", reroll_count: round - 1)
          sequence.push(round_text)
        end

        total = rating_total + command.modifier
        if command.half
          total = (total / 2.0).ceil
          if command.modifier_after_half != 0
            total += command.modifier_after_half
          end
        elsif command.one_and_a_half
          total = (total * 1.5).ceil
          if command.modifier_after_one_and_a_half != 0
            total += command.modifier_after_one_and_a_half
          end
        end

        total_text = total.to_s
        sequence.push(total_text)

        return sequence.join(" ＞ "), round > 1, false
      end
    end
  end
end
