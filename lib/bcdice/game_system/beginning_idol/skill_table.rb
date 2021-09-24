# frozen_string_literal: true

module BCDice
  module GameSystem
    class BeginningIdol < Base
      class SkillTable < DiceTable::SaiFicSkillTable
        def roll(randomizer)
          roll_command(randomizer, "RTT")
        end
      end

      class SkillGetTable < DiceTable::Table
        def self.from_i18n(key, skill_table, locale)
          table = I18n.t(key, locale: locale)
          new(table[:name], table[:type], table[:items], skill_table, locale)
        end

        def initialize(name, type, items, skill_table, locale)
          super(name, type, items)
          @skill_table = skill_table

          skill_get_table = I18n.t("BeginningIdol.skill_get_table", locale: locale)
          @reroll_reg = Regexp.new(skill_get_table[:reroll_reg])
          @reroll = skill_get_table[:reroll]
          @secondary_name = skill_get_table[:secondary_name]
        end

        def roll(randomizer)
          chosen = super(randomizer)

          m = @reroll_reg.match(chosen.body)
          unless m
            return chosen
          end

          reroll_category = m.captures
          body = chosen.body + "\n"
          loop do
            skill = @skill_table.roll_skill(randomizer)
            body += "#{@secondary_name} ＞ [#{skill.category_dice},#{skill.row_dice}] ＞ #{skill}"
            unless reroll_category.include?(skill.category_name)
              break
            end

            body += " ＞ #{@reroll}\n"
          end

          DiceTable::RollResult.new(chosen.table_name, chosen.value, body)
        end
      end

      class SkillHometown
        def initialize(skill_table)
          @skill_name = skill_table
        end

        def roll(randomizer)
          @skill_name.roll_command(randomizer, "AT6")
        end
      end
    end
  end
end
