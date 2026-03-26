# frozen_string_literal: true

require 'bcdice/base'
require 'bcdice/dice_table/range_table'
require 'bcdice/dice_table/table'
require "bcdice/format"

module BCDice
  module GameSystem
    class BlackJacket < Base
      # ゲームシステムの識別子
      ID = 'BlackJacket'

      # ゲームシステム名
      NAME = 'ブラックジャケットRPG'

      # ゲームシステム名の読みがな
      SORT_KEY = 'ふらつくしあけつとRPG'

      # ダイスボットの使い方
      HELP_MESSAGE = <<~INFO_MESSAGE_TEXT
        ・行為判定（BJx）
        　x：成功率
        　例）BJ80
        　クリティカル、ファンブルの自動的判定を行います。
        　「BJ50+20-30」のように加減算記述も可能。
        　成功率は上限100％、下限０％
        ・デスチャート(DCxY)
        　x：チャートの種類。肉体：DCL、精神：DCS、環境：DCC
        　Y=マイナス値
        　例）DCL5：ライフが -5 の判定
        　　　DCS3：サニティーが -3 の判定
        　　　DCC0：クレジット 0 の判定
        ・チャレンジ・ペナルティ・チャート（CPC）
        ・サイドトラック・チャート（STC）
      INFO_MESSAGE_TEXT

      register_prefix(
        'BJ',
        'DC[LSC]',
        'CPC',
        'STC'
      )

      def eval_game_system_specific_command(command)
        resolute_action(command) || roll_death_chart(command) || roll_tables(command, self.class::TABLES)
      end

      private

      def resolute_action(command)
        m = /^BJ(\d+([+-]\d+)*)$/.match(command)
        unless m
          return nil
        end

        success_rate = ArithmeticEvaluator.eval(m[1])

        roll_result, dice10, dice01 = roll_d100
        roll_result_text = format('%02d', roll_result)

        result = action_result(roll_result, dice10, dice01, success_rate)

        sequence = [
          translate("BlackJacket.action_judge", rate: success_rate),
          "1D100[#{dice10},#{dice01}]=#{roll_result_text}",
          roll_result_text.to_s,
          result.text
        ]

        result.text = sequence.join(" ＞ ")
        result
      end

      def action_result(total, tens, ones, success_rate)
        if total == 100
          Result.fumble(translate("BlackJacket.misery"))
        elsif success_rate <= 0
          Result.fumble(translate("BlackJacket.fumble"))
        elsif total <= success_rate - 100
          Result.critical(translate("BlackJacket.critical"))
        elsif tens == ones
          if total <= success_rate
            Result.critical(translate("BlackJacket.critical"))
          else
            Result.fumble(translate("BlackJacket.fumble"))
          end
        elsif total <= success_rate
          Result.success(translate("success"))
        else
          Result.failure(translate("failure"))
        end
      end

      def roll_d100
        dice10 = @randomizer.roll_once(10)
        dice10 = 0 if dice10 == 10
        dice01 = @randomizer.roll_once(10)
        dice01 = 0 if dice01 == 10

        roll_result = dice10 * 10 + dice01
        roll_result = 100 if roll_result == 0

        return roll_result, dice10, dice01
      end

      class DeathChart
        def initialize(name, chart)
          @name = name
          @chart = chart.freeze

          if @chart.size != 11
            raise ArgumentError, "unexpected chart size #{name.inspect} (given #{@chart.size}, expected 11)"
          end
        end

        # @param randomizer [Randomizer]
        # @param minus_score [Integer]
        # @param locale [Symbol]
        # @return [String]
        def roll(randomizer, minus_score, locale)
          dice = randomizer.roll_once(10)
          key_number = dice + minus_score

          key_text, chosen = at(key_number, locale)

          return I18n.translate("BlackJacket.death_chart_result", locale: locale, name: @name, minus: minus_score, dice: dice, key: key_number, key_text: key_text, chosen: chosen)
        end

        private

        # key_numberの10から20がindexの0から10に対応する
        def at(key_number, locale)
          if key_number < 10
            [I18n.translate("BlackJacket.death_chart_under", locale: locale), @chart.first]
          elsif key_number > 20
            [I18n.translate("BlackJacket.death_chart_over", locale: locale), @chart.last]
          else
            [key_number.to_s, @chart[key_number - 10]]
          end
        end
      end

      def roll_death_chart(command)
        m = /^DC([LSC])(\d+)$/i.match(command)
        unless m
          return m
        end

        chart = self.class::DEATH_CHARTS[m[1]]
        minus_score = m[2].to_i

        return chart.roll(@randomizer, minus_score, @locale)
      end

      class << self
        private

        def translate_tables(locale)
          {
            "CPC" => DiceTable::Table.from_i18n("BlackJacket.table.CPC", locale),
            "STC" => DiceTable::Table.from_i18n("BlackJacket.table.STC", locale),
          }
        end

        def translate_death_charts(locale)
          {
            'L' => DeathChart.new(
              I18n.translate("BlackJacket.chart_name.physical", locale: locale),
              I18n.translate("BlackJacket.death_charts.physical", locale: locale)
            ),
            'S' => DeathChart.new(
              I18n.translate("BlackJacket.chart_name.mental", locale: locale),
              I18n.translate("BlackJacket.death_charts.mental", locale: locale)
            ),
            'C' => DeathChart.new(
              I18n.translate("BlackJacket.chart_name.social", locale: locale),
              I18n.translate("BlackJacket.death_charts.social", locale: locale)
            ),
          }
        end
      end

      TABLES       = translate_tables(:ja_jp).freeze
      DEATH_CHARTS = translate_death_charts(:ja_jp).freeze
    end
  end
end
