# frozen_string_literal: true

module BCDice
  module GameSystem
    class Dracurouge < Base
      # ゲームシステムの識別子
      ID = 'Dracurouge'

      # ゲームシステム名
      NAME = 'ドラクルージュ'

      # ゲームシステム名の読みがな
      SORT_KEY = 'とらくるうしゆ'

      # ダイスボットの使い方
      HELP_MESSAGE = <<~MESSAGETEXT
        ・行い判定（DRx+y）
        　x：振るサイコロの数（省略時４）、y：渇き修正（省略時０）
        　例） DR　DR6　DR+1　DR5+2
        ・抗い判定（DRRx）
        　x：振るサイコロの数
        　例） DRR3
        ・原風景表（ST）、叙勲表（CO）、叙勲後表（CA）、遥か過去表（EP）
        　原罪表（OS）、受難表（PN）、近況表（RS）、平和な過去表（PP）
        ・堕落表（CTx） x：渇き （例） CT3
        ・堕落の兆し表（CS）、拡張・堕落の兆し表（ECS）
        ・絆内容決定表（BT）
        ・反応表（RTxy）x：血統、y：道　xy省略で一括表示
        　血統　D：ドラク、R：ローゼンブルク、H：ヘルズガルド、M：ダストハイム
        　　　　A：アヴァローム　N：ノスフェラス、G：ゲイズヴァルト、K：カインシルト
        　道　F：領主、G：近衛、R：遍歴、W：賢者、J：狩人、N：夜獣
        　　　E：将軍、B：僧正、H：空駆、K：船長、L：寵童、V：仲立、U：技師、D：博士
        　　　S：星読、G2：後見
        　例）RT（一括表示）、RTDF（ドラクの領主）、RTAG2（アヴァロームの後見人）
        ・異端の反応表（HRTxy）x：血統、y：道　xy省略で一括表示
        　血統　L：異端卿、V：ヴルコラク、N：ナハツェーラ、K：カルンシュタイン
        　　　　G：グリマルキン、S：ストリガ、M：メリュジーヌ、F：フォーン
        　　　　H：ホムンクルス、E：エナメルム、S2：サングィナリエ、A：アールヴ
        　　　　V2：ヴィーヴル、L2：ルーガルー、A2：アルラウネ、F2：フリッガ
        　道　W：野伏、N：流浪、S：密使、H：魔女、F：剣士、X：検体
        　例）HRT（一括表示）、HRTVW（ヴルコラクの野伏）、HRTF2X（フリッガの検体）
        ・D66ダイスあり
      MESSAGETEXT

      def initialize(command)
        super(command)
        @enabled_d66 = true
        @d66_sort_type = D66SortType::NO_SORT
      end

      def eval_game_system_specific_command(command)
        roll_conduct_dice(command) ||
          roll_resist_dice(command) ||
          getReactionDiceCommandResult(command) ||
          getHeresyReactionDiceCommandResult(command) ||
          getCorruptionDiceCommandResult(command) ||
          roll_tables(command, self.class::TABLES)
      end

      private

      # 行い判定 (DRx+y)
      def roll_conduct_dice(command)
        m = /^DR(\d*[1-9])?(\+\d+)?$/.match(command)
        unless m
          return nil
        end

        dice_count = m[1]&.to_i || 4
        thirsty_point = m[2].to_i

        dice_list = @randomizer.roll_barabara(dice_count, 6).sort

        glory_dice = count_glory_dice(dice_list)
        dice_list += Array.new(glory_dice, 10)

        calculation_process = apply_thirsty_point(dice_list, thirsty_point)

        sequence = [
          "(#{command})",
          "#{dice_count}D6#{Format.modifier(thirsty_point)}",
          calculation_process,
          "[ #{dice_list.join(', ')} ]",
        ].compact

        return sequence.join(" ＞ ")
      end

      def count_glory_dice(dice_list)
        one_count = dice_list.count(1)
        six_count = dice_list.count(6)

        return (one_count / 2) + (six_count / 2)
      end

      def apply_thirsty_point(dice_list, thirsty_point)
        return nil if thirsty_point == 0

        idx = dice_list.rindex { |i| i <= 6 }

        text_list = dice_list.map(&:to_s)
        text_list[idx] += "+#{thirsty_point}"
        dice_list[idx] += thirsty_point

        return "[ #{text_list.join(', ')} ]"
      end

      # 抗い判定 (DRRx)
      def roll_resist_dice(command)
        m = /^DRR(\d+)$/.match(command)
        unless m
          return nil
        end

        dice_count = m[1].to_i
        dice_count = 4 if dice_count == 0

        dice_list = @randomizer.roll_barabara(dice_count, 6).sort

        return "(#{command}) ＞ #{dice_count}D6 ＞ [ #{dice_list.join(', ')} ]"
      end

      def getReactionDiceCommandResult(command)
        return nil unless command =~ /^RT((\w\d*)(\w\d*))?/

        typeText1 = Regexp.last_match(2)
        typeText2 = Regexp.last_match(3)

        name = translate("Dracurouge.RT.name")
        blood = translate("Dracurouge.RT.blood")
        style = translate("Dracurouge.RT.style")

        return getReactionText(name, typeText1, typeText2, blood, style)
      end

      def getHeresyReactionDiceCommandResult(command)
        return nil unless command =~ /^HRT((\w\d*)(\w\d*))?/

        typeText1 = Regexp.last_match(2)
        typeText2 = Regexp.last_match(3)

        name = translate("Dracurouge.HRT.name")
        blood = translate("Dracurouge.HRT.blood")
        style = translate("Dracurouge.HRT.style")

        return getReactionText(name, typeText1, typeText2, blood, style)
      end

      def getReactionText(name, typeText1, typeText2, infos1, infos2)
        return nil unless checkTypeText(typeText1, infos1)
        return nil unless checkTypeText(typeText2, infos2)

        ten_value = @randomizer.roll_once(6)
        one_value = @randomizer.roll_once(6)
        number = "#{ten_value}#{one_value}"

        isBefore = (ten_value < 4)
        infos = isBefore ? infos1 : infos2

        typeText = (isBefore ? typeText1 : typeText2)

        index = (one_value - 1) + (isBefore ? (ten_value - 1) : (ten_value - 4)) * 6
        debug("index", index)

        if typeText.nil?
          resultText = getReactionTextFull(infos, index)
        else
          info = infos[typeText.to_sym]
          return nil if info.nil?

          resultText = getReactionTex(info, index)
        end

        return "#{name}(#{number}) ＞ #{resultText}"
      end

      def checkTypeText(typeText, infos)
        return true if typeText.nil?

        return infos.keys.include?(typeText.to_sym)
      end

      def getReactionTextFull(infos, index)
        resultTexts = []

        infos.each_value do |info|
          resultTexts << getReactionTex(info, index)
        end

        return resultTexts.join('／')
      end

      def getReactionTex(info, index)
        typeName = info[:name]
        text = info[:table][index]

        return "#{typeName}：#{text}"
      end

      def getCorruptionDiceCommandResult(command)
        return nil unless command =~ /^CT(\d+)$/

        modify = Regexp.last_match(1).to_i

        name = translate("Dracurouge.CT.name")
        table =
          [
            [0, translate("Dracurouge.CT.table.0")],
            [1, translate("Dracurouge.CT.table.1")],
            [3, translate("Dracurouge.CT.table.3")],
            [5, translate("Dracurouge.CT.table.5")],
            [6, translate("Dracurouge.CT.table.6")],
            [7, translate("Dracurouge.CT.table.7")],
            [8, translate("Dracurouge.CT.table.8")],
            [99, translate("Dracurouge.CT.table.99")],
          ]

        dice_list = @randomizer.roll_barabara(2, 6)
        number = dice_list.sum()
        number_text = dice_list.join(",")

        index = (number - modify)
        debug('index', index)
        text = get_table_by_number(index, table)

        return "2D6[#{number_text}]-#{modify} ＞  #{name}(#{index}) ＞ #{text}"
      end

      class YearTable
        # @param key [String]
        # @param locale [Symbol]
        # @param years [Array<String>]
        # @return [YearTable]
        def self.from_i18n(key, locale, years)
          table = I18n.translate(key, locale: locale, raise: true)
          items = table[:items].zip(years)
          return new(table[:name], table[:year_title], items)
        end

        # @param name [String]
        # @param year_title [String]
        # @param items [Array<Array<(String, String)>>]
        def initialize(name, year_title, items)
          @name = name
          @year_title = year_title
          @items = items.freeze
        end

        # @param randomizer [Randomizer]
        # @return [String]
        def roll(randomizer)
          tens, ones = randomizer.roll_barabara(2, 6)
          index = (tens - 1) * 6 + (ones - 1)

          text, year_expr = @items[index]
          interim_expr = year_expr.gsub(/\d+D6+/) { |expr| roll_d6x(expr, randomizer) }
          year = ArithmeticEvaluator.eval(interim_expr.gsub("×", "*"))

          "#{@name}(#{tens}#{ones}) ＞ #{text} ＞ #{@year_title}：#{year_expr} ＞ (#{interim_expr}) ＞ #{@year_title}：#{year}年"
        end

        private

        # D66と同様の形式でD666などにも対応したダイスロール
        #
        # @param expr [String]
        # @param randomizer [Randomizer]
        # @return [Integer]
        def roll_d6x(expr, randomizer)
          times, sides = expr.split("D", 2)
          times = times.to_i

          list = Array.new(times) do
            randomizer.roll_barabara(sides.length, 6)
                      .reverse # テスト系の互換性のために反転する
                      .map.with_index { |x, idx| x * (10**idx) }
                      .sum()
          end

          return list.sum()
        end
      end

      class << self
        private

        def translate_tables(locale)
          {
            "CO" => YearTable.from_i18n(
              "Dracurouge.table.CO",
              locale,
              [
                "7+1D6×1D6",
                "7+1D6×1D6",
                "7+1D6×1D6",
                "7+1D6×1D6",
                "7+1D6×1D6",
                "7+1D6×1D6",
                "7+1D6×1D6",
                "10+2D6",
                "7+1D6×1D6",
                "14+1D6×1D6",
                "7+1D6×1D6",
                "10+1D6×1D6",
                "7+1D6×1D6",
                "10+2D6",
                "7+1D6×1D6",
                "14+1D6×1D6",
                "10+2D6",
                "7+1D6×1D6",
                "14+1D6×1D6",
                "18+1D6×1D6",
                "10+2D6",
                "7+1D6×1D6",
                "7+1D6×1D6",
                "7+1D6×1D6",
                "7+1D6×1D6",
                "30+1D6×1D6",
                "14+1D6×1D6",
                "7+1D6×1D6",
                "14+1D6×1D6",
                "10+2D6",
                "14+1D6×1D6",
                "14+1D6×1D6",
                "7+4D6",
                "14+1D6×1D6",
                "7+1D6×1D6",
                "7+1D6×1D6",
              ]
            ),
            "CA" => YearTable.from_i18n(
              "Dracurouge.table.CA",
              locale,
              [
                "2D6×10",
                "1D6×1D6",
                "1D6×1D6",
                "2D6×5",
                "2D6×10",
                "1D6×1D6",
                "2D6×10",
                "1D6×5",
                "2D6×10",
                "2D6×3",
                "1D6×1D6",
                "1D6×1D6",
                "2D6×10",
                "2D6×10",
                "2D6×20",
                "2D6×10",
                "2D6×20",
                "1D6×1D6",
                "1D6×3",
                "1D6×1D6",
                "1D6×5",
                "2D6×10",
                "1D6×1D6",
                "2D6×10",
                "2D6",
                "1D6×1D6",
                "2D6",
                "1D6×1D6",
                "2D6×20",
                "2D6×10",
                "1D6×1D6",
                "2D6×50",
                "2D6×10",
                "1D6×1D6",
                "2D6×5",
                "1D6×1D6",
              ]
            ),
            "EP" => YearTable.from_i18n(
              "Dracurouge.table.EP",
              locale,
              [
                "1D66+1300",
                "1D666",
                "1D666",
                "1D666",
                "1D66+1250",
                "1D666",
                "3D6×100",
                "2D6×100",
                "1D66+1210",
                "1D666",
                "2D6×100",
                "3D6×100",
                "1D66+1300",
                "2D6×100",
                "1D6+1250",
                "1D666",
                "1D666",
                "1D666",
                "1D66+1250",
                "2D6×100",
                "1D666",
                "3D6×100",
                "2D6×100",
                "2D6×100",
                "1D6×150",
                "2D6×100",
                "1D66+1250",
                "1D66+400",
                "1212",
                "2D6×100",
                "2D6×100",
                "1D66×10",
                "3D6×100",
                "3D6×100",
                "1D66+1300",
                "1D66+1833",
              ]
            ),
            "OS" => YearTable.from_i18n(
              "Dracurouge.table.OS",
              locale,
              [
                "7+1D6×1D6",
                "7+1D6×1D6",
                "7+1D6×1D6",
                "7+1D6×1D6",
                "7+1D6×1D6",
                "7+1D6×1D6",
                "7+1D6×1D6",
                "7+1D6×1D6",
                "7+1D6×1D6",
                "13+1D6×1D6",
                "7+1D6×1D6",
                "13+1D6×1D6",
                "7+1D6×1D6",
                "13+1D6×1D6",
                "13+1D6×1D6",
                "13+1D6×1D6",
                "7+1D6×1D6",
                "7+1D6×1D6",
                "10+1D6×1D6",
                "7+1D6×1D6",
                "15+1D6×1D6",
                "6+2D6",
                "7+1D6×1D6",
                "7+1D6×1D6",
                "13+1D6×1D6",
                "35+1D6×1D6",
                "9+2D6",
                "13+1D6×1D6",
                "9+2D6",
                "6+2D6",
                "7+1D6×1D6",
                "7+2D6",
                "7+1D6×1D5",
                "7+1D6×1D6",
                "13+1D6×1D6",
                "7+1D6×1D6",
              ]
            ),
            "RS" => YearTable.from_i18n(
              "Dracurouge.table.RS",
              locale,
              [
                "2D6×10",
                "1D6×1D6",
                "1D6×1D6",
                "1D6×1D6",
                "3D6×30",
                "3D6×30",
                "2D6×10",
                "2D6×10",
                "2D6×10",
                "2D6×10",
                "2D6×20",
                "1D6×1D6",
                "1D6×1D6",
                "1D6×1D6",
                "1",
                "2D6×10",
                "2D6×20",
                "1D6×1D6",
                "1D6×1D6",
                "3D6×30",
                "3D6×20",
                "1D6×1D6",
                "3D6×30",
                "3D6×20",
                "1D6×1D6",
                "1D6×1D6",
                "1D6×1D6",
                "1D6×1D6",
                "1D6×10",
                "2D6×10",
                "3D6×50",
                "1D6×1D6",
                "3D6×20",
                "2D6×10",
                "1D6×1D6",
                "3D6×50",
              ]
            ),
            "PP" => YearTable.from_i18n(
              "Dracurouge.table.PP",
              locale,
              [
                "8+2D6",
                "6+2D6",
                "7+1D6×1D6",
                "15+1D6×1D6",
                "7+1D6×1D6",
                "7+1D6×1D6",
                "7+1D6×1D6",
                "7+1D6×1D6",
                "7+1D6×1D6",
                "7+1D6×1D6",
                "7+1D6×1D6",
                "7+1D6×1D6",
                "6+2D6",
                "7+1D6×1D6",
                "9+2D6",
                "15+1D6×1D6",
                "9+3D6",
                "7+1D6×1D6",
                "10+1D6×1D6",
                "9+2D6",
                "9+2D6",
                "9+3D6",
                "6+2D6",
                "7+1D6×1D6",
                "7+1D6×1D6",
                "7+1D6×1D6",
                "6+2D6",
                "10+1D6×1D6",
                "7+1D6×1D6",
                "12+1D6×1D6",
                "15+1D6×1D6",
                "9+3D6",
                "7+1D6×1D6",
                "7+1D6×1D6",
                "7+1D6×1D6",
                "12+4D6",
              ]
            ),
            "ST" => DiceTable::D66Table.from_i18n("Dracurouge.table.ST", locale),
            "PN" => DiceTable::D66Table.from_i18n("Dracurouge.table.PN", locale),
            "CS" => DiceTable::Table.from_i18n("Dracurouge.table.CS", locale),
            "ECS" => DiceTable::D66Table.from_i18n("Dracurouge.table.ECS", locale),
            "BT" => DiceTable::Table.from_i18n("Dracurouge.table.BT", locale),
          }
        end
      end

      TABLES = translate_tables(:ja_jp)

      register_prefix('DR', 'RT', 'HRT', 'CT\d+', TABLES.keys)
    end
  end
end
