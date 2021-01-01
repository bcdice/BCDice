# frozen_string_literal: true

module BCDice
  module GameSystem
    class MeikyuKingdom
      # 地名決定表
      def mk_pn_decide_table(num)
        output = ""

        d1 = @randomizer.roll_once(6)
        d2 = @randomizer.roll_once(6)
        debug("d1", d1)
        debug("d2", d2)

        d1 = (d1 / 2.0).ceil.to_i
        d2 = (d2 / 2.0).ceil.to_i

        num.times do |_i|
          output += "「" + mk_decoration_table(d1) + mk_placename_table(d2) + "」"
        end

        return output
      end

      # 修飾決定表(1D6)
      def mk_decoration_table(num)
        debug("mk_decoration_table num", num)

        table = [
          [1, lambda { mk_basic_decoration_table(@randomizer.roll_d66(D66SortType::ASC)) }],
          [2, lambda { mk_spooky_decoration_table(@randomizer.roll_d66(D66SortType::ASC)) }],
          [3, lambda { mk_katakana_decoration_table(@randomizer.roll_d66(D66SortType::ASC)) }],
        ]
        return get_table_by_number(num, table)
      end

      # 地名決定表(1D6)
      def mk_placename_table(num)
        table = [
          [1, lambda { mk_passage_placename_table(@randomizer.roll_d66(D66SortType::ASC)) }],
          [2, lambda { mk_natural_placename_table(@randomizer.roll_d66(D66SortType::ASC)) }],
          [3, lambda { mk_artifact_placename_table(@randomizer.roll_d66(D66SortType::ASC)) }],
        ]
        return get_table_by_number(num, table)
      end

      # 基本表(D66)
      def mk_basic_decoration_table(num)
        table = [
          [11, "欲望（よくぼう）"],
          [12, "漂流（ひょうりゅう）"],
          [13, "黄金（おうごん）"],
          [14, "火達磨（ひだるま）"],
          [15, "災厄（さいやく）"],
          [16, "三日月（みかづき）"],
          [22, "絡繰り（からくり）"],
          [23, "流星（りゅうせい）"],
          [24, "棘々（とげとげ）"],
          [25, "鏡（かがみ）"],
          [26, "銀鱗（ぎんりん）"],
          [33, "螺旋（らせん）"],
          [34, "七色（なないろ）"],
          [35, "殉教（じゅんきょう）"],
          [36, "水晶（すいしょう）"],
          [44, "氷結（ひょうけつ）"],
          [45, "忘却（ぼうきゃく）"],
          [46, "幸福（こうふく）"],
          [55, "妖精（ようせい）"],
          [56, "霧雨（きりさめ）"],
          [66, "夕暮れ（ゆうぐれ）"],
        ]
        return get_table_by_number(num, table)
      end

      # 不気味表(D66)
      def mk_spooky_decoration_table(num)
        table = [
          [11, "赤錆（あかさび）"],
          [12, "串刺し（くしざし）"],
          [13, "鬼蜘蛛（おにぐも）"],
          [14, "蠍（さそり）"],
          [15, "幽霊（ゆうれい）"],
          [16, "髑髏（どくろ）"],
          [22, "血溜まり（ちだまり）"],
          [23, "臓物（ぞうもつ）"],
          [24, "骸（むくろ）"],
          [25, "鉤爪（かぎづめ）"],
          [26, "犬狼（けんろう）"],
          [33, "奈落（ならく）"],
          [34, "大蛇（おろち）"],
          [35, "地獄（じごく）"],
          [36, "蚯蚓（みみず）"],
          [44, "退廃（たいはい）"],
          [45, "土竜（もぐら）"],
          [46, "絶望（ぜつぼう）"],
          [55, "夜泣き（よなき）"],
          [56, "緑林（りょくりん）"],
          [66, "どん底（どんぞこ）"],
        ]
        return get_table_by_number(num, table)
      end

      # カタカナ表(D66)
      def mk_katakana_decoration_table(num)
        table = [
          [11, "マヨネーズ"],
          [12, "ダイナマイト"],
          [13, "ドラゴン"],
          [14, "ボヨヨン"],
          [15, "モケモケ"],
          [16, "マヌエル"],
          [22, "ダイス"],
          [23, "ロマン"],
          [24, "ウクレレ"],
          [25, "エップカプ"],
          [26, "カンパネルラ"],
          [33, "マンチキン"],
          [34, "バロック"],
          [35, "ミサイル"],
          [36, "ドッキリ"],
          [44, "ブラック"],
          [45, "好きなモンスターの名前"],
          [46, "好きなトラップの名前"],
          [55, "好きな単語表で"],
          [56, "好きな名前決定表で"],
          [66, "好きな数字の組み合わせ"],
        ]
        return get_table_by_number(num, table)
      end

      # 通路系地名表(D66)
      def mk_passage_placename_table(num)
        table = [
          [11, "門（ゲート）"],
          [12, "回廊（コリドー）"],
          [13, "通り（ストリート）"],
          [14, "小路（アレイ）"],
          [15, "大路（アベニュー）"],
          [16, "街道（ロード）"],
          [22, "鉄道（ライン）"],
          [23, "迷宮（メイズ）"],
          [24, "坑道（トンネル）"],
          [25, "坂（スロープ）"],
          [26, "峠（パス）"],
          [33, "運河（カナル）"],
          [34, "水路（チャネル）"],
          [35, "河（ストリーム）"],
          [36, "堀（モート）"],
          [44, "溝（ダイク）"],
          [45, "階段（ステア）"],
          [46, "辻（トレイル）"],
          [55, "橋（ブリッジ）"],
          [56, "穴（ホール）"],
          [66, "柱廊（ストア）"],
        ]
        return get_table_by_number(num, table)
      end

      # 自然系地名表(D66)
      def mk_natural_placename_table(num)
        table = [
          [11, "砂漠（デザート）"],
          [12, "丘陵（ヒル）"],
          [13, "海（オーシャン）"],
          [14, "森（フォレスト）"],
          [15, "沼（ポンド）"],
          [16, "海岸（コースト）"],
          [22, "密林（ジャングル）"],
          [23, "湖（レイク）"],
          [24, "山脈（マウンテンズ）"],
          [25, "平原（プレイン）"],
          [26, "ヶ原（ランド）"],
          [33, "荒野（ヒース）"],
          [34, "渓谷（ヴァレー）"],
          [35, "島（アイランド）"],
          [36, "連峰（ピークス）"],
          [44, "火山（ヴォルケイノ）"],
          [45, "湿原（ウェットランド）"],
          [46, "星雲（ネビュラ）"],
          [55, "星（スター）"],
          [56, "ヶ淵（プール）"],
          [66, "雪原（スノウズ）"],
        ]
        return get_table_by_number(num, table)
      end

      # 人工系地名表(D66)
      def mk_artifact_placename_table(num)
        table = [
          [11, "城（キャッスル）"],
          [12, "壁（ウォール）"],
          [13, "砦（フォート）"],
          [14, "地帯（ゾーン）"],
          [15, "室（ルーム）"],
          [16, "の間（チャンバー）"],
          [22, "浴室（バス）"],
          [23, "畑（ファーム）"],
          [24, "館（ハウス）"],
          [25, "座（コンスティレィション）"],
          [26, "遺跡（ルイン）"],
          [33, "ヶ浜（ビーチ）"],
          [34, "塔（タワー）"],
          [35, "墓場（グレイブ）"],
          [36, "洞（ケイヴ）"],
          [44, "堂（バジリカ）"],
          [45, "野（フィールド）"],
          [46, "書院（スタディ）"],
          [55, "駅前（ステイション）"],
          [56, "房（クラスター）"],
          [66, "腐海（ケイオスシー）"],
        ]
        return get_table_by_number(num, table)
      end
    end
  end
end
