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
        ATn, RTTn: 特技表(n＝分野。空:ランダム 1:主義 2:身体 3:モチーフ 4:情緒 5:行動 6:逆境)
        RCT: 分野ランダム表
        SCENE, MACHI, GAKKO, BAND: (汎用、街角、学校、バンド)シーン表 接近シーンで使用
        TENKAI: シーン展開表 奔走シーン 練習シーンで使用

        D66入れ替えあり
      INFO_MESSAGE_TEXT

      def initialize(command)
        super(command)

        @sort_add_dice = true
        @d66_sort_type = D66SortType::ASC
      end

      def result_2d6(_total, dice_total, _dice_list, cmp_op, _target)
        return nil unless cmp_op == :>=

        if dice_total <= 2
          Result.fumble(translate("StratoShout.fumble"))
        elsif dice_total >= 12
          Result.critical(translate("StratoShout.critical"))
        end
      end

      def eval_game_system_specific_command(command)
        roll_tables(command, self.class::TABLES) || self.class::RTT.roll_command(@randomizer, command)
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

        def translate_rtt(locale)
          DiceTable::SaiFicSkillTable.from_i18n("StratoShout.RTT", locale, rtt: 'AT', rttn: ['AT1', 'AT2', 'AT3', 'AT4', 'AT5', 'AT6'])
        end
      end

      TABLES = translate_tables(:ja_jp)
      RTT = translate_rtt(:ja_jp)

      register_prefix(TABLES.keys, RTT.prefixes)
    end
  end
end
