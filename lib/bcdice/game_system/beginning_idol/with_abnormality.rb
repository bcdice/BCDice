# frozen_string_literal: true

module BCDice
  module GameSystem
    class BeginningIdol < Base
      module WithAbnormality
        def replace_abnormality(chosen, randomizer)
          reg = Regexp.new(I18n.t("BeginningIdol.abnormality.regexp", locale: @locale))
          m = reg.match(chosen.body)
          unless m
            return chosen
          end

          abno_count = kanji_to_i(m[1])
          unless abno_count
            return chosen
          end

          text = @bad_status_table.roll(randomizer, abno_count)
          new_body = chosen.body.sub(reg, text)

          return DiceTable::RollResult.new(chosen.table_name, chosen.value, new_body)
        end

        def kanji_to_i(kanji)
          list = I18n.t("BeginningIdol.abnormality.num_map", locale: @locale)
          list.find_index(kanji)&.succ
        end
      end

      class D66WithAbnormality < DiceTable::D66Table
        include WithAbnormality

        def self.from_i18n(key, bad_status_table, locale)
          table = I18n.t(key, locale: locale)
          sort_type = D66SortType.const_get(table[:d66_sort_type])

          new(table[:name], sort_type, table[:items], bad_status_table, locale)
        end

        def initialize(name, sort_type, items, bad_status_table, locale)
          super(name, sort_type, items)
          @bad_status_table = bad_status_table
          @locale = locale
        end

        def roll(randomizer)
          chosen = super(randomizer)
          replace_abnormality(chosen, randomizer)
        end
      end

      class TableWithAbnormality < DiceTable::Table
        include WithAbnormality

        def self.from_i18n(key, bad_status_table, locale)
          table = I18n.t(key, locale: locale)
          new(table[:name], table[:type], table[:items], bad_status_table, locale)
        end

        def initialize(name, type, items, bad_status_table, locale)
          super(name, type, items)
          @bad_status_table = bad_status_table
          @locale = locale
        end

        def roll(randomizer)
          chosen = super(randomizer)
          replace_abnormality(chosen, randomizer)
        end
      end
    end
  end
end
