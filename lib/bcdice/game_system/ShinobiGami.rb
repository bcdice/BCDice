# frozen_string_literal: true

require "bcdice/dice_table/chain_table"
require "bcdice/dice_table/sai_fic_skill_table"
require "bcdice/dice_table/table"
require "bcdice/format"

module BCDice
  module GameSystem
    class ShinobiGami < Base
      # ゲームシステムの識別子
      ID = 'ShinobiGami'

      # ゲームシステム名
      NAME = 'シノビガミ'

      # ゲームシステム名の読みがな
      SORT_KEY = 'しのひかみ'

      # ダイスボットの使い方
      # 25/01/17：書式成形（半角スペース×2に統一、同じ書籍のシーン表は改行なしで列挙）
      HELP_MESSAGE = <<~INFO_MESSAGE_TEXT
        ・行為判定 nSG@s#f>=x
          2D6の行為判定を行う。ダイス数が指定された場合、大きい出目2個を採用する。
          n: ダイス数 (省略時 2)
          s: スペシャル値 (省略時 12)
          f: ファンブル値 (省略時 2)
          x: 目標値 (省略可)
          例）SG, SG@11, SG@11#3, SG#3>=7, 3SG>=7

        ・行為判定以外の表
          以下の表は「回数+コマンド」で複数回振れる
          例）3RCT, 2WT

        ・ランダム特技決定表 RTTn (n:分野番号、省略可能)
          1器術 2体術 3忍術 4謀術 5戦術 6妖術

        ・ランダム分野表 RCT

        ・各種表：基本ルールブック以降
          ファンブル表 FT、戦場表 BT、感情表 ET、変調表 WT、戦国変調表 GWT、プライズ効果表 PT
          妖魔化（異形表、妖魔忍法表一括） MT、異形表 MTR、妖魔忍法表(x:A,B,C) DSx

        ・各種表：流派ブック以降
          比良坂流派ブック
            パニック表 HRPT
          鞍馬流派ブック
            新戦場表 BNT
          御斎流派ブック
            覚醒表 OTAT
            忍法授業シーン表（x:1-攻撃系 2-防御系 3-戦略系）NCTx
            【数奇】OTS
          隠忍流派ブック
            妖術変調対応表（x:なし-現代／戦国、1-現代、2-戦国）YWTx
            妖魔化（新異形表利用） NMT、新異形表 NMTR、妖魔忍法表（x:1-異霊 2-凶身 3-神化 4-攻激）DSNx
            出物表 ONDT

        ・各種表：基本ルールブック改訂版以前
          無印
            旧ファンブル表 OFT 、旧変調表 OWT、旧戦場表 OBT、異形表 MT
          怪
            怪ファンブル表 KFT、怪変調表 KWT (基本ルールブックと同一）

        ・シーン表
          基本ルールブック
            通常 ST、出島 DST、都市 CST、館 MST、トラブル TST、回想 KST、日常 NST、学校 GAST、戦国 GST
          忍秘伝
            中忍試験 HC、滅びの塔 HT、影の街 HK、夜行列車 HY、病院 HO、龍動 HR、密室 HM、催眠 HS
          正忍記
            カジノ TC、ロードムービー TRM、マスカレイド・キャッスル TMC、月天に死の咲く TGS、恋人との日々 TKH、学校（黒星祭） TKG、魔都学園 TMG、魔都東京 TMT
          流派ブック以降
            御斎流派ブック
              不良高校 OTFK
          基本ルールブック改訂版以前
            死
              東京 TKST
            リプレイ戦1〜2巻
              京都 KYST、神社仏閣 JBST
          その他
            秋空に雪舞えば AKST、夏の終わり NTST、出島EX DXST、災厄 CLST、斜歯ラボ HLST、培養プラント PLST

        ・D66ダイスあり
      INFO_MESSAGE_TEXT

      class DemonSkillTableForMetamorphose
        def initialize(pretext, table)
          @pretext = pretext
          @table = table
        end

        def roll(randomizer)
          return "#{@pretext} ＞ #{@table.roll(randomizer)}"
        end
      end

      def initialize(command)
        super(command)

        @sort_add_dice = true
        @d66_sort_type = D66SortType::ASC
      end

      def result_2d6(total, dice_total, _dice_list, cmp_op, target)
        return nil unless cmp_op == :>=

        if dice_total <= 2
          Result.fumble(translate("fumble"))
        elsif dice_total >= 12
          Result.critical(translate("ShinobiGami.special"))
        elsif target == "?"
          nil
        elsif total >= target
          Result.success(translate("success"))
        else
          Result.failure(translate("failure"))
        end
      end

      register_prefix('\d*SG')

      def eval_game_system_specific_command(command)
        return action_roll(command) || repeat_table(command)
      end

      def repeat_table(command)
        times = command.start_with?(/\d/) ? command.to_i : 1
        key = command.sub(/^\d+/, '')
        results = [*0...times].map do |_|
          roll_tables(key, self.class::TABLES) || roll_tables(key, self.class::SCENE_TABLES) ||
            roll_tables(key, self.class::DEMON_SKILL_TABLES) || roll_tables(key, self.class::DEMON_SKILL_TABLES_NEW) || self.class::RTT.roll_command(@randomizer, key)
        end.compact
        return nil if results.empty?

        return results.join("\n")
      end

      private

      def action_roll(command)
        parser = Command::Parser.new(/\d*SG/, round_type: round_type)
                                .restrict_cmp_op_to(:>=, nil)
                                .enable_critical
                                .enable_fumble
        cmd = parser.parse(command)
        return nil unless cmd

        times = cmd.command.start_with?(/\d/) ? cmd.command.to_i : 2
        return nil if times <= 1

        cmd.critical ||= 12
        cmd.fumble ||= 2

        dice_list_full = @randomizer.roll_barabara(times, 6).sort
        dice_list_full_str = "[#{dice_list_full.join(',')}]" if times > 2

        dice_list = dice_list_full[-2, 2]
        dice_total = dice_list.sum()
        total = dice_total + cmd.modify_number

        result =
          if dice_total <= cmd.fumble
            Result.fumble(translate("fumble"))
          elsif dice_total >= cmd.critical
            Result.critical(translate("ShinobiGami.special"))
          elsif cmd.cmp_op.nil?
            Result.new
          elsif total >= cmd.target_number
            Result.success(translate("success"))
          else
            Result.failure(translate("failure"))
          end

        sequence = [
          "(#{cmd.to_s(:after_modify_number)})",
          dice_list_full_str,
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
          mt_pretext  = I18n.translate("ShinobiGami.table.MT.pretext",  locale: locale)
          nmt_pretext = I18n.translate("ShinobiGami.table.NMT.pretext", locale: locale)
          mt_items    = I18n.translate("ShinobiGami.table.MT.items",    locale: locale)
          nmt_items   = I18n.translate("ShinobiGami.table.NMT.items",   locale: locale)
          
          dsa = DiceTable::Table.from_i18n("ShinobiGami.table.DSA", locale)
          dsb = DiceTable::Table.from_i18n("ShinobiGami.table.DSB", locale)
          dsc = DiceTable::Table.from_i18n("ShinobiGami.table.DSC", locale)
          dsn1 = DiceTable::Table.from_i18n("ShinobiGami.table.DSN1", locale)
          dsn2 = DiceTable::Table.from_i18n("ShinobiGami.table.DSN2", locale)
          dsn3 = DiceTable::Table.from_i18n("ShinobiGami.table.DSN3", locale)
          dsn4 = DiceTable::Table.from_i18n("ShinobiGami.table.DSN4", locale)

          {
            'MT' => DiceTable::ChainTable.new(
              I18n.translate("ShinobiGami.table.MT.name", locale: locale),
              '1D6',
              [
                DemonSkillTableForMetamorphose.new(mt_pretext[0], dsa),
                DemonSkillTableForMetamorphose.new(mt_pretext[1], dsb),
                DemonSkillTableForMetamorphose.new(mt_pretext[2], dsc),
                mt_items[3],
                mt_items[4],
                mt_items[5],
              ]
            ),
            'MTR'  => DiceTable::Table.from_i18n("ShinobiGami.table.MTR",  locale),
            'NMT' => DiceTable::ChainTable.new(
              I18n.translate("ShinobiGami.table.NMT.name", locale: locale),
              '1D6',
              [
                DemonSkillTableForMetamorphose.new(nmt_pretext[0], dsn1),
                DemonSkillTableForMetamorphose.new(nmt_pretext[1], dsn2),
                DemonSkillTableForMetamorphose.new(nmt_pretext[2], dsn3),
                DemonSkillTableForMetamorphose.new(nmt_pretext[3], dsn4),
                nmt_items[4],
                nmt_items[5],
              ]
            ),
            'NMTR' => DiceTable::Table.from_i18n("ShinobiGami.table.NMTR", locale),
            'FT'   => DiceTable::Table.from_i18n("ShinobiGami.table.FT",   locale),
            'OFT'  => DiceTable::Table.from_i18n("ShinobiGami.table.OFT",  locale),
            'KFT'  => DiceTable::Table.from_i18n("ShinobiGami.table.KFT",  locale),
            'ET'   => DiceTable::Table.from_i18n("ShinobiGami.table.ET",   locale),
            'WT'   => DiceTable::Table.from_i18n("ShinobiGami.table.WT",   locale),
            'OWT'  => DiceTable::Table.from_i18n("ShinobiGami.table.OWT",  locale),
            'KWT'  => DiceTable::Table.from_i18n("ShinobiGami.table.KWT",  locale),
            'GWT'  => DiceTable::Table.from_i18n("ShinobiGami.table.GWT",  locale),
            'OBT'  => DiceTable::Table.from_i18n("ShinobiGami.table.OBT",  locale),
            'BT'   => DiceTable::Table.from_i18n("ShinobiGami.table.BT",   locale),
            'PT'   => DiceTable::Table.from_i18n("ShinobiGami.table.PT",   locale),
            ## 以下流派ブック
            'BNT'  => DiceTable::Table.from_i18n("ShinobiGami.table.BNT",  locale),
            'YWT'  => DiceTable::Table.from_i18n("ShinobiGami.table.YWT",  locale),
            'YWT1' => DiceTable::Table.from_i18n("ShinobiGami.table.YWT1", locale),
            'YWT2' => DiceTable::Table.from_i18n("ShinobiGami.table.YWT2", locale),
            'OTS'  => DiceTable::Table.from_i18n("ShinobiGami.table.OTS",  locale),
            'HRPT' => DiceTable::Table.from_i18n("ShinobiGami.table.HRPT", locale),
            'OTAT' => DiceTable::Table.from_i18n("ShinobiGami.table.OTAT", locale),
            'ONDT' => DiceTable::Table.from_i18n("ShinobiGami.table.ONDT", locale),
            ## 忍法授業シーン表（シナリオとは無関係なためこちらに記載）
            'NCT1' => DiceTable::Table.from_i18n("ShinobiGami.table.NCT1", locale),
            'NCT2' => DiceTable::Table.from_i18n("ShinobiGami.table.NCT2", locale),
            'NCT3' => DiceTable::Table.from_i18n("ShinobiGami.table.NCT3", locale),
          }
        end

        def translate_scene_tables(locale)
          {
            ## 以下シーン表
            'ST'   => DiceTable::Table.from_i18n("ShinobiGami.scene_table.ST",   locale),
            'CST'  => DiceTable::Table.from_i18n("ShinobiGami.scene_table.CST",  locale),
            'MST'  => DiceTable::Table.from_i18n("ShinobiGami.scene_table.MST",  locale),
            'DST'  => DiceTable::Table.from_i18n("ShinobiGami.scene_table.DST",  locale),
            'TST'  => DiceTable::Table.from_i18n("ShinobiGami.scene_table.TST",  locale),
            'NST'  => DiceTable::Table.from_i18n("ShinobiGami.scene_table.NST",  locale),
            'TKST' => DiceTable::Table.from_i18n("ShinobiGami.scene_table.TKST", locale),
            'KST'  => DiceTable::Table.from_i18n("ShinobiGami.scene_table.KST",  locale),
            'GST'  => DiceTable::Table.from_i18n("ShinobiGami.scene_table.GST",  locale),
            'GAST' => DiceTable::Table.from_i18n("ShinobiGami.scene_table.GAST", locale),
            'KYST' => DiceTable::Table.from_i18n("ShinobiGami.scene_table.KYST", locale),
            'JBST' => DiceTable::Table.from_i18n("ShinobiGami.scene_table.JBST", locale),
            'AKST' => DiceTable::Table.from_i18n("ShinobiGami.scene_table.AKST", locale),
            'CLST' => DiceTable::Table.from_i18n("ShinobiGami.scene_table.CLST", locale),
            'DXST' => DiceTable::Table.from_i18n("ShinobiGami.scene_table.DXST", locale),
            'HC'   => DiceTable::Table.from_i18n("ShinobiGami.scene_table.HC",   locale),
            'HK'   => DiceTable::Table.from_i18n("ShinobiGami.scene_table.HK",   locale),
            'HLST' => DiceTable::Table.from_i18n("ShinobiGami.scene_table.HLST", locale),
            'HM'   => DiceTable::Table.from_i18n("ShinobiGami.scene_table.HM",   locale),
            'HO'   => DiceTable::Table.from_i18n("ShinobiGami.scene_table.HO",   locale),
            'HR'   => DiceTable::Table.from_i18n("ShinobiGami.scene_table.HR",   locale),
            'HS'   => DiceTable::Table.from_i18n("ShinobiGami.scene_table.HS",   locale),
            'HT'   => DiceTable::Table.from_i18n("ShinobiGami.scene_table.HT",   locale),
            'HY'   => DiceTable::Table.from_i18n("ShinobiGami.scene_table.HY",   locale),
            'NTST' => DiceTable::Table.from_i18n("ShinobiGami.scene_table.NTST", locale),
            'PLST' => DiceTable::Table.from_i18n("ShinobiGami.scene_table.PLST", locale),
            ## 以下正忍記
            'TMT'  => DiceTable::Table.from_i18n("ShinobiGami.scene_table.TMT",  locale),
            'TMG'  => DiceTable::Table.from_i18n("ShinobiGami.scene_table.TMG",  locale),
            'TC'   => DiceTable::Table.from_i18n("ShinobiGami.scene_table.TC",   locale),
            'TGS'  => DiceTable::Table.from_i18n("ShinobiGami.scene_table.TGS",  locale),
            'TRM'  => DiceTable::Table.from_i18n("ShinobiGami.scene_table.TRM",  locale),
            'TMC'  => DiceTable::Table.from_i18n("ShinobiGami.scene_table.TMC",  locale),
            'TKG'  => DiceTable::Table.from_i18n("ShinobiGami.scene_table.TKG",  locale),
            'TKH'  => DiceTable::Table.from_i18n("ShinobiGami.scene_table.TKH",  locale),
            ## 以下流派ブック
            'OTFK' => DiceTable::Table.from_i18n("ShinobiGami.scene_table.OTFK", locale),
          }
        end

        def translate_demon_skill_tables(locale)
          {
            # 妖魔忍法表A, B, C
            'DSA' => DiceTable::Table.from_i18n("ShinobiGami.table.DSA", locale),
            'DSB' => DiceTable::Table.from_i18n("ShinobiGami.table.DSB", locale),
            'DSC' => DiceTable::Table.from_i18n("ShinobiGami.table.DSC", locale),
          }
        end

        def translate_demon_skill_tables_new(locale)
          {
            # 妖魔忍法表（隠忍流派）
            'DSN1' => DiceTable::Table.from_i18n("ShinobiGami.table.DSN1", locale),
            'DSN2' => DiceTable::Table.from_i18n("ShinobiGami.table.DSN2", locale),
            'DSN3' => DiceTable::Table.from_i18n("ShinobiGami.table.DSN3", locale),
            'DSN4' => DiceTable::Table.from_i18n("ShinobiGami.table.DSN4", locale),
          }
        end

        def translate_rtt(locale)
          DiceTable::SaiFicSkillTable.from_i18n("ShinobiGami.RTT", locale)
        end

      end

      DEMON_SKILL_TABLES = translate_demon_skill_tables(:ja_jp).freeze
      DEMON_SKILL_TABLES_NEW = translate_demon_skill_tables_new(:ja_jp).freeze
      TABLES = translate_tables(:ja_jp).freeze
      SCENE_TABLES = translate_scene_tables(:ja_jp).freeze
      RTT = translate_rtt(:ja_jp)

      register_prefix(RTT.prefixes.map { |k| "\\d*#{k}" }, TABLES.keys.map { |k| "\\d*#{k}" }, SCENE_TABLES.keys.map { |k| "\\d*#{k}" }, DEMON_SKILL_TABLES.keys.map { |k| "\\d*#{k}" }, DEMON_SKILL_TABLES_NEW.keys.map { |k| "\\d*#{k}" })
    end
  end
end