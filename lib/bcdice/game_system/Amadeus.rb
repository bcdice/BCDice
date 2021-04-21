# frozen_string_literal: true

require "bcdice/arithmetic_evaluator"
require "bcdice/format"
require "bcdice/normalize"

module BCDice
  module GameSystem
    class Amadeus < Base
      # ゲームシステムの識別子
      ID = 'Amadeus'

      # ゲームシステム名
      NAME = 'アマデウス'

      # ゲームシステム名の読みがな
      SORT_KEY = 'あまてうす'

      # ダイスボットの使い方
      HELP_MESSAGE = <<~INFO_MESSAGE_TEXT
        ・判定(Rx±y@z>=t)
        　能力値のダイスごとに成功・失敗の判定を行います。
        　x：能力ランク(S,A～D)　y：修正値（省略可）
        　z：スペシャル最低値（省略：6）　t：目標値（省略：4）
        　　例） RA　RB-1　RC>=5　RD+2　RS-1@5>=6
        　出力書式は
        　　(達成値)_(判定結果)[(出目)(対応するインガ)]
        　C,Dランクでは対応するインガは出力されません。
        　　出力例)　2_ファンブル！[1黒] / 3_失敗[3青]
        ・各種表
        　境遇表 ECT／関係表 RT／親心表 PRT／戦場表 BST／休憩表 BT／
        　ファンブル表 FT／致命傷表 FWT／戦果表 BRT／ランダムアイテム表 RIT／
        　損傷表 WT／悪夢表 NMT／目標表 TGT／制約表 CST／
        　ランダムギフト表 RGT／決戦戦果表 FBT／
        　店内雰囲気表 SAT／特殊メニュー表 SMT
        ・試練表（～VT）
        　ギリシャ神群 GCVT／ヤマト神群 YCVT／エジプト神群 ECVT／
        　クトゥルフ神群 CCVT／北欧神群 NCVT／中華神群 CHVT／
          ラストクロニクル神群 LCVT／ケルト神群 KCVT／ダンジョン DGVT／日常 DAVT
        ・挑戦テーマ表（～CT）
        　武勇 PRCT／技術 TCCT／頭脳 INCT／霊力 PSCT／愛 LVCT／日常 DACT
      INFO_MESSAGE_TEXT

      def initialize(command)
        super(command)

        @sort_add_dice = true
        @enabled_d66 = true
        @d66_sort_type = D66SortType::ASC
      end

      def eval_game_system_specific_command(command)
        text = amadeusDice(command)
        return text unless text.nil?

        return roll_tables(command, self.class::TABLES)
      end

      def amadeusDice(command)
        m = /^(R([A-DS])([+\-\d]*))(@(\d))?((>(=)?)([+\-\d]*))?(@(\d))?$/i.match(command)
        unless m
          return nil
        end

        skillRank = m[2]
        modifier = ArithmeticEvaluator.eval(m[3])
        cmp_op = m[7] ? Normalize.comparison_operator(m[7]) : :>=
        target = m[9] ? ArithmeticEvaluator.eval(m[9]) : 4
        specialNum = (m[5] || m[11] || 6).to_i

        diceCount = CHECK_DICE_COUNT[skillRank]

        diceList = @randomizer.roll_barabara(diceCount, 6)
        diceText = diceList.join(",")
        specialText = (specialNum == 6 ? "" : "@#{specialNum}")

        diceList = [diceList.min] if skillRank == "D"
        available_inga = diceList.size > 1
        inga_table = translate("Amadeus.inga_table")

        results =
          diceList.map do |dice|
            achieve = dice + modifier
            result = check_success(achieve, dice, cmp_op, target, specialNum)
            if available_inga
              inga = inga_table[dice - 1]
              "#{achieve}_#{result}[#{dice}#{inga}]"
            else
              "#{achieve}_#{result}[#{dice}]"
            end
          end

        sequence = [
          "(R#{skillRank}#{Format.modifier(modifier)}#{specialText}#{cmp_op}#{target})",
          "[#{diceText}]#{Format.modifier(modifier)}",
          results.join(" / ")
        ]

        return sequence.join(" ＞ ")
      end

      def check_success(total_n, dice_n, cmp_op, target_num, special_n)
        return translate("Amadeus.fumble") if dice_n == 1
        return translate("Amadeus.special") if dice_n >= special_n

        if total_n.send(cmp_op, target_num)
          translate("success")
        else
          translate("failure")
        end
      end

      CHECK_DICE_COUNT = {"S" => 4, "A" => 3, "B" => 2, "C" => 1, "D" => 2}.freeze

      def self.translate_tables(locale)
        {
          "ECT" => DiceTable::Table.from_i18n("Amadeus.table.ECT", locale),
          "BST" => DiceTable::Table.from_i18n("Amadeus.table.BST", locale),
          "RT" => DiceTable::Table.from_i18n("Amadeus.table.RT", locale),
          "PRT" => DiceTable::Table.from_i18n("Amadeus.table.PRT", locale),
          "FT" => DiceTable::Table.from_i18n("Amadeus.table.FT", locale),
          "BT" => DiceTable::D66Table.from_i18n("Amadeus.table.BT", locale),
          "FWT" => DiceTable::Table.from_i18n("Amadeus.table.FWT", locale),
          "BRT" => DiceTable::Table.from_i18n("Amadeus.table.BRT", locale),
          "RIT" => DiceTable::Table.from_i18n("Amadeus.table.RIT", locale),
          "WT" => DiceTable::Table.from_i18n("Amadeus.table.WT", locale),
          "NMT" => DiceTable::Table.from_i18n("Amadeus.table.NMT", locale),
          "TGT" => DiceTable::Table.from_i18n("Amadeus.table.TGT", locale),
          "CST" => DiceTable::Table.from_i18n("Amadeus.table.CST", locale),
          "GCVT" => DiceTable::Table.from_i18n("Amadeus.table.GCVT", locale),
          "YCVT" => DiceTable::Table.from_i18n("Amadeus.table.YCVT", locale),
          "ECVT" => DiceTable::Table.from_i18n("Amadeus.table.ECVT", locale),
          "CCVT" => DiceTable::Table.from_i18n("Amadeus.table.CCVT", locale),
          "NCVT" => DiceTable::Table.from_i18n("Amadeus.table.NCVT", locale),
          "DGVT" => DiceTable::Table.from_i18n("Amadeus.table.DGVT", locale),
          "DAVT" => DiceTable::Table.from_i18n("Amadeus.table.DAVT", locale),
          "PRCT" => DiceTable::Table.from_i18n("Amadeus.table.PRCT", locale),
          "TCCT" => DiceTable::Table.from_i18n("Amadeus.table.TCCT", locale),
          "INCT" => DiceTable::Table.from_i18n("Amadeus.table.INCT", locale),
          "PSCT" => DiceTable::Table.from_i18n("Amadeus.table.PSCT", locale),
          "LVCT" => DiceTable::Table.from_i18n("Amadeus.table.LVCT", locale),
          "DACT" => DiceTable::Table.from_i18n("Amadeus.table.DACT", locale),
          "RGT" => DiceTable::Table.from_i18n("Amadeus.table.RGT", locale),
          "FBT" => DiceTable::Table.from_i18n("Amadeus.table.FBT", locale),
          "CHVT" => DiceTable::Table.from_i18n("Amadeus.table.CHVT", locale),
          "LCVT" => DiceTable::Table.from_i18n("Amadeus.table.LCVT", locale),
          "KCVT" => DiceTable::Table.from_i18n("Amadeus.table.KCVT", locale),
          "SAT" => DiceTable::D66Table.from_i18n("Amadeus.table.SAT", locale),
          "SMT" => DiceTable::D66Table.from_i18n("Amadeus.table.SMT", locale),
        }
      end

      TABLES = translate_tables(:ja_jp)

      register_prefix('R[A-DS]', TABLES.keys)
    end
  end
end
