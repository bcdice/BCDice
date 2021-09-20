# frozen_string_literal: true

module BCDice
  module GameSystem
    class BeginningIdol < Base
      class << self
        private

        # @params locale [Symbol]
        # @return [ChainTable]
        def translate_accessories_table(locale)
          items = I18n.t("BeginningIdol.ACT.items", locale: locale)
          subtables = [
            DiceTable::D66Table.from_i18n("BeginningIdol.ACT.subtables.head", locale),
            DiceTable::D66Table.from_i18n("BeginningIdol.ACT.subtables.hat", locale),
            DiceTable::D66Table.from_i18n("BeginningIdol.ACT.subtables.body", locale),
            DiceTable::D66Table.from_i18n("BeginningIdol.ACT.subtables.arm", locale),
            DiceTable::D66Table.from_i18n("BeginningIdol.ACT.subtables.foot", locale),
            DiceTable::D66Table.from_i18n("BeginningIdol.ACT.subtables.other", locale),
          ]

          ChainTable.new(
            I18n.t("BeginningIdol.ACT.name", locale: locale),
            "1D6",
            items.zip(subtables)
          )
        end
      end
    end
  end
end
