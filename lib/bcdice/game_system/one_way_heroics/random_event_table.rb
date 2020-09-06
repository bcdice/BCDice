module BCDice
  module GameSystem
    class OneWayHeroics < Base
      class RandomEventTable
        def initialize(name, type, items)
          @name = name
          @items = items.freeze

          m = /(\d+)D(\d+)/i.match(type)
          unless m
            raise ArgumentError, "Unexpected table type: #{type}"
          end

          @times = m[1].to_i
          @sides = m[2].to_i
        end

        def roll_with_day(day, randomizer)
          value = randomizer.roll_sum(@times, @sides)
          index = value - 1

          chosen = @items[index]
          chosen =
            if chosen.respond_to?(:roll)
              chosen.roll(randomizer)
            elsif chosen.respond_to?(:roll_with_day)
              chosen.roll_with_day(day, randomizer)
            else
              chosen
            end

          return "#{@name}(#{value}) ＞ #{chosen}"
        end
      end

      class BranchByDay
        def initialize(text, less_than_equal, greater)
          @text = text
          @greater = greater
          @less_than_equal = less_than_equal
        end

        def roll_with_day(day, randomizer)
          value = randomizer.roll_once(6)
          chosen = choise(value, day)

          chosen =
            if chosen.respond_to?(:roll_with_day)
              "#{chosen.key}#{day} ＞ #{chosen.roll_with_day(day, randomizer)}"
            elsif chosen.ascii_only?
              [chosen, TABLES[chosen].roll(randomizer)].join(" ＞ ")
            else
              chosen
            end

          result = <<~RESULT.chomp
            #{@text} ＞
             1D6 ＞ #{value} ＞ #{branch_result(value, day)} ＞
             #{chosen}
          RESULT
          return result
        end

        def choise(value, day)
          raise NotImplementedError
        end

        def branch_result(value, day)
          raise NotImplementedError
        end
      end

      class BranchByElapsedDays < BranchByDay
        def choise(value, day)
          value > day ? @greater : @less_than_equal
        end

        def branch_result(value, day)
          if value > day
            "日数[#{day}]を超えている"
          else
            "日数[#{day}]以下"
          end
        end
      end

      class BranchByDayParity < BranchByDay
        def choise(value, _)
          value.odd? ? @greater : @less_than_equal
        end

        def branch_result(value, _)
          if value.odd?
            "奇数"
          else
            "偶数"
          end
        end
      end

      class MoveToTableWithDay
        def initialize(text, table)
          @text = text
          @table = table
        end

        def roll_with_day(day, randomizer)
          <<~RESULT.chomp
            #{@text} ＞
             #{@table.key}#{day} ＞ #{@table.roll_with_day(day, randomizer)}
          RESULT
        end
      end

      RANDOM_EVENT_TABLE = RandomEventTable.new(
        "ランダムイベント表",
        "1D6",
        [
          BranchByElapsedDays.new(
            "さらに１Ｄ６を振る。現在ＰＣがいるエリアの【日数】以下なら「施設表」へ移動。【日数】を超えていれば「ダンジョン表」（１５３ページ）へ移動。",
            "FCLT",
            DUNGEON_TABLE
          ),
          BranchByElapsedDays.new(
            "さらに１Ｄ６を振る。現在ＰＣがいるエリアの【日数】以下なら「世界の旅表」（１５７ページ）へ移動。【日数】を超えていれば「野外遭遇表(OUTENC)」（１５５ページ）へ移動。",
            "「世界の旅表」（１５７ページ）へ。",
            "OUTENC"
          ),
          MoveToTable.new("「施設表」へ移動。", "FCLT"),
          "「世界の旅表」（１５７ページ）へ移動。",
          MoveToTable.new("「野外遭遇表」（１５５ページ）へ移動。", "OUTENC"),
          MoveToTableWithDay.new("「ダンジョン表」（１５２ページ）へ移動。", DUNGEON_TABLE),
        ]
      )

      RANDOM_EVENT_TABLE_PLUS = RandomEventTable.new(
        "ランダムイベント表プラス",
        "1D6",
        [
          BranchByElapsedDays.new(
            "さらに1D6を振る。現在PCがいるエリアの【日数】以下なら施設表プラス（０２２ページ）へ移動。【経過日数】を超えていればダンジョン表プラス（０２５ページ）へ移動",
            "FCLTP",
            DUNGEON_TABLE_PLUS
          ),
          BranchByElapsedDays.new(
            "さらに1D6を振る。現在PCがいるエリアの【日数】以下なら世界の旅表（基本１５７ページ）へ移動。【経過日数】を超えていれば野外遭遇表（基本１５５ページ）へ移動",
            "「世界の旅表」（１５７ページ）へ。",
            "OUTENC"
          ),
          BranchByElapsedDays.new(
            "さらに1D6を振る。現在PCがいるエリアの【日数】以下なら世界の旅表２（０２８ページ）へ移動。【経過日数】を超えていれば野外遭遇表プラス（０２５ページ）へ移動",
            "世界の旅表２（０２８ページ）へ。",
            "OUTENCP"
          ),
          BranchByDayParity.new(
            "さらに1D6を振る。奇数なら世界の旅表（基本１５７ページ）へ移動。偶数なら世界の旅表２（０２８ページ）へ移動",
            "世界の旅表（基本１５７ページ）へ。",
            "世界の旅表２（０２８ページ）へ。"
          ),
          MoveToTable.new("施設表プラスへ移動（０２２ページ）", "FCLTP"),
          MoveToTableWithDay.new("ダンジョン表プラスへ移動（０２５ページ）", DUNGEON_TABLE_PLUS)
        ]
      )
    end
  end
end
