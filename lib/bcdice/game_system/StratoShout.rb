# frozen_string_literal: true

module BCDice
  module GameSystem
    class StratoShout < Base
      # ゲームシステムの識別子
      ID = 'StratoShout'

      # ゲームシステム名
      NAME = 'ストラトシャウト'

      # ゲームシステム名の読みがな
      SORT_KEY = 'すとらとしやうと'

      # ダイスボットの使い方
      HELP_MESSAGE = <<~INFO_MESSAGE_TEXT

        VOT, GUT, BAT, KEYT, DRT: (ボーカル、ギター、ベース、キーボード、ドラム)トラブル表
        EMO: 感情表
        AT[1-6]: 特技表(空: ランダム 1: 主義 2: 身体 3: モチーフ 4: エモーション 5: 行動 6: 逆境)
        SCENE, MACHI, GAKKO, BAND: (汎用、街角、学校、バンド)シーン表 接近シーンで使用
        TENKAI: シーン展開表 奔走シーン 練習シーンで使用

        []内は省略可　D66入れ替えあり
      INFO_MESSAGE_TEXT

      register_prefix('AT[1-6]?')

      def initialize(command)
        super(command)

        @sort_add_dice = true
        @enabled_d66 = true
        @d66_sort_type = D66SortType::ASC
      end

      def check_2D6(total, dice_total, _dice_list, cmp_op, target)
        return '' if target == '?'
        return '' unless cmp_op == :>=

        result =
          if dice_total <= 2
            translate("StratoShout.fumble")
          elsif dice_total >= 12
            translate("StratoShout.critical")
          elsif total >= target
            translate("success")
          else
            translate("failure")
          end

        return " ＞ #{result}"
      end

      def eval_game_system_specific_command(command)
        if (m = /^AT([1-6]?)$/.match(command))
          value = m[1].to_i
          return getSkillList(value)
        end

        roll_tables(command, self.class::TABLES)
      end

      def getSkillList(field = 0)
        title = translate("StratoShout.AT.name")
        table = translate("StratoShout.AT.table")

        number1 = 0
        if field == 0
          table, number1 = get_table_by_1d6(table)
        else
          table = table[field - 1]
        end

        fieldName, table = table
        skill, number2 = get_table_by_2d6(table)

        text = title
        if field == 0
          text += " ＞ [#{number1},#{number2}]"
        else
          skill_class = translate("StratoShout.AT.skill_class", name: fieldName)
          text += "#{skill_class} ＞ [#{number2}]"
        end

        return "#{text} ＞ 《#{skill}／#{fieldName}#{number2}》"
      end

      class << self
        private

        def translate_tables(locale)
          {
            "VOT" => DiceTable::Table.from_i18n("StratoShout.table.VOT", locale),
            "GUT" => DiceTable::Table.from_i18n("StratoShout.table.GUT", locale),
            "BAT" => DiceTable::Table.from_i18n("StratoShout.table.BAT", locale),
            "KEYT" => DiceTable::Table.from_i18n("StratoShout.table.KEYT", locale),
            "DRT" => DiceTable::Table.from_i18n("StratoShout.table.DRT", locale),
            "EMO" => DiceTable::Table.from_i18n("StratoShout.table.EMO", locale),
            "SCENE" => DiceTable::Table.from_i18n("StratoShout.table.SCENE", locale),
            "MACHI" => DiceTable::Table.from_i18n("StratoShout.table.MACHI", locale),
            "GAKKO" => DiceTable::Table.from_i18n("StratoShout.table.GAKKO", locale),
            "BAND" => DiceTable::Table.from_i18n("StratoShout.table.BAND", locale),
            "TENKAI" => DiceTable::D66Table.from_i18n("StratoShout.table.TENKAI", locale),
          }
        end
      end

      TABLES = translate_tables(:ja_jp)

      register_prefix(TABLES.keys)
    end
  end
end
