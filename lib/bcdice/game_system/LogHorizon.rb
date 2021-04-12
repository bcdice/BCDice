# frozen_string_literal: true

require "bcdice/base"

module BCDice
  module GameSystem
    class LogHorizon < Base
      # ゲームシステムの識別子
      ID = 'LogHorizon'

      # ゲームシステム名
      NAME = 'ログ・ホライズンTRPG'

      # ゲームシステム名の読みがな
      SORT_KEY = 'ろくほらいすんTRPG'

      # ダイスボットの使い方
      HELP_MESSAGE = <<~MESSAGETEXT
        ■ 判定 (xLH±y>=z)
        　xD6の判定。クリティカル、ファンブルの自動判定を行います。
        　x：xに振るダイス数を入力。
        　±y：yに修正値を入力。±の計算に対応。省略可能。
        　>=z：zに目標値を入力。±の計算に対応。省略可能。
        　例） 3LH　2LH>=8　3LH+1>=10

        ■ 消耗表 (tCTx±y$z)
        　PCT 体力／ECT 気力／GCT 物品／CCT 金銭
        　x:CRを指定。
        　±y:修正値。＋と－の計算に対応。省略可能。
        　$z：＄を付けるとダイス目を z 固定。表の特定の値参照用に。省略可能。
        　例） PCT1　ECT2+1　GCT3-1　CCT3$5

        ■ 消耗表ロール (CTx±y)
        　消耗表ロールを行い、出目を決定する。
        　x：CRを指定。指定できますが、無視されます。省略可能
        　±y：修正値。＋と－の計算に対応。省略可能。

        ■ 財宝表 (tTRSx±y$)
        　LHZB1記載の財宝表
        　CTRS 金銭／MTRS 魔法素材／ITRS 換金アイテム／※HTRS ヒロイン／GTRS ゴブリン財宝表
        　x：CRを指定。省略時はダイス値 0 固定で修正値の表参照。《ゴールドフィンガー》使用時など。
        　±y：修正値。＋と－の計算に対応。省略可能。
        　$：＄を付けると財宝表のダイス目を7固定（1回分のプライズ用）。省略可能。
        　例） CTRS1　MTRS2+1　ITRS3-1　ITRS+27　CTRS3$

        ■ 財宝表（拡張ルールブック） (tTRSEx±y$)
        　LHZB2記載の財宝表
        　CTRSE 金銭／MTRSE 魔法素材／ITRSE 換金アイテム／OTRSE そのほか
        　記法は財宝表と同様

        ■ 財宝表ロール (TRSx±y)
        　財宝表ロールを行い、出目を決定する。
        　x：CRを指定。省略時はCR 0として扱う
        　±y：修正値。＋と－の計算に対応。省略可能。

        ■ イースタル探索表 (ESTLx±y$z)
        　x：CRを指定。省略時はダイス値 0 固定で修正値の表参照。
        　±y：修正値。＋と－の計算に対応。省略可能。
        　$z：＄を付けるとダイス目を z 固定。特定CRの表参照用に。省略可能。
        　例） ESTL1　ESTL+15　ESTL2+1$5　ESTL2-1$5

        ■ プレフィックスドマジックアイテム効果表 (MGRx)
        　xはMGを指定。(LHZB1用)

        ■ 楽器種別表† (MIIx)
        　xは楽器の種類(1～6を指定)、省略可能
        　1 打楽器１／2 鍵盤楽器／3 弦楽器１／4 弦楽器２／5 管楽器１／6 管楽器２

        ■ 特殊消耗表☆ (tSCTx±y$z)
        　消耗表と同様、ただしCRは省略可能。
        　ESCT ロデ研は爆発だ！／CSCT アルヴの呪いじゃ！

        ■ ロデ研の新発明ランダム決定表※ (IATt)
        　IATA 特徴A(メリット)／IATB 特徴B(デメリット)／IATL 見た目／IATT 種類
        　tを省略すると全て表示。tにA/B/L/Tを任意の順で連結可能
        　例）IAT　IATALT  IATABBLT  IATABL

        ■ 表
        　・パーソナリティタグ表 (PTAG)
        　・交友表 (KOYU)
        　・攻撃命中箇所ランダム決定表※ (HLOC)
        　・PC名ランダム決定表※ (PCNM)
        　・アキバの街で遭遇するトラブルランダム決定表※ (TIAS)
        　・廃棄児ランダム決定表※ (ABDC)

        †印は☆印は「イントゥ・ザ・セルデシア さらなるビルドの羽ばたき（１）」より、
        ☆印はセルデシア・ガゼット「できるかな66」Vol.1より、
        ※印は「実録・七面体工房スタッフ座談会(夏の陣)」より。利用法などはそちら参照。
        ・D66ダイスあり
      MESSAGETEXT

      register_prefix('\d+LH', '\w+CT', 'CT', '\w+TRS', 'TRS', 'IAT', 'TIAS', 'ABDC', 'MII', 'ESTL')

      def initialize(command)
        super(command)
        @d66_sort_type = D66SortType::NO_SORT
      end

      def eval_game_system_specific_command(command)
        getCheckRollDiceCommandResult(command) ||
          roll_consumption(command) ||
          roll_consumption_table(command) ||
          roll_treasure(command) ||
          roll_treasure_table(command) ||
          roll_treasure_table_b2(command) ||
          getInventionAttributeTextDiceCommandResult(command) ||
          getTroubleInAkibaStreetDiceCommandResult(command) ||
          getAbandonedChildDiceCommandResult(command) ||
          getMusicalInstrumentTypeDiceCommandResult(command) ||
          roll_eastal_exploration_table(command) ||
          roll_tables(command, self.class::TABLES)
      end

      private

      def getCheckRollDiceCommandResult(command)
        parser = Command::Parser.new(/\d+LH/, round_type: round_type)
                                .restrict_cmp_op_to(nil, :>=)

        parsed = parser.parse(command)
        unless parsed
          return nil
        end

        dice_count = parsed.command.to_i

        dice_list = @randomizer.roll_barabara(dice_count, 6)
        dice_total = dice_list.sum()
        total = dice_total + parsed.modify_number

        sequence = [
          "(#{parsed})",
          "#{dice_total}[#{dice_list.join(',')}]#{Format.modifier(parsed.modify_number)}",
          total,
          result_text(dice_count, dice_list, total, parsed),
        ].compact

        return sequence.join(" ＞ ")
      end

      def result_text(dice_count, dice_list, total, parsed)
        if dice_list.count(6) >= 2
          translate("LogHorizon.LH.critical")
        elsif dice_list.count(1) >= dice_count
          translate("LogHorizon.LH.fumble")
        elsif parsed.cmp_op.nil?
          nil
        elsif total >= parsed.target_number
          translate('success')
        else
          translate('failure')
        end
      end

      def getValue(text, defaultValue)
        return defaultValue if text.nil? || text.empty?

        ArithmeticEvaluator.eval(text)
      end

      # 消耗表ロール
      def roll_consumption(command)
        m = /^CT\d*([+\-\d]+)?$/.match(command)
        return nil unless m

        modifier = ArithmeticEvaluator.eval(m[1])
        formated_modifier = Format.modifier(modifier)
        dice = @randomizer.roll_once(6)

        interim_expr = dice.to_s + formated_modifier unless formated_modifier.empty?

        sequence = [
          "(1D6#{formated_modifier})",
          interim_expr,
          dice + modifier,
        ].compact

        return sequence.join(" ＞ ")
      end

      ### 消耗表 ###
      def roll_consumption_table(command)
        m = /(P|E|G|C|ES|CS)CT(\d+)?([+\-\d]+)?(?:\$(\d+))?/.match(command)
        return nil unless m

        table = construct_consumption_table(m[1])
        cr = m[2].to_i
        modifier = ArithmeticEvaluator.eval(m[3])
        table.fix_dice_value(m[4].to_i) if m[4]

        return table.roll(cr, modifier, @randomizer)
      end

      def construct_consumption_table(type)
        table =
          case type
          when "P"
            translate("LogHorizon.CT.PCT")
          when "E"
            translate("LogHorizon.CT.ECT")
          when "G"
            translate("LogHorizon.CT.GCT")
          when "C"
            translate("LogHorizon.CT.CCT")
          when "ES"
            translate("LogHorizon.CT.ESCT")
          when "CS"
            translate("LogHorizon.CT.CSCT")
          end

        ConsumptionTable.new(table[:name], table[:items])
      end

      # 消耗表
      class ConsumptionTable
        # @param name [String]
        # @param tables [Array[Hash{Integer => String}]]
        def initialize(name, tables)
          @name = name
          @tables = tables

          @dice_value = nil
        end

        # ダイスの値を固定する
        # @param dice [Integer]
        # @return [void]
        def fix_dice_value(dice)
          @dice_value = dice
        end

        def roll(cr, modifier, randomizer)
          table_index = ((cr - 1) / 5).clamp(0, @tables.size - 1)
          items = @tables[table_index]

          @dice_value ||= randomizer.roll_once(6)
          total = @dice_value + modifier

          chosen = items[total.clamp(0, 7)]

          "#{@name}(#{total}[#{@dice_value}]) ＞ #{chosen}"
        end
      end

      # 財宝表ロール
      def roll_treasure(command)
        m = /^TRS(\d+)?([+\-\d]+)?$/.match(command)
        return nil unless m

        character_rank = m[1].to_i
        modifier = ArithmeticEvaluator.eval(m[2])

        dice_list = @randomizer.roll_barabara(2, 6)
        dice_total = dice_list.sum
        total = dice_total + character_rank * 5 + modifier

        return "(2D6+#{character_rank}*5#{Format.modifier(modifier)}) ＞ "\
               "#{dice_total}[#{dice_list.join(',')}]#{Format.modifier(character_rank * 5 + modifier)} ＞ "\
               "#{total}"
      end

      ### 財宝表 ###
      def roll_treasure_table(command)
        m = /^([CMIHG]TRS)(\d+)?([+\-\d]+)?(\$)?$/.match(command)
        return nil unless m

        type = m[1]
        table = construct_treasure_table(type)

        character_rank = m[2].to_i
        modifier = ArithmeticEvaluator.eval(m[3])
        return translate("LogHorizon.TRS.need_cr", command: command) if character_rank == 0 && modifier == 0

        table.fix_dice_value(7) if m[4]

        return table.roll(character_rank, modifier, @randomizer)
      end

      def construct_treasure_table(type)
        if type == "HTRS"
          HeroineTreasureTable.from_i18n("LogHorizon.TRS.HTRS", @locale)
        else
          TreasureTable.from_i18n("LogHorizon.TRS.#{type}", @locale)
        end
      end

      # 拡張ルール財宝表
      def roll_treasure_table_b2(command)
        m = /^([CMIO]TRSE)(\d+)?([+\-\d]+)?(\$)?$/.match(command)
        return nil unless m

        type = m[1]
        table = ExpansionTreasureTable.from_i18n("LogHorizon.TRSE.#{type}", @locale)

        character_rank = m[2].to_i
        modifier = ArithmeticEvaluator.eval(m[3])
        return translate("LogHorizon.TRS.need_cr", command: command) if character_rank == 0 && modifier == 0

        table.fix_dice_value(7) if m[4]

        return table.roll(character_rank, modifier, @randomizer)
      end

      # 財宝表
      class TreasureTable
        include Translate

        class << self
          def from_i18n(key, locale)
            table = I18n.translate(key, raise: true, locale: locale)
            new(table[:name], table[:items], locale)
          end
        end

        # @param name [String]
        # @param items [Hash{Integer => String}]
        def initialize(name, items, locale)
          @name = name
          @items = items
          @locale = locale

          @dice_list = nil
        end

        # プライズ取得用にダイスの値を固定する
        # @param dice [Integer]
        # @return [void]
        def fix_dice_value(dice)
          @dice_list = [dice]
        end

        # @param cr [Integer]
        # @param modifier [Integer]
        # @param randomizer [Randomizer]
        # @return [String, nil]
        def roll(cr, modifier, randomizer)
          return nil if cr == 0 && modifier == 0

          index =
            if cr == 0 && modifier != 0
              modifier # modifierの値のみ設定されている場合には、その値の項目をダイスロールせずに参照する
            else
              @dice_list ||= randomizer.roll_barabara(2, 6)
              @dice_list.sum() + 5 * cr + modifier
            end
          chosen = pick_item(index)

          dice_str = "[#{@dice_list&.join(',')}]" if @dice_list

          "#{@name}(#{index}#{dice_str}) ＞ #{chosen}"
        end

        private

        # @param index [Integer]
        # @return [String]
        def pick_item(index)
          if index <= 6
            translate("LogHorizon.TRS.below_lower_limit", value: 6) # 6以下の出目は未定義です
          elsif index <= 62
            @items[index]
          elsif index <= 72
            "#{@items[index - 10]}&80G"
          elsif index <= 82
            "#{@items[index - 20]}&160G"
          elsif index <= 87
            "#{@items[index - 30]}&260G"
          else
            translate("LogHorizon.TRS.exceed_upper_limit", value: 88) # 88以上の出目は未定義です
          end
        end
      end

      # ヒロイン財宝表
      class HeroineTreasureTable < TreasureTable
        # @param index [Integer]
        # @return [String]
        def pick_item(index)
          if index <= 6
            translate("LogHorizon.TRS.below_lower_limit", value: 6)
          elsif index <= 53
            @items[index]
          else
            translate("LogHorizon.TRS.exceed_upper_limit", value: 54)
          end
        end
      end

      # 拡張ルール財宝表
      class ExpansionTreasureTable < TreasureTable
        # @param index [Integer]
        # @return [String]
        def pick_item(index)
          if index <= 6
            translate("LogHorizon.TRS.below_lower_limit", value: 6)
          elsif index <= 162
            @items[index]
          elsif index <= 172
            "#{@items[index - 10]}&200G"
          elsif index <= 182
            "#{@items[index - 20]}&400G"
          elsif index <= 187
            "#{@items[index - 30]}&600G"
          else
            translate("LogHorizon.TRS.exceed_upper_limit", value: 188)
          end
        end
      end

      # ロデ研の新発明ランダム決定表
      def getInventionAttributeTextDiceCommandResult(command)
        return nil unless command =~ /IAT([ABMDLT]*)/

        tableName = translate("LogHorizon.IAT.name")

        table_indicate_string = Regexp.last_match(1) && Regexp.last_match(1) != '' ? Regexp.last_match(1) : 'MDLT'
        is_single = (table_indicate_string.length == 1)

        result = []
        number = []

        table_indicate_string.split(//).each do |char|
          dice_result = @randomizer.roll_once(6)
          number << dice_result.to_s
          table =   case char
                    when 'A', 'M'
                      translate("LogHorizon.IAT.A")
                    when 'B', 'D'
                      translate("LogHorizon.IAT.B")
                    when 'L'
                      translate("LogHorizon.IAT.L")
                    when 'T'
                      translate("LogHorizon.IAT.T")
                    end
          chosen = table[:items][dice_result - 1]
          if is_single
            chosen = "#{table[:name]}：#{chosen}"
          end

          result.push(chosen)
        end

        return "#{tableName}([#{number.join(',')}]) ＞ #{result.join(' ')}"
      end

      # アキバの街で遭遇するトラブルランダム決定表
      def getTroubleInAkibaStreetDiceCommandResult(command)
        return nil unless command == "TIAS"

        roll_random_table("LogHorizon.TIAS")
      end

      # 廃棄児ランダム決定表
      def getAbandonedChildDiceCommandResult(command)
        return nil unless command == "ABDC"

        roll_random_table("LogHorizon.ABDC")
      end

      def roll_random_table(key)
        table = translate(key)
        tables = table[:tables]

        dice_list = @randomizer.roll_barabara(tables.size, 6)
        result = dice_list.map.with_index { |n, index| tables[index][n - 1] }

        return "#{table[:name]}([#{dice_list.join(',')}]) ＞ #{result.join(' ')}"
      end

      # 楽器種別表
      def getMusicalInstrumentTypeDiceCommandResult(command)
        return nil unless command =~ /MII(\d?)/

        is_roll = !(Regexp.last_match(1) && Regexp.last_match(1) != '')
        type = is_roll ? @randomizer.roll_once(6) : Regexp.last_match(1).to_i

        return nil if type < 1 || 6 < type

        tableName = translate("LogHorizon.MII.name")
        type_name = translate("LogHorizon.MII.type_list")[type - 1]

        dice = @randomizer.roll_once(6)
        result = translate("LogHorizon.MII.items")[type - 1][dice - 1]

        return tableName.to_s + (is_roll ? "(#{type})" : '') + " ＞ #{type_name}(#{dice}) ＞ #{result}"
      end

      # イースタル探索表
      def roll_eastal_exploration_table(command)
        m = /ESTL(\d+)?([+\-\d]+)?(?:\$(\d+))?/.match(command)
        return nil unless m
        return nil if m[1].nil? && m[2].nil? && m[3].nil?

        character_rank = m[1].to_i
        modifier = ArithmeticEvaluator.eval(m[2])
        fixed_dice_value = m[3]&.to_i

        dice_list =
          if fixed_dice_value
            [fixed_dice_value]
          elsif character_rank == 0
            []
          else
            @randomizer.roll_barabara(2, 6)
          end

        dice_str = "[#{dice_list.join(',')}]" unless dice_list.empty?
        total = (dice_list.sum() + character_rank * 5 + modifier).clamp(7, 162)

        table_name = translate("LogHorizon.ESTL.name")
        table = translate("LogHorizon.ESTL.items")
        chosen = table[total].chomp

        return "#{table_name}(#{total}#{dice_str})\n#{chosen}"
      end

      class << self
        private

        def translate_tables(locale)
          {
            "PTAG" => DiceTable::D66Table.from_i18n("LogHorizon.table.PTAG", locale),
            "KOYU" => DiceTable::D66Table.from_i18n("LogHorizon.table.KOYU", locale),
            "MGR1" => DiceTable::D66Table.from_i18n("LogHorizon.table.MGR1", locale),
            "MGR2" => DiceTable::D66Table.from_i18n("LogHorizon.table.MGR2", locale),
            "MGR3" => DiceTable::D66Table.from_i18n("LogHorizon.table.MGR3", locale),
            "HLOC" => DiceTable::D66Table.from_i18n("LogHorizon.table.HLOC", locale),
            "PCNM" => DiceTable::D66Table.from_i18n("LogHorizon.table.PCNM", locale),
          }
        end
      end

      TABLES = translate_tables(:ja_jp)

      register_prefix(TABLES.keys)
    end
  end
end
