# frozen_string_literal: true

require "bcdice/dice_table/chain_table"
require "bcdice/dice_table/sai_fic_skill_table"
require "bcdice/dice_table/table"
require "bcdice/format"

module BCDice
  module GameSystem
    class StarryDolls < Base
      # ゲームシステムの識別子
      ID = "StarryDolls"

      # ゲームシステム名
      NAME = "スタリィドール"

      # ゲームシステム名の読みがな
      SORT_KEY = "すたりいとおる"

      # ダイスボットの使い方
      HELP_MESSAGE = <<~INFO_MESSAGE_TEXT
        ・行為判定 nD6±m@s>=t
        　nD6の行為判定を行う。スペシャル／ファンブル／成功／失敗を判定。
        　　n: ダイス数
        　　m: 修正（省略可）
        　　s: スペシャル値（省略時 12）
        　　t: 目標値（?指定可）
        ・各種表
        　・ランダム特技決定表 RTTn (n：分野番号、省略可能)
        　　　1願望 2元素 3星使い 4動作 5召喚 6人間性
        　・ランダム分野表 RCT
        　・ランダム星座表 HOR
        　　　ランダム星座表A HORA／ランダム星座表B HORB
        　・主人関係表 MRT／関係属性表 RAT
        　・従者関係表 SRT
        　・奇跡表 MIR
        　・戦果表 BRT
        　・事件表 TRO
        　・森事件表 TROF
        　・庭園事件表 TROG
        　・城内事件表 TROC
        　・都市事件表 TROT
        　・図書館事件表 TROL
        　・駅事件表 TROS
        　・従者トラブル表 TRS
        　・リアクション表　忠誠 RAL
        　・リアクション表　冷静 RAC
        　・リアクション表　母性 RAM
        　・リアクション表　年長者 RAO
        　・リアクション表　無邪気 RAI
        　・リアクション表　長老 RAE
        　・遭遇表 ENC
        　・致命傷表 FWT
        　・カタストロフ表 CAT
        　・回想表
        　　　〈魔術師の庭〉回想表 JDSRT／〈セブンス・ヘブン〉回想表 SHRT
        　　　／〈祝福の鐘〉回想表 BCRT／〈オメガ探偵社〉回想表 ODRT
        　・出張表
        　　　〈魔術師の庭〉出張表 JDSBT／〈セブンス・ヘブン〉出張表 SHBT
        　　　／〈祝福の鐘〉出張表 BCBT／〈オメガ探偵社〉出張表 ODBT
        　　　／〈天の川商店街〉出張表 ASBT／〈ポラリス星学院〉出張表 PABT
        　　　／〈人形騎士団〉出張表 SCBT／〈人形騎士団〉への出張表 TOSCBT
        ・D66ダイスあり
      INFO_MESSAGE_TEXT

      def initialize(command)
        super(command)

        @d66_sort_type = D66SortType::ASC
      end

      def eval_game_system_specific_command(command)
        action_roll(command) ||
          roll_tables(command, self.class::TABLES) ||
          self.class::RTT.roll_command(@randomizer, command)
      end

      private

      def action_roll(command)
        parser = Command::Parser.new("D6", round_type: round_type)
                                .has_prefix_number
                                .restrict_cmp_op_to(:>=)
                                .enable_critical
                                .enable_question_target
        cmd = parser.parse(command)
        return nil unless cmd

        times = cmd.prefix_number
        return nil if times < 1

        fumble = 2
        special = cmd.critical || 12

        if special <= fumble
          special = fumble + 1 # p.180
          cmd.critical = special
        end

        dice_list = @randomizer.roll_barabara(times, 6)
        dice_total = dice_list.sum()
        total = dice_total + cmd.modify_number

        result =
          if dice_total <= fumble
            Result.fumble(translate("StarryDolls.action_roll.fumble"))
          elsif dice_total >= special
            Result.critical(translate("StarryDolls.action_roll.special"))
          elsif cmd.question_target?
            Result.new
          elsif total >= cmd.target_number
            Result.success(translate("success"))
          else
            Result.failure(translate("failure"))
          end

        sequence = [
          "(#{cmd.to_s(:after_modify_number)})",
          "#{dice_total}[#{dice_list.join(',')}]#{Format.modifier(cmd.modify_number)}",
          total,
          result.text
        ].compact

        result.text = sequence.join(" ＞ ")
        result
      end

      class << self
        private

        def translate_tables(locale)
          hor_table_a = DiceTable::Table.from_i18n("StarryDolls.HORA", locale)
          hor_table_b = DiceTable::Table.from_i18n("StarryDolls.HORB", locale)

          {
            "HORA" => hor_table_a,
            "HORB" => hor_table_b,
            "HOR" => DiceTable::ChainTable.new(
              I18n.translate("StarryDolls.HOR.name", locale: locale),
              "1D6",
              [
                hor_table_a,
                hor_table_a,
                hor_table_a,
                hor_table_b,
                hor_table_b,
                hor_table_b,
              ]
            ),
            "MRT" => DiceTable::Table.from_i18n("StarryDolls.MRT", locale),
            "RAT" => DiceTable::Table.from_i18n("StarryDolls.RAT", locale),
            "MIR" => DiceTable::Table.from_i18n("StarryDolls.MIR", locale),
            "BRT" => DiceTable::Table.from_i18n("StarryDolls.BRT", locale),
            "TRO" => DiceTable::Table.from_i18n("StarryDolls.TRO", locale),
            "ENC" => DiceTable::Table.from_i18n("StarryDolls.ENC", locale),
            "FWT" => DiceTable::Table.from_i18n("StarryDolls.FWT", locale),
            "CAT" => DiceTable::Table.from_i18n("StarryDolls.CAT", locale),
            "JDSRT" => DiceTable::Table.from_i18n("StarryDolls.JDSRT", locale),
            "SHRT" => DiceTable::Table.from_i18n("StarryDolls.SHRT", locale),
            "BCRT" => DiceTable::Table.from_i18n("StarryDolls.BCRT", locale),
            "ODRT" => DiceTable::Table.from_i18n("StarryDolls.ODRT", locale),
            "SRT" => DiceTable::Table.from_i18n("StarryDolls.SRT", locale),
            "TRS" => DiceTable::Table.from_i18n("StarryDolls.TRS", locale),
            "RAL" => DiceTable::Table.from_i18n("StarryDolls.RAL", locale),
            "RAC" => DiceTable::Table.from_i18n("StarryDolls.RAC", locale),
            "RAM" => DiceTable::Table.from_i18n("StarryDolls.RAM", locale),
            "RAO" => DiceTable::Table.from_i18n("StarryDolls.RAO", locale),
            "RAI" => DiceTable::Table.from_i18n("StarryDolls.RAI", locale),
            "RAE" => DiceTable::Table.from_i18n("StarryDolls.RAE", locale),
            "JDSBT" => DiceTable::Table.from_i18n("StarryDolls.JDSBT", locale),
            "SHBT" => DiceTable::Table.from_i18n("StarryDolls.SHBT", locale),
            "BCBT" => DiceTable::Table.from_i18n("StarryDolls.BCBT", locale),
            "ODBT" => DiceTable::Table.from_i18n("StarryDolls.ODBT", locale),
            "ASBT" => DiceTable::Table.from_i18n("StarryDolls.ASBT", locale),
            "PABT" => DiceTable::Table.from_i18n("StarryDolls.PABT", locale),
            "SCBT" => DiceTable::Table.from_i18n("StarryDolls.SCBT", locale),
            "TOSCBT" => DiceTable::Table.from_i18n("StarryDolls.TOSCBT", locale),
            "TROF" => DiceTable::Table.from_i18n("StarryDolls.TROF", locale),
            "TROG" => DiceTable::Table.from_i18n("StarryDolls.TROG", locale),
            "TROC" => DiceTable::Table.from_i18n("StarryDolls.TROC", locale),
            "TROT" => DiceTable::Table.from_i18n("StarryDolls.TROT", locale),
            "TROL" => DiceTable::Table.from_i18n("StarryDolls.TROL", locale),
            "TROS" => DiceTable::Table.from_i18n("StarryDolls.TROS", locale),
          }
        end

        def translate_rtt(locale)
          DiceTable::SaiFicSkillTable.from_i18n("StarryDolls.RTT", locale)
        end
      end

      TABLES = translate_tables(:ja_jp).freeze
      RTT = translate_rtt(:ja_jp)

      register_prefix('\d+D6', RTT.prefixes, TABLES.keys)
    end
  end
end
