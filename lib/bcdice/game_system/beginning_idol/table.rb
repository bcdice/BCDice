# frozen_string_literal: true

module BCDice
  module GameSystem
    class BeginningIdol < Base
      private

      class SkillTable < DiceTable::SaiFicSkillTable
        def roll(randomizer)
          roll_command(randomizer, "RTT")
        end
      end

      SKILL_TABLE = SkillTable.new(
        [
          ["身長", ["～125", "131", "136", "141", "146", "156", "166", "171", "176", "180", "190～"]],
          ["属性", ["エスニック", "ダーク", "セクシー", "フェミニン", "キュート", "プレーン", "パッション", "ポップ", "バーニング", "クール", "スター"]],
          ["才能", ["異国文化", "スタイル", "集中力", "胆力", "体力", "笑顔", "運動神経", "気配り", "学力", "セレブ", "演技力"]],
          ["キャラ", ["中二病", "ミステリアス", "マイペース", "軟派", "語尾", "キャラ分野の空白", "元気", "硬派", "物腰丁寧", "どじ", "ばか"]],
          ["趣味", ["オカルト", "ペット", "スポーツ", "おしゃれ", "料理", "趣味分野の空白", "ショッピング", "ダンス", "ゲーム", "音楽", "アイドル"]],
          ["出身", ["沖縄", "九州地方", "四国地方", "中国地方", "近畿地方", "中部地方", "関東地方", "北陸地方", "東北地方", "北海道", "海外"]],
        ],
        rtt: "AT",
        rttn: ["AT1", "AT2", "AT3", "AT4", "AT5", "AT6"]
      )

      class SkillGetTable < DiceTable::Table
        def roll(randomizer)
          chosen = super(randomizer)

          m = /身長分野、(属性|才能)分野、出身分野が出たら振り直し/.match(chosen.body)
          unless m
            return chosen
          end

          reroll_category = ["身長", m[1], "出身"]
          body = chosen.body + "\n"
          loop do
            skill = SKILL_TABLE.roll_skill(randomizer)
            body += "特技リスト ＞ [#{skill.category_dice},#{skill.row_dice}] ＞ #{skill}"
            unless reroll_category.include?(skill.category_name)
              break
            end

            body += " ＞ 振り直し\n"
          end

          DiceTable::RollResult.new(chosen.table_name, chosen.value, body)
        end
      end

      module SkillHometown
        module_function

        def roll(randomizer)
          SKILL_TABLE.roll_command(randomizer, "AT6")
        end
      end

      TABLE = {
        "SGT" => SkillGetTable.new(
          "アイドルスキル修得表(チャレンジガールズ)",
          "1D6",
          [
            "シーンプレイヤーが修得している才能分野の特技が指定特技のアイドルスキル",
            "シーンプレイヤーが修得しているキャラ分野の特技が指定特技のアイドルスキル",
            "シーンプレイヤーが修得している趣味分野の特技が指定特技のアイドルスキル",
            "ランダムに決定した特技が指定特技のアイドルスキル(身長分野、属性分野、出身分野が出たら振り直し)",
            "《メンタルアップ》《パフォーマンスアップ》《アイテムアップ》のうちいずれか1つ",
            "《メンタルアップ》《パフォーマンスアップ》《アイテムアップ》のうちいずれか1つ",
          ]
        ),
        "RS" => SkillGetTable.new(
          "アイドルスキル修得表(ロードトゥプリンス)",
          "1D6",
          [
            "シーンプレイヤーが修得している属性分野の特技が指定特技のアイドルスキル",
            "シーンプレイヤーが修得しているキャラ分野の特技が指定特技のアイドルスキル",
            "シーンプレイヤーが修得している趣味分野の特技が指定特技のアイドルスキル",
            "ランダムに決定した特技が指定特技のアイドルスキル(身長分野、才能分野、出身分野が出たら振り直し)",
            "《メンタルディフェンス》《判定アップ》《個性アップ》のうちいずれか1つ",
            "《メンタルディフェンス》《判定アップ》《個性アップ》のうちいずれか1つ",
          ]
        ),
        "HA" => ChainD66Table.new(
          "ハプニング表",
          {
            11 => ["ハプニングなし"],
            12 => ["ハプニングなし"],
            13 => ["ハプニングなし"],
            14 => ["ハプニングなし"],
            15 => ["ハプニングなし"],
            16 => ["ハプニングなし"],
            22 => ["パートナープレイヤーに、地方からオファーが来た。その土地独特の文化を学んで、パートナープレイヤーに伝えよう。", SkillHometown],
            23 => ["グラビア撮影だが、用意された衣装のサイズがパートナープレイヤーに合わなかった。何とかして、衣装を合わせなければいけない。", "特技 : パートナープレイヤーが修得している身長分野の特技"],
            24 => ["ダンス撮影中。パートナープレイヤーのダンスに迷いが見えた。何かアドバイスをして、迷いを取り払いたい。", "特技 : 《ダンス／趣味9》"],
            25 => ["歌の仕事だが、パートナープレイヤーの歌がどこかぎこちない。うまく本来の歌を取り戻させよう。", "特技 : パートナープレイヤーが修得している属性分野の特技"],
            26 => ["体力を消費する仕事の最中に、パートナープレイヤーが倒れてしまった！　急いで処置をしなければ！", "特技 : 《気配り／才能9》"],
            33 => ["パートナープレイヤーにマイナースポーツのCMが回ってきたが、知らない様子だ。ルールを教えよう。", "特技 : 《スポーツ／趣味4》"],
            34 => ["パートナープレイヤーのキャラに合わない仕事が舞い込んだ。演技力で乗り切ってほしい。", "特技 : 《演技力／才能12》"],
            35 => ["パートナープレイヤーが風邪をひいてしまう。次の仕事までに、なんとか治してもらわなければ。", "特技 : 《元気／キャラ8》"],
            36 => ["パートナープレイヤーの属性らしくない衣装が来てしまった。うまくアレンジできればいいけど。", "特技 : 《おしゃれ／趣味5》"],
            44 => ["パートナープレイヤーのテンションが低い。テンションを上げるようなことを言おう。", "特技 : 《バーニング／属性10》"],
            45 => ["パートナープレイヤーの仕事に必要な小道具が足りなくなった。調達しよう。", "特技 : 《ショッピング／趣味8》"],
            46 => ["パートナープレイヤーに外国から仕事が舞い込んできた。外国の文化に合わせた仕事をしなければ。", "特技 : 《異国文化／才能2》"],
            55 => ["パートナープレイヤーに大会社からの仕事のオファーがやって来る。プレッシャーに負けないように後押ししよう。", "特技 : 《胆力／才能5》"],
            56 => ["パートナープレイヤーと他のアイドルグループとのコラボイベントが行われる。そのアイドルの情報を集めてこよう。", "特技 : 《アイドル／趣味12》"],
            66 => ["パートナープレイヤーの周りで、幽霊騒ぎが起こる。安心させるためにも、調査に乗り出そう。", "特技 : 《オカルト／趣味2》"],
          }
        ),
        "RE" => RandomEventTable,
      }.freeze

      register_prefix(TABLE.keys)

      def roll_other_table(command)
        TABLE[command]&.roll(@randomizer)
      end

      class << self
        private

        def translate_tables(locale)
          costume_challenge_girls = CostumeTable.from_i18n("BeginningIdol.tables.DT", locale)
          costume_road_to_prince = CostumeTable.from_i18n("BeginningIdol.tables.RC", locale)
          costume_fortune_stars = CostumeTable.from_i18n("BeginningIdol.tables.FC", locale)

          bland = ChainTable.new(
            I18n.t("BeginningIdol.ACB.name", locale: locale),
            "1D6",
            [
              [I18n.t("BeginningIdol.ACB.items.challenge_girls", locale: locale), costume_challenge_girls.brand_only()],
              [I18n.t("BeginningIdol.ACB.items.challenge_girls", locale: locale), costume_challenge_girls.brand_only()],
              [I18n.t("BeginningIdol.ACB.items.road_to_prince", locale: locale), costume_road_to_prince.brand_only()],
              [I18n.t("BeginningIdol.ACB.items.road_to_prince", locale: locale), costume_road_to_prince.brand_only()],
              [I18n.t("BeginningIdol.ACB.items.fortune_stars", locale: locale), costume_fortune_stars.brand_only()],
              [I18n.t("BeginningIdol.ACB.items.fortune_stars", locale: locale), costume_fortune_stars.brand_only()],
            ]
          )

          {
            "DT" => costume_challenge_girls,
            "RC" => costume_road_to_prince,
            "FC" => costume_fortune_stars,
            "ACB" => bland,
            "CBT" => DiceTable::D66Table.from_i18n("BeginningIdol.tables.CBT", locale),
            "RCB" => DiceTable::D66Table.from_i18n("BeginningIdol.tables.RCB", locale),
            "HBT" => DiceTable::D66Table.from_i18n("BeginningIdol.tables.HBT", locale),
            "RHB" => DiceTable::D66Table.from_i18n("BeginningIdol.tables.RHB", locale),
            "RU" => DiceTable::Table.from_i18n("BeginningIdol.tables.RU", locale),
            "SIP" => DiceTable::Table.from_i18n("BeginningIdol.tables.SIP", locale),
            "BU" => DiceTable::Table.from_i18n("BeginningIdol.tables.BU", locale),
            "HW" => DiceTable::Table.from_i18n("BeginningIdol.tables.HW", locale),
            "FL" => DiceTable::Table.from_i18n("BeginningIdol.tables.FL", locale),
            "MSE" => DiceTable::Table.from_i18n("BeginningIdol.tables.MSE", locale),
            "ST" => DiceTable::Table.from_i18n("BeginningIdol.tables.ST", locale),
            "FST" => DiceTable::Table.from_i18n("BeginningIdol.tables.FST", locale),
            "BWT" => DiceTable::D66Table.from_i18n("BeginningIdol.tables.BWT", locale),
            "LWT" => DiceTable::D66Table.from_i18n("BeginningIdol.tables.LWT", locale),
            "TWT" => DiceTable::D66Table.from_i18n("BeginningIdol.tables.TWT", locale),
            "CWT" => DiceTable::D66Table.from_i18n("BeginningIdol.tables.CWT", locale),
            "SU" => DiceTable::D66Table.from_i18n("BeginningIdol.tables.SU", locale),
            "WI" => DiceTable::D66Table.from_i18n("BeginningIdol.tables.WI", locale),
            "NA" => DiceTable::D66Table.from_i18n("BeginningIdol.tables.NA", locale),
            "GA" => DiceTable::D66Table.from_i18n("BeginningIdol.tables.GA", locale),
            "BA" => DiceTable::D66Table.from_i18n("BeginningIdol.tables.BA", locale),
            "WT" => DiceTable::D66Table.from_i18n("BeginningIdol.tables.WT", locale),
            "VA" => DiceTable::D66Table.from_i18n("BeginningIdol.tables.VA", locale),
            "MU" => DiceTable::D66Table.from_i18n("BeginningIdol.tables.MU", locale),
            "DR" => DiceTable::D66Table.from_i18n("BeginningIdol.tables.DR", locale),
            "VI" => DiceTable::D66Table.from_i18n("BeginningIdol.tables.VI", locale),
            "SP" => DiceTable::D66Table.from_i18n("BeginningIdol.tables.SP", locale),
            "CHR" => DiceTable::D66Table.from_i18n("BeginningIdol.tables.CHR", locale),
            "PAR" => DiceTable::D66Table.from_i18n("BeginningIdol.tables.PAR", locale),
            "SW" => DiceTable::D66Table.from_i18n("BeginningIdol.tables.SW", locale),
            "AN" => DiceTable::D66Table.from_i18n("BeginningIdol.tables.AN", locale),
            "MOV" => DiceTable::D66Table.from_i18n("BeginningIdol.tables.MOV", locale),
            "FA" => DiceTable::D66Table.from_i18n("BeginningIdol.tables.FA", locale),
            "BVT" => DiceTable::Table.from_i18n("BeginningIdol.tables.BVT", locale),
            "LVT" => DiceTable::Table.from_i18n("BeginningIdol.tables.LVT", locale),
            "TVT" => DiceTable::Table.from_i18n("BeginningIdol.tables.TVT", locale),
            "CVT" => DiceTable::Table.from_i18n("BeginningIdol.tables.CVT", locale),
            "BST" => DiceTable::Table.from_i18n("BeginningIdol.tables.BST", locale),
            "LST" => DiceTable::Table.from_i18n("BeginningIdol.tables.LST", locale),
            "TST" => DiceTable::Table.from_i18n("BeginningIdol.tables.TST", locale),
            "CST" => DiceTable::Table.from_i18n("BeginningIdol.tables.CST", locale),
            "BPT" => DiceTable::Table.from_i18n("BeginningIdol.tables.BPT", locale),
            "LPT" => DiceTable::Table.from_i18n("BeginningIdol.tables.LPT", locale),
            "TPT" => DiceTable::Table.from_i18n("BeginningIdol.tables.TPT", locale),
            "CPT" => DiceTable::Table.from_i18n("BeginningIdol.tables.CPT", locale),
            "BIT" => DiceTable::Table.from_i18n("BeginningIdol.tables.BIT", locale),
            "LIT" => DiceTable::Table.from_i18n("BeginningIdol.tables.LIT", locale),
            "TIT" => DiceTable::Table.from_i18n("BeginningIdol.tables.TIT", locale),
            "CIT" => DiceTable::Table.from_i18n("BeginningIdol.tables.CIT", locale),
            "CHO" => DiceTable::D66Table.from_i18n("BeginningIdol.tables.CHO", locale),
            "SCH" => DiceTable::Table.from_i18n("BeginningIdol.tables.SCH", locale),
            "WCH" => DiceTable::Table.from_i18n("BeginningIdol.tables.WCH", locale),
            "NCH" => DiceTable::Table.from_i18n("BeginningIdol.tables.NCH", locale),
            "GCH" => DiceTable::D66Table.from_i18n("BeginningIdol.tables.GCH", locale),
            "PCH" => DiceTable::D66Table.from_i18n("BeginningIdol.tables.PCH", locale),
            "LUR" => D6TwiceTable.from_i18n("BeginningIdol.tables.LUR", locale),
            "SUR" => D6TwiceTable.from_i18n("BeginningIdol.tables.SUR", locale),
            "WUR" => D6TwiceTable.from_i18n("BeginningIdol.tables.WUR", locale),
            "NUR" => D6TwiceTable.from_i18n("BeginningIdol.tables.NUR", locale),
            "GUR" => D6TwiceTable.from_i18n("BeginningIdol.tables.GUR", locale),
            "BUR" => D6TwiceTable.from_i18n("BeginningIdol.tables.BUR", locale),
            "ACE" => DiceTable::D66Table.from_i18n("BeginningIdol.tables.ACE", locale),
            "ACT" => translate_accessories_table(locale),
          }
        end
      end

      TABLES = translate_tables(:ja_jp)

      BAD_STATUS_TABLE = BadStatusTable.new(:ja_jp)

      register_prefix(TABLES.keys)
    end
  end
end
