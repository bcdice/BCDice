# frozen_string_literal: true

require 'bcdice/dice_table/table'
require 'bcdice/dice_table/d66_range_table'
require 'bcdice/dice_table/d66_grid_table'
require 'bcdice/format'

module BCDice
  module GameSystem
    class MonotoneMuseum < Base
      # ゲームシステムの識別子
      ID = 'MonotoneMuseum'

      # ゲームシステム名
      NAME = 'モノトーンミュージアムRPG'

      # ゲームシステム名の読みがな
      SORT_KEY = 'ものとおんみゆうしあむRPG'

      # ダイスボットの使い方
      HELP_MESSAGE = <<~INFO_MESSAGE_TEXT
        ・判定
        　・通常判定　　　　　　2D6+m>=t[c,f]
        　　修正値m,目標値t,クリティカル値c,ファンブル値fで判定ロールを行います。
        　　クリティカル値、ファンブル値は省略可能です。([]ごと省略できます)
        　　自動成功、自動失敗、成功、失敗を自動表示します。
        ・各種表
        　・感情表　ET／感情表 2.0　ET2
        　・兆候表　OT／兆候表ver2.0　OT2／兆候表ver3.0　OT3
        　・歪み表　DT／歪み表ver2.0　DT2／歪み表(野外)　DTO／歪み表(海)　DTS／歪み表(館・城)　DTM
        　・世界歪曲表　WDT／世界歪曲表2.0　WDT2
        　・永劫消失表　EDT
        ・D66ダイスあり
      INFO_MESSAGE_TEXT

      # ダイスボットを初期化する
      def initialize(command)
        super(command)

        # 式、出目ともに送信する

        # D66ダイスあり（出目をソートしない）
        @d66_sort_type = D66SortType::NO_SORT
        # バラバラロール（Bコマンド）でソートする
        @sort_add_dice = true
      end

      # 固有のダイスロールコマンドを実行する
      # @param [String] command 入力されたコマンド
      # @return [String, nil] ダイスロールコマンドの実行結果
      def eval_game_system_specific_command(command)
        if (ret = check_roll(command))
          return ret
        end

        return roll_tables(command, self.class::TABLES)
      end

      private

      def check_roll(command)
        m = /^(\d+)D6([+\-\d]*)>=(\?|\d+)(\[(\d+)?(,(\d+))?\])?$/i.match(command)
        unless m
          return nil
        end

        dice_count = m[1].to_i
        modify_number = m[2] ? ArithmeticEvaluator.eval(m[2]) : 0
        target = m[3].to_i
        critical = m[5]&.to_i || 12
        fumble = m[7]&.to_i || 2

        dice_list = @randomizer.roll_barabara(dice_count, 6).sort
        dice_value = dice_list.sum()
        dice_str = dice_list.join(",")
        total = dice_value + modify_number

        result =
          if dice_value <= fumble
            Result.fumble(translate("MonotoneMuseum.automatic_failure"))
          elsif dice_value >= critical
            Result.critical(translate("MonotoneMuseum.automatic_success"))
          elsif target == 0
            Result.success('')
          elsif total >= target
            Result.success(translate("success"))
          else
            Result.failure(translate("failure"))
          end

        sequence = [
          "(#{command})",
          "#{dice_value}[#{dice_str}]#{Format.modifier(modify_number)}",
          total.to_s,
          result.text,
        ]

        result.text = sequence.join(" ＞ ").chomp(" ＞ ")

        result
      end

      # モノトーンミュージアム用のテーブル
      # D66を振って決定する
      # 1項目あたり出目2つに対応する
      class MMTable < DiceTable::D66RangeTable
        # @param key [String]
        # @param locale [Symbol]
        # @return [MMTable]
        def self.from_i18n(key, locale)
          table = I18n.translate(key, locale: locale, raise: true)
          new(table[:name], table[:items])
        end

        # @param name [String]
        # @param items [Array<String>]
        def initialize(name, items)
          if items.size != RANGE.size
            raise UnexpectedTableSize.new(name, items.size)
          end

          items_with_range = RANGE.zip(items)

          super(name, items_with_range)
        end

        # 1項目あたり2個
        RANGE = [11..12, 13..14, 15..16, 21..22, 23..24, 25..26, 31..32, 33..34, 35..36, 41..42, 43..44, 45..46, 51..52, 53..54, 55..56, 61..62, 63..64, 65..66].freeze
      end

      class << self
        private

        def translate_tables(locale)
          {
            "ET" => DiceTable::D66GridTable.from_i18n("MonotoneMuseum.table.ET", locale),
            "ET2" => DiceTable::D66GridTable.from_i18n("MonotoneMuseum.table.ET2", locale),
            "OT" => DiceTable::Table.from_i18n("MonotoneMuseum.table.OT", locale),
            "DT" => DiceTable::Table.from_i18n("MonotoneMuseum.table.DT", locale),
            "DT2" => MMTable.from_i18n("MonotoneMuseum.table.DT2", locale),
            "WDT" => DiceTable::Table.from_i18n("MonotoneMuseum.table.WDT", locale),
            "WDT2" => MMTable.from_i18n("MonotoneMuseum.table.WDT2", locale),
            "OT2" => MMTable.from_i18n("MonotoneMuseum.table.OT2", locale),
            "DTO" => MMTable.from_i18n("MonotoneMuseum.table.DTO", locale),
            "DTS" => MMTable.from_i18n("MonotoneMuseum.table.DTS", locale),
            "EDT" => DiceTable::Table.from_i18n("MonotoneMuseum.table.EDT", locale),
            "DTM" => MMTable.from_i18n("MonotoneMuseum.table.DTM", locale),
            "OT3" => DiceTable::Table.from_i18n("MonotoneMuseum.table.OT3", locale),
          }
        end
      end

      TABLES = translate_tables(:ja_jp).freeze

      register_prefix('\d+D6', TABLES.keys)
    end
  end
end
