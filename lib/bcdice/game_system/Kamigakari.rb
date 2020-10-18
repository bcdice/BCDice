# frozen_string_literal: true

module BCDice
  module GameSystem
    class Kamigakari < Base
      # ゲームシステムの識別子
      ID = 'Kamigakari'

      # ゲームシステム名
      NAME = '神我狩'

      # ゲームシステム名の読みがな
      SORT_KEY = 'かみかかり'

      # ダイスボットの使い方
      HELP_MESSAGE = <<~INFO_MESSAGE_TEXT
        ・各種表
         ・感情表(ET)
         ・霊紋消費の代償表(RT)
         ・伝奇名字・名前決定表(NT)
         ・魔境臨界表(KT)
         ・獲得素材チャート(MTx xは［法則障害］の［強度］。省略時は１)
        　　例） MT　MT3　MT9
        ・D66ダイスあり
      INFO_MESSAGE_TEXT

      def initialize(command)
        super(command)

        @sort_add_dice = true
        @enabled_d66 = true
        @d66_sort_type = D66SortType::NO_SORT
      end

      def eval_game_system_specific_command(command)
        tableName = ""
        result = ""

        debug("eval_game_system_specific_command command", command)

        case command.upcase
        when /^MT(\d*)$/
          rank = Regexp.last_match(1)
          rank ||= 1
          rank = rank.to_i
          tableName, result, number = getGetMaterialTableResult(rank)
        else
          return roll_tables(command, self.class::TABLES)
        end

        if result.empty?
          return ""
        end

        text = "#{tableName}(#{number}) ＞ #{result}"
        return text
      end

      def getGetMaterialTableResult(rank)
        tableName = translate("Kamigakari.MT.name")
        table = translate("Kamigakari.MT.items")

        result, number = get_table_by_d66(table)

        effect, number2 = getMaterialEffect(rank)
        number = "#{number},#{number2}"

        price = getPrice(effect)

        result = translate("Kamigakari.MT.result_format", material: result, effect: effect)
        result += "：#{price}" unless price.nil?

        return tableName, result, number
      end

      def getMaterialEffect(rank)
        number = @randomizer.roll_once(6)

        result = ""
        type = ""
        if number < 6
          result, number2 = getMaterialEffectNomal(rank)
          type = translate("Kamigakari.MT.common_material.name")
        else
          result, number2 = getMaterialEffectRare()
          type = translate("Kamigakari.MT.rare_material.name")
        end

        result = "#{type}：#{result}"
        number = "#{number},#{number2}"

        return result, number
      end

      def getMaterialEffectNomal(rank)
        table = translate("Kamigakari.MT.common_material.items")

        number = @randomizer.roll_d66(D66SortType::NO_SORT)

        result = get_table_by_number(number, table)
        debug("getMaterialEffectNomal result", result)

        if result =~ /\+n/
          power, number2 = getMaterialEffectPower(rank)

          result = result.sub(/\+n/, "+#{power}")
          number = "#{number},#{number2}"
        end

        return result, number
      end

      def getMaterialEffectPower(rank)
        table = [
          [4, [1, 1, 1, 2, 2, 3]],
          [8, [1, 1, 2, 2, 3, 3]],
          [9, [1, 2, 3, 3, 4, 5]],
        ]

        rank = 9 if rank > 9
        rankTable = get_table_by_number(rank, table)
        power, number = get_table_by_1d6(rankTable)

        return power, number
      end

      def getMaterialEffectRare()
        table = [
          [3, "**" + translate("Kamigakari.MT.rare_material.give_attribute")], # 付与
          [5, "**" + translate("Kamigakari.MT.rare_material.halve_damage")], # 半減
          [6, translate("Kamigakari.MT.rare_material.optional_by_GM")],
        ]

        number = @randomizer.roll_once(6)
        result = get_table_by_number(number, table)
        debug('getMaterialEffectRare result', result)

        if result.include?("**")
          attribute, number2 = getAttribute()
          result = result.sub("**", attribute.to_s)
          number = "#{number},#{number2}"
        end

        return result, number
      end

      def getAttribute()
        table = translate("Kamigakari.MT.attribute")

        number = @randomizer.roll_d66(D66SortType::NO_SORT)

        result = get_table_by_number(number, table)

        return result, number
      end

      def getPrice(effect)
        power =
          if (m = effect.match(/\+(\d+)/))
            m[1].to_i
          elsif effect.include?(translate("Kamigakari.MT.rare_material.give_attribute")) # 付与
            3
          elsif effect.include?(translate("Kamigakari.MT.rare_material.halve_damage")) # 半減
            4
          else
            0
          end

        table = [
          nil,
          "500G(#{translate('Kamigakari.MT.effect_power')}:1)",
          "1000G(#{translate('Kamigakari.MT.effect_power')}:2)",
          "1500G(#{translate('Kamigakari.MT.effect_power')}:3)",
          "2000G(#{translate('Kamigakari.MT.effect_power')}:4)",
          "3000G(#{translate('Kamigakari.MT.effect_power')}:5)",
        ]
        price = table[power]

        return price
      end

      class << self
        private

        def translate_tables(locale)
          {
            "RT" => DiceTable::Table.from_i18n("Kamigakari.table.RT", locale),
            "ET" => DiceTable::D66Table.from_i18n("Kamigakari.table.ET", locale),
            "KT" => DiceTable::D66Table.from_i18n("Kamigakari.table.KT", locale),
            "NT" => DiceTable::D66Table.from_i18n("Kamigakari.table.NT", locale),
          }
        end
      end

      TABLES = translate_tables(:ja_jp)

      register_prefix('MT(\d*)', TABLES.keys)
    end
  end
end
