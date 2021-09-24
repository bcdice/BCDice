# frozen_string_literal: true

module BCDice
  module GameSystem
    class BeginningIdol < Base
      class MySkillNameTable
        # @param locale [Symbol]
        # @return [MySkillNameTable]
        def initialize(locale)
          @locale = locale

          article = DiceTable::Table.from_i18n("BeginningIdol.MS.subtables.article", locale)
          describe = DiceTable::D66Table.from_i18n("BeginningIdol.MS.subtables.describe", locale)
          scene = DiceTable::D66Table.from_i18n("BeginningIdol.MS.subtables.scene", locale)
          material = DiceTable::D66Table.from_i18n("BeginningIdol.MS.subtables.material", locale)
          action = DiceTable::D66Table.from_i18n("BeginningIdol.MS.subtables.action", locale)
          @chains = [
            [describe, scene, material],
            [describe, scene, action],
            [describe, material, action],
            [scene, material, action],
            [describe, scene, article],
            [material, action, article],
          ].freeze
        end

        # @param randomizer [BCDice::Randomizer]
        # @return [String]
        def roll(randomizer)
          index = randomizer.roll_once(6)
          chosens = @chains[index - 1].map { |t| t.roll(randomizer) }

          dice = chosens.map { |chosen| chosen.table_name + chosen.value.to_s }

          name = I18n.t("BeginningIdol.MS.name", locale: @locale)
          skill_name_format = I18n.t("BeginningIdol.MS.formats", locale: @locale)[index - 1]
          skill_name = format(skill_name_format, *chosens.map(&:body))

          "#{name} ＞ [#{index},#{dice.join(',')}] ＞ #{skill_name}"
        end
      end
    end
  end
end
