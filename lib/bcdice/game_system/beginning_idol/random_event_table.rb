# frozen_string_literal: true

module BCDice
  module GameSystem
    class BeginningIdol < Base
      class RandomEventTable
        # @param locale [Symbol]
        # @return [MySkillNameTable]
        def initialize(locale)
          @locale = locale
        end

        # @param randomizer [BCDice::Randomizer]
        # @return [String]
        def roll(randomizer)
          first_index = randomizer.roll_once(6)
          d66_index = randomizer.roll_d66(D66SortType::NO_SORT)

          i18n_key = first_index.even? ? "BeginningIdol.RE.on_event" : "BeginningIdol.RE.off_event"
          table = I18n.t(i18n_key, locale: @locale)
          name = I18n.t("BeginningIdol.RE.name", locale: @locale)
          result_format = I18n.t("BeginningIdol.RE.format", locale: @locale)

          chosen = table[:items][d66_index]

          return "#{name} ＞ (1D6) ＞ #{first_index}\n#{table[:name]} ＞ [#{d66_index}] ＞ #{format(result_format, event: chosen[0], page: chosen[1])}"
        end
      end
    end
  end
end
