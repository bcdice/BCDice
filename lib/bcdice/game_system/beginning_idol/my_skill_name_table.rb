# frozen_string_literal: true

module BCDice
  module GameSystem
    class BeginningIdol < Base
      ARTICLE_TABLE = DiceTable::Table.new(
        "称号表",
        "1D6",
        [
          "アイドル",
          "ガール／ボーイ",
          "パラダイス",
          "プリンセス／プリンス",
          "スタイル",
          "クイーン／キング",
        ]
      )

      DESCRIBE_TABLE = DiceTable::D66Table.new(
        "形容表",
        D66SortType::ASC,
        {
          11 => "ビギニング",
          12 => "パワフル",
          13 => "ビューティフル",
          14 => "エターナル",
          15 => "きらめき",
          16 => "シャイニング",
          22 => "パーフェクト",
          23 => "1000%",
          24 => "フレッシュ",
          25 => "ドキドキ",
          26 => "ワイルド",
          33 => "ロイヤル",
          34 => "ときめき",
          35 => "ふわふわ",
          36 => "スタイリッシュ",
          44 => "小悪魔",
          45 => "スーパー",
          46 => "ウルトラ",
          55 => "ハイパー",
          56 => "ダイナマイト",
          66 => "アルティメット",
        }
      )

      SCENE_TABLE = DiceTable::D66Table.new(
        "情景表",
        D66SortType::ASC,
        {
          11 => "マーメイド",
          12 => "ドリーム",
          13 => "ピュア",
          14 => "アニマル",
          15 => "サンシャイン",
          16 => "ムーンライト",
          22 => "かわいい／かっこいい",
          23 => "フューチャリング",
          24 => "ライジング",
          25 => "バーニング",
          26 => "スターライト",
          33 => "ボンバー",
          34 => "レインボー",
          35 => "フローズン",
          36 => "ヒート",
          44 => "ダーク",
          45 => "ぴかぴか",
          46 => "サンライズ",
          55 => "スターダスト",
          56 => "オーロラ",
          66 => "ギャラクシー",
        }
      )

      MATERIAL_TABLE = DiceTable::D66Table.new(
        "マテリアル表",
        D66SortType::ASC,
        {
          11 => "バスケット",
          12 => "エクスプレス",
          13 => "エアプレーン",
          14 => "ロケット",
          15 => "ハリケーン",
          16 => "バイク",
          22 => "タイガー",
          23 => "ドルフィン",
          24 => "ドッグ",
          25 => "キャット",
          26 => "バニー",
          33 => "ドラゴン",
          34 => "ソード",
          35 => "ランス",
          36 => "パラソル",
          44 => "ローズ",
          45 => "ロータス",
          46 => "コスモス",
          55 => "キャンディ",
          56 => "ハート",
          66 => "フェニックス",
        }
      )

      ACTION_TABLE = DiceTable::D66Table.new(
        "アクション表",
        D66SortType::ASC,
        {
          11 => "スパイラル",
          12 => "フライ",
          13 => "シャワー",
          14 => "ダイブ",
          15 => "イリュージョン",
          16 => "ラッシュ",
          22 => "ターン",
          23 => "ラブ",
          24 => "ハグ",
          25 => "ダッシュ",
          26 => "シュート",
          33 => "ダイビング",
          34 => "クロス",
          35 => "トリック",
          36 => "ビーム",
          44 => "スラッシュ",
          45 => "ボイス",
          46 => "ドライブ",
          55 => "くるくる",
          56 => "ジャンプ",
          66 => "アクション",
        }
      )

      module MySkillNameTable
        module_function

        TABLE = [
          "形容表＋情景表＋マテリアル表",
          "形容表＋情景表＋アクション表",
          "形容表＋マテリアル表＋アクション表",
          "情景表＋マテリアル表＋アクション表",
          "形容表もしくは情景表＋称号表＋PCの名前",
          "マテリアル表もしくはアクション表＋称号表＋PCの名前",
        ].freeze

        FORMATS = [
          "%s＋%s＋%s",
          "%s＋%s＋%s",
          "%s＋%s＋%s",
          "%s＋%s＋%s",
          "%sもしくは%s＋%s＋PCの名前",
          "%sもしくは%s＋%s＋PCの名前",
        ].freeze

        CHAINS = [
          [DESCRIBE_TABLE, SCENE_TABLE, MATERIAL_TABLE],
          [DESCRIBE_TABLE, SCENE_TABLE, ACTION_TABLE],
          [DESCRIBE_TABLE, MATERIAL_TABLE, ACTION_TABLE],
          [SCENE_TABLE, MATERIAL_TABLE, ACTION_TABLE],
          [DESCRIBE_TABLE, SCENE_TABLE, ARTICLE_TABLE],
          [MATERIAL_TABLE, ACTION_TABLE, ARTICLE_TABLE],
        ].freeze

        # @param randomizer [BCDice::Randomizer]
        # @return [String]
        def roll(randomizer)
          index = randomizer.roll_once(6)
          chosens = CHAINS[index - 1].map { |t| t.roll(randomizer) }

          dice = chosens.map { |chosen| chosen.table_name + chosen.value.to_s }
          skill_name = format(FORMATS[index - 1], *chosens.map(&:body))

          "マイスキル名決定表 ＞ [#{index},#{dice.join(',')}] ＞ #{skill_name}"
        end
      end
    end
  end
end
