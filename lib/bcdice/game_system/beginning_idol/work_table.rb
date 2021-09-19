# frozen_string_literal: true

module BCDice
  module GameSystem
    class BeginningIdol < Base
      private

      class WorkWithChanceTable < DiceTable::D66Table
        def roll(randomizer, chance)
          chosen = super(randomizer)
          unless chance
            return chosen
          end

          m = /チャンスが(\d{1,2})以下ならオフ。/.match(chosen.body)
          if m && m[1].to_i >= chance
            DiceTable::RollResult.new(chosen.table_name, chosen.value, "オフ")
          elsif m
            DiceTable::RollResult.new(chosen.table_name, chosen.value, chosen.body.sub(/チャンスが(\d{1,2})以下ならオフ。/, ""))
          else
            chosen
          end
        end
      end

      LocalWorkTable = WorkWithChanceTable.new(
        "地方アイドル仕事表",
        D66SortType::ASC,
        {
          11 => "オフ",
          12 => "オフ",
          13 => "握手会をすることになった。遠方から自分たち目当てにやって来るお客さんも多数見える。チャンスが5以下ならオフ。\n特技 : 《アイドル／趣味12》",
          14 => "ミニコンサートが全国放送で小さく紹介される。ちょっとだけ、外見が注目されたみたいだ。チャンスが4以下ならオフ。\n特技 : 《スタイル／才能3》",
          15 => "地元ラジオ局で自分たちの番組が始まる。チャンスが3以下ならオフ。\n特技 : 《キャラ分野の空白／趣味7》",
          16 => "地元のテレビ局にゲスト出演。うまく自分たちを紹介できるだろうか？　チャンスが3以下ならオフ。\n特技 : 好きな出身分野の特技",
          22 => "オフ",
          23 => "街頭でティッシュ配りの手伝いをする。笑顔を忘れずに、がんばろう。\n特技 : 《笑顔／才能7》",
          24 => "地元のお手伝いの一環として、害虫退治に駆り出された。なぜ、こんなことに。\n特技 : 《胆力／才能5》",
          25 => "畑仕事のお手伝いをすることになった。とりあえず、体力が要求される。\n特技 : 《体力／才能6》",
          26 => "ショッピングモールのお手伝いをすることになった。うまくお手伝いができれば、繁盛するかも。\n特技 : 《ショッピング／趣味8》",
          33 => "オフ",
          34 => "インターネットラジオに出演。声とトークで。地域のことを伝えていこう。\n特技 : 《異国文化／才能2》",
          35 => "地元のテレビ局の取材が入る。テーマは、地方でがんばっている人たちだ。\n特技 : 《元気／キャラ8》",
          36 => "デパートで風船を配るお手伝い。子どもたち相手のお仕事は、ちょっと大変です。\n特技 : 《気配り／才能9》",
          44 => "オフ",
          45 => "着ぐるみを着て、市民と交流。暑くてつらい仕事だけど、大切な交流の時間です。\n特技 : 《バーニング／属性10》",
          46 => "観光地の物販コーナーで地元の特産品を売るお手伝い。地方アイドル的に、大切なお仕事。\n特技 : 好きな出身分野の特技",
          55 => "オフ",
          56 => "動画サイトのチャンネルで、自分たちの宣伝を行なうことに。世界中に発信！\n特技 : 《スター／属性12》",
          66 => "オフ",
        }
      )

      register_prefix("LO")

      def roll_work_table(command)
        if (m = /^LO([1-6]{1,2})?$/.match(command))
          LocalWorkTable.roll(@randomizer, m[1]&.to_i)
        end
      end
    end
  end
end
