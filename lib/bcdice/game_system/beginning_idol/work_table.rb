# frozen_string_literal: true

module BCDice
  module GameSystem
    class BeginningIdol < Base
      class WorkWithChanceTable < DiceTable::D66Table
        def self.from_i18n(key, locale)
          table = I18n.t(key, locale: locale)
          sort_type = D66SortType.const_get(table[:d66_sort_type])

          new(table[:name], sort_type, table[:items], locale)
        end

        def initialize(name, sort_type, items, locale)
          super(name, sort_type, items)
          @regexp = Regexp.new(I18n.t("BeginningIdol.with_chance.regexp", locale: locale))
          @off = I18n.t("BeginningIdol.with_chance.off_text", locale: locale)
        end

        def roll_command(randomizer, command)
          m = /^LO([1-6]{1,2})?$/.match(command)
          unless m
            return nil
          end

          roll(randomizer, m[1]&.to_i)
        end

        def roll(randomizer, chance = nil)
          chosen = super(randomizer)
          unless chance
            return chosen
          end

          m = @regexp.match(chosen.body)
          if m && m[1].to_i >= chance
            DiceTable::RollResult.new(chosen.table_name, chosen.value, @off)
          elsif m
            DiceTable::RollResult.new(chosen.table_name, chosen.value, chosen.body.sub(@regexp, ""))
          else
            chosen
          end
        end
      end

      class << self
        private

        def translate_local_work_table(locale)
          WorkWithChanceTable.from_i18n("BeginningIdol.local_work", locale)
        end
      end

      register_prefix("LO")
    end
  end
end
