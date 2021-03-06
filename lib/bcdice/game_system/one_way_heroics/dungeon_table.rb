# frozen_string_literal: true

module BCDice
  module GameSystem
    class OneWayHeroics < Base
      class DungeonTable
        attr_reader :key

        def initialize(name, key, type, items)
          @name = name
          @key = key
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
          value += @times if day >= 4

          index = value - @times
          return "#{@name}(#{value}) ＞ #{@items[index]}"
        end
      end

      DUNGEON_TABLE = DungeonTable.new(
        "ダンジョン表",
        "DNGN",
        "1D6",
        [
          "犬小屋（１５５ページ）",
          "犬小屋（１５５ページ）",
          "「ダンジョン遭遇表」（１５３ページ）へ移動。小型ダンジョンだ。",
          "「ダンジョン遭遇表」（１５３ページ）へ移動。小型ダンジョンだ。",
          "「ダンジョン遭遇表」（１５３ページ）へ移動。ここは中型ダンジョンなので、モンスターが出現した場合、数が1体増加する。さらにイベントの経験値が1増加する。",
          "「ダンジョン遭遇表」（１５３ページ）へ移動。ここは大型ダンジョンなので、モンスターが出現した場合、数が2体増加する。さらにイベントの経験値が2増加する。",
          "牢獄遭遇表へ移動（１５４ページ）。牢獄つきダンジョン。",
        ]
      )

      DUNGEON_TABLE_PLUS = DungeonTable.new(
        "ダンジョン表プラス",
        "DNGNP",
        "2D6",
        [
          "犬小屋（基本１５５ページ）",
          "犬小屋（基本１５５ページ）",
          "犬小屋（基本１５５ページ）",
          "犬小屋（基本１５５ページ）",
          "「ダンジョン遭遇表」（基本１５３ページ）へ移動。小型ダンジョンだ。",
          "「ダンジョン遭遇表」（基本１５３ページ）へ移動。小型ダンジョンだ。",
          "「ダンジョン遭遇表」（基本１５３ページ）へ移動。ここは中型ダンジョンのため、モンスターが出現した場合、数が１体増加する。またイベントの【経験値】が１増加する。",
          "「ダンジョン遭遇表」（基本１５３ページ）へ移動。ここは大型ダンジョンのため、モンスターが出現した場合、数が２体増加する。またイベントの【経験値】が２増加する。",
          "「ダンジョン遭遇表」（基本１５３ページ）へ移動。近くに寄っただけで吸い込まれる罠のダンジョンだ。「ダンジョン遭遇表」を使用したあと、中央にあるモニュメントに触れて転移して出るか、【鉄格子】と戦闘して出るか選択する。転移した場合は闇の目の前に出てしまい、全力ダッシュで【ＳＴ】を１Ｄ６消費する。【鉄格子】との戦闘では逃走を選択できない。",
          "「ダンジョン遭遇表」（基本１５３ページ）へ移動。水浸しのダンジョンで、「ダンジョン遭遇表」を使用した直後に【ＳＴ】が３減少する。「水泳」",
          "水路に囲まれた水上遺跡だ。なかに入るなら【ＳＴ】を４消費（「水泳」）してから「ダンジョン遭遇表」（基本１５３ページ）へ移動。イベントの判定に成功すると追加で【豪華な宝箱】が１つ出現し、戦闘か開錠を試みられる。",
          "「牢獄遭遇表」（基本１５４ページ）へ移動。牢獄つきダンジョンだ。",
          "砂の遺跡にたどりつき、「牢獄遭遇表」（基本１５４ページ）へ移動。モンスターが出現した場合、数が２体増加する。またイベントの【経験値】が２増加する。イベントの判定に成功すると追加で【珍しい箱】が１つ出現し、戦闘か開錠を試みられる。",
        ]
      )
    end
  end
end
