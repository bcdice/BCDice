# frozen_string_literal: true

module BCDice
  module GameSystem
    class Yotabana < Base
      # ゲームシステムの識別子
      ID = "Yotabana"

      # ゲームシステム名
      NAME = "ヨタバナ"

      # ゲームシステム名の読みがな
      SORT_KEY = "よたはな"

      # ダイスボットの使い方
      HELP_MESSAGE = <<~INFO_MESSAGE_TEXT
        ▪️ 各種表
          COT 収束表
          EVT イベント表
      INFO_MESSAGE_TEXT

      def eval_game_system_specific_command(command)
        roll_tables(command, TABLES)
      end

      TABLES = {
        "COT" => DiceTable::Table.new(
          "収束表",
          "1D6",
          [
            "サプライズ忍者／唐突に忍者が乱入し、場面にいるキャラクターを倒して去っていく",
            "仙人／唐突に仙人が乱入し、不思議な力で事態を収束させて帰っていく",
            "洗脳薬／不思議な薬が散布され、キャラクターを洗脳し、事態を収束させる",
            "作者の手／キャラクターたちの言動が唐突に変わり、事態が収束する。作者の大いなる手だ……",
            "神の奇跡／神が奇跡を起こし事態を収束させる。または神の信徒になり、信仰の前に争いは無意味であると悟る",
            "和解／話し合えば分かり合えた。この世は対話で通じ合える",
          ]
        ),
        "EVT" => DiceTable::Table.new(
          "イベント表",
          "1D12",
          [
            "道端に刺さっていた聖剣を拾う",
            "ゾンビの群れと遭遇する",
            "落ちていたコインを拾う。ちょっとラッキーな気分になる",
            "あらゆるところで爆発が！？",
            "唐突に冬が訪れ、猛吹雪が襲う",
            "無人のトラックが突っ込んでくる",
            "ネコちゃんに懐かれる",
            "料金滞納で水道を止められる",
            "ゴキゲンな音楽が鳴り響く",
            "水着になる",
            "オークションにかけられる",
            "殺人アンドロイドが襲いかかってくる",
          ]
        ),
      }.freeze

      register_prefix(TABLES.keys)
    end
  end
end
