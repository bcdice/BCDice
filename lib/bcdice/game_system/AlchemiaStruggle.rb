# frozen_string_literal: true

require "bcdice"

module BCDice
  module GameSystem
    class AlchemiaStruggle < Base
      ID = "AlchemiaStruggle"
      NAME = "アルケミア・ストラグル"
      SORT_KEY = "あるけみあすとらくる"

      HELP_MESSAGE = <<~MESSAGETEXT
        ■ ダイスロール（ XAS ）
          ＸＤをロールします。
          例） 5AS
        
        ■ ダイスロール＆最大になるようにピック（ XASY ）
          ＸＤをロールし、そこから最大になるようにＹ個をピックします。
          例） 4AS3

        ■ 表
          ・奇跡の触媒
            ・エレメント (CELE, CElement)
            ・アルケミア (CALC, CAlchemia)
            ・インフォーマント (CINF, CInformant)
            ・イノセンス (CINN, CInnocence)
            ・アクワイヤード (CACQ, CAcquired)
          ・携行品
            ・Ｓサイズ (ARS, ArticleS)
            ・Ｍサイズ (ARM, ArticleM)
            ・Ｌサイズ (ARL, ArticleL)
      MESSAGETEXT

      ROLL_REG = /^(\d+)AS(\d+)?$/i.freeze

      register_prefix('\\d+AS')

      def eval_game_system_specific_command(command)
        c = resolve_alias command

        try_roll_alchemia(c) ||
          roll_tables(c, COMPOSITE_TABLES)
      end

      def resolve_alias(source_command)
        ALIAS.each do |key, value|
          if key.upcase == source_command.upcase || value.upcase == source_command.upcase
            return value
          end
        end

        source_command
      end

      def try_roll_alchemia(command)
        if command.match? ROLL_REG
          match = ROLL_REG.match command

          roll_dice_count = match[1].to_i

          if match[2].nil?
            # ロールのみ（ピックなし）:

            result = roll_alchemia(roll_dice_count)
            return make_roll_text(result)
          else
            # ロールして最大値をピック:

            pick_dice_count = match[2].to_i

            result = roll_alchemia_and_pick(roll_dice_count, pick_dice_count)
            return make_roll_and_pick_text(result[:rolled_dices], pick_dice_count, result[:picked_dices])
          end
        end
      end

      def roll_alchemia(roll_dice_count)
        @randomizer.roll_barabara(roll_dice_count, 6)
      end

      def roll_alchemia_and_pick(roll_dice_count, pick_dice_count)
        rolled_dice_list = roll_alchemia(roll_dice_count)

        return {
          rolled_dices: rolled_dice_list,
          picked_dices: pick_maximum(rolled_dice_list, pick_dice_count),
        }
      end

      def pick_maximum(dice_list, pick_dice_count)
        if dice_list.size <= pick_dice_count
          dice_list
        else
          dice_list.sort[-pick_dice_count..-1]
        end
      end

      def make_roll_text(rolled_dice_list)
        "(#{rolled_dice_list.size}D) ＞ #{make_dice_text(rolled_dice_list)}"
      end

      # 実際にピックできた数と要求されたピック数は一致しないケースが（ルール上）あるため、 pick_dice_count はパラメータとして受ける必要がある。
      def make_roll_and_pick_text(rolled_dice_list, pick_dice_count, picked_dice_list)
        "(#{rolled_dice_list.size}D>>#{pick_dice_count}D) ＞ #{make_dice_text(rolled_dice_list)} >> #{make_dice_text(picked_dice_list)} ＞ #{picked_dice_list.sum}"
      end

      def make_dice_text(dice_list)
        "[#{dice_list.sort.join ', '}]"
      end

      # ひとつめのダイスは偶奇だけを見るテーブルをつくる
      # items は { odd: [ , , , , , ], even: [ , , , , , ] } の構造
      def self.make_d66_small_table(name, items)
        formatted_items = {}

        (1..6).each do |left_dice|
          child_table = left_dice.odd? ? items[:odd] : items[:even]

          (1..6).each do |right_dice|
            index_for_child_table = right_dice - 1
            formatted_items[left_dice * 10 + right_dice] = child_table[index_for_child_table]
          end
        end

        DiceTable::D66Table.new(
          name,
          D66SortType::NO_SORT,
          formatted_items
        )
      end

      CATALYST_TABLES = {
        'CElement' => DiceTable::Table.new(
          "奇跡の触媒（エレメント）",
          "1D6",
          [
            "ワンド",
            "水晶玉",
            "カード",
            "ステッキ",
            "手鏡",
            "宝石",
          ]
        ),
        'CAlchemia' => DiceTable::Table.new(
          "奇跡の触媒（アルケミア）",
          "1D6",
          [
            "指輪",
            "ブレスレット",
            "イヤリング",
            "ネックレス",
            "ブローチ",
            "ヘアピン",
          ]
        ),
        'CInformant' => DiceTable::Table.new(
          "奇跡の触媒（インフォーマント）",
          "1D6",
          [
            "スマートフォン",
            "タブレット",
            "ノートパソコン",
            "無線機（トランシーバー）",
            "ウェアラブルデバイス",
            "携帯ゲーム機",
          ]
        ),
        'CInnocence' => DiceTable::Table.new(
          "奇跡の触媒（イノセンス）",
          "1D6",
          [
            "手袋",
            "笛",
            "靴",
            "鈴",
            "拡声器",
            "弦楽器",
          ]
        ),
        'CAcquired' => DiceTable::Table.new(
          "奇跡の触媒（アクワイヤード）",
          "1D6",
          [
            "ボタン",
            "音声",
            "モーション",
            "脳波",
            "記録媒体",
            "ＡＩ",
          ]
        ),
      }.freeze

      ARTICLE_TABLES = {
        'ArticleS' => DiceTable::D66Table.new(
          "携行品（Ｓサイズ）",
          D66SortType::ASC,
          {
            11 => "マッチ",
            12 => "ペットボトル",
            13 => "試験管",
            14 => "団扇",
            15 => "植物",
            16 => "ハンカチ",
            22 => "化粧用具",
            23 => "ベルト",
            24 => "タバコ",
            25 => "チェーン",
            26 => "電池",
            33 => "お菓子",
            34 => "針金",
            35 => "コイン",
            36 => "ナイフ",
            44 => "カトラリー",
            45 => "砂",
            46 => "スプレー",
            55 => "石",
            56 => "文房具",
            66 => "ペンライト",
          }
        ),
        'ArticleM' => make_d66_small_table(
          "携行品（Ｍサイズ）",
          {
            odd: [
              "本",
              "傘",
              "金属板",
              "花火",
              "エアガン",
              "包帯",
            ],
            even: [
              "工具",
              "ジャケット",
              "ロープ",
              "人形",
              "軽食",
              "ガラス瓶",
            ],
          }
        ),
        'ArticleL' => make_d66_small_table(
          "携行品（Ｌサイズ）",
          {
            odd: [
              "木刀",
              "釣り具",
              "自転車",
              "バット",
              "寝袋",
              "丸太",
            ],
            even: [
              "物干し竿",
              "鍋",
              "スケートボード",
              "シャベル（スコップ）",
              "タンク",
              "脚立",
            ],
          }
        ),
      }.freeze

      COMPOSITE_TABLES =
        CATALYST_TABLES.merge(ARTICLE_TABLES)

      ALIAS =
        CATALYST_TABLES.keys.map { |x| [x[0...4].upcase, x] }.to_h.merge(
          ARTICLE_TABLES.keys.map { |x| [x[0...2].upcase + x[-1], x] }.to_h
        ).freeze

      register_prefix(ALIAS.keys, COMPOSITE_TABLES.keys)
    end
  end
end
