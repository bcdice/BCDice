# frozen_string_literal: true

require "bcdice/dice_table/table"
require "bcdice/dice_table/d66_grid_table"

module BCDice
  module GameSystem
    class StellarKnights < Base
      # ゲームシステムの識別子
      ID = 'StellarKnights'

      # ゲームシステム名
      NAME = '銀剣のステラナイツ'

      # ゲームシステム名の読みがな
      SORT_KEY = 'きんけんのすてらないつ'

      # ダイスボットの使い方
      HELP_MESSAGE = <<~MESSAGETEXT
        ・判定　nSK[d][,k>l,...]
        []内は省略可能。
        n: ダイス数、d: アタック判定における対象の防御力、k, l: ダイスの出目がkならばlに変更（アマランサスのスキル「始まりの部屋」用）
        d省略時はダイスを振った結果のみ表示。（nSKはnB6と同じ）

        4SK: ダイスを4個振って、その結果を表示
        5SK3: 【アタック判定：5ダイス】、対象の防御力を3として成功数を表示
        3SK,1>6: ダイスを3個振り、出目が1のダイスを全て6に変更し、その結果を表示
        6SK4,1>6,2>6: 【アタック判定：6ダイス】、出目が1と2のダイスを全て6に変更、対象の防御力を4として成功数を表示

        ・基本
        TT：お題表
        STA    ：シチュエーション表A：時間 (Situation Table A)
        STB    ：シチュエーション表B：場所 (ST B)
        STB2[n]：シチュエーション表B その2：学園編 (ST B 2)
        　n: 1(アーセルトレイ), 2(イデアグロリア), 3(シトラ), 4(フィロソフィア), 5(聖アージェティア), 6(SoA)
        STC    ：シチュエーション表C：話題 (ST C)
        ALLS   ：シチュエーション表全てを一括で（学園編除く）
        GAT：所属組織決定 (Gakuen Table)
        HOT：希望表 (Hope Table)
        DET：絶望表 (Despair Table)
        WIT：願い事表 (Wish Table)
        YST：あなたの物語表 (Your Story Table)
        YSTA：あなたの物語表：異世界 (YST Another World)
        PET：性格表 (Personality Table)
            性格表を2回振り、性格を決定する

        ・霧と桜のマルジナリア
        YSTM：あなたの物語表：マルジナリア世界 (YST Marginalia)
        STM：シチュエーション表：マルジナリア世界 (ST Marginalia)
        YSTL：あなたの物語表：手紙世界 (YST Letter)
        YSTR：あなたの物語表：リコレクト・ドール (YST Recollect-doll)
        STBR：シチュエーション表B：場所（リコレクト・ドール） (ST B Recollect-doll)
        STCR：シチュエーション表C：リコレクト (ST C Recollect)
        STBS：シチュエーション表B：シトラセッティング (ST B Sut Tu Real)
        STE：シチュエーション表：エクリプス専用 (ST Eclipse)

        ・紫弾のオルトリヴート
        FT：フラグメント表 (Fragment Table)
            フラグメント表を５回振る
        FTx：フラグメント表をx回振る
        YSTB：あなたの物語表：ブリンガー (YST Bringer)
        YSTF：あなたの物語表：フォージ (YST Forge)
        STAL：シチュエーション表：オルトリヴート (ST Alt-Levoot)
      MESSAGETEXT

      def initialize(command)
        super(command)

        @sort_barabara_dice = true # バラバラロール（Bコマンド）でソート有
        @d66_sort_type = D66SortType::NO_SORT
      end

      def eval_game_system_specific_command(command)
        command = command.upcase

        if (table = TABLES[command])
          table.roll(@randomizer)
        elsif (m = /(\d+)SK(\d)?((,\d>\d)+)?/.match(command))
          resolute_action(m[1].to_i, m[2] && m[2].to_i, m[3], command)
        elsif command == 'STB2'
          roll_all_situation_b2_tables
        elsif command == 'ALLS'
          roll_all_situation_tables
        elsif command == "PET"
          roll_personality_table
        elsif (m = /FT(\d+)?/.match(command))
          num = (m[1] || 5).to_i
          roll_fragment_table(num)
        end
      end

      private

      # @param [Integer] num_dices
      # @param [Integer | nil] defence
      # @param [String] dice_change_text
      # @param [String] command
      # @return [String]
      def resolute_action(num_dices, defence, dice_change_text, command)
        dices = @randomizer.roll_barabara(num_dices, 6).sort
        dice_text = dices.join(",")

        output = "(#{command}) ＞ #{dice_text}"

        # FAQによると、ダイスの置き換えは宣言された順番に適用されていく
        dice_change_rules = parse_dice_change_rules(dice_change_text)
        dice_change_rules.each do |rule|
          dices.map! { |val| val == rule[:from] ? rule[:to] : val }
        end

        unless dice_change_rules.empty?
          dices.sort!
          output += " ＞ [#{dices.join(',')}]"
        end

        unless defence.nil?
          success = dices.count { |val| val >= defence }
          output += " ＞ " + translate("StellarKnights.SK.success_num", success_num: success)
        end

        output
      end

      def parse_dice_change_rules(text)
        return [] if text.nil?

        # 正規表現の都合で先頭に ',' が残っているので取っておく
        text = text[1..-1]
        text.split(',').map do |rule|
          v = rule.split('>').map(&:to_i)
          {
            from: v[0],
            to: v[1],
          }
        end
      end

      def roll_all_situation_b2_tables
        (1..6).map { |num| TABLES["STB2#{num}"].roll(@randomizer) }.join("\n")
      end

      def roll_all_situation_tables
        ['STA', 'STB', 'STC'].map { |command| TABLES[command].roll(@randomizer) }.join("\n")
      end

      def roll_personality_table
        value1, index1 = get_table_by_d66(translate("StellarKnights.PET.items"))
        value2, index2 = get_table_by_d66(translate("StellarKnights.PET.items"))
        name = translate("StellarKnights.PET.name")
        result = translate("StellarKnights.PET.result", value1: value1, value2: value2)
        return "#{name}(#{index1},#{index2}) ＞ #{result}"
      end

      def roll_fragment_table(num)
        if num <= 0
          return nil
        end

        results = Array.new(num) { get_table_by_d66(translate("StellarKnights.FT.items")) }
        values = results.map { |r| r[0] }
        indexes = results.map { |r| r[1] }
        name = translate("StellarKnights.FT.name")

        return "#{name}(#{indexes.join(',')}) ＞ #{values.join(',')}"
      end

      class << self
        private

        def translate_tables(locale)
          {
            "TT" => DiceTable::D66GridTable.from_i18n("StellarKnights.tables.TT", locale),
            "STA" => DiceTable::Table.from_i18n("StellarKnights.tables.STA", locale),
            "STB" => DiceTable::D66OneThirdTable.from_i18n("StellarKnights.tables.STB", locale),
            "STB21" => DiceTable::Table.from_i18n("StellarKnights.tables.STB21", locale),
            "STB22" => DiceTable::Table.from_i18n("StellarKnights.tables.STB22", locale),
            "STB23" => DiceTable::Table.from_i18n("StellarKnights.tables.STB23", locale),
            "STB24" => DiceTable::Table.from_i18n("StellarKnights.tables.STB24", locale),
            "STB25" => DiceTable::Table.from_i18n("StellarKnights.tables.STB25", locale),
            "STB26" => DiceTable::Table.from_i18n("StellarKnights.tables.STB26", locale),
            "STC" => DiceTable::D66HalfGridTable.from_i18n("StellarKnights.tables.STC", locale),
            "GAT" => DiceTable::Table.from_i18n("StellarKnights.tables.GAT", locale),
            "HOT" => DiceTable::D66HalfGridTable.from_i18n("StellarKnights.tables.HOT", locale),
            "DET" => DiceTable::D66HalfGridTable.from_i18n("StellarKnights.tables.DET", locale),
            "WIT" => DiceTable::D66OneThirdTable.from_i18n("StellarKnights.tables.WIT", locale),
            "YST" => DiceTable::D66OneThirdTable.from_i18n("StellarKnights.tables.YST", locale),
            "YSTA" => DiceTable::D66OneThirdTable.from_i18n("StellarKnights.tables.YSTA", locale),
            "YSTM" => DiceTable::D66OneThirdTable.from_i18n("StellarKnights.tables.YSTM", locale),
            "STM" => DiceTable::D66HalfGridTable.from_i18n("StellarKnights.tables.STM", locale),
            "YSTL" => DiceTable::D66HalfGridTable.from_i18n("StellarKnights.tables.YSTL", locale),
            "YSTR" => DiceTable::D66HalfGridTable.from_i18n("StellarKnights.tables.YSTR", locale),
            "STBR" => DiceTable::D66HalfGridTable.from_i18n("StellarKnights.tables.STBR", locale),
            "STCR" => DiceTable::D66HalfGridTable.from_i18n("StellarKnights.tables.STCR", locale),
            "STBS" => DiceTable::D66HalfGridTable.from_i18n("StellarKnights.tables.STBS", locale),
            "STE" => DiceTable::D66HalfGridTable.from_i18n("StellarKnights.tables.STE", locale),
            "YSTB" => DiceTable::D66HalfGridTable.from_i18n("StellarKnights.tables.YSTB", locale),
            "YSTF" => DiceTable::D66HalfGridTable.from_i18n("StellarKnights.tables.YSTF", locale),
            "STAL" => DiceTable::D66HalfGridTable.from_i18n("StellarKnights.tables.STAL", locale),
          }
        end
      end

      TABLES = translate_tables(:ja_jp)

      register_prefix('\d+SK', 'STB2', 'ALLS', 'PET', 'FT', TABLES.keys)
    end
  end
end
