# frozen_string_literal: true

module BCDice
  module GameSystem
    class KillDeathBusiness < Base
      # ゲームシステムの識別子
      ID = 'KillDeathBusiness'

      # ゲームシステム名
      NAME = 'キルデスビジネス'

      # ゲームシステム名の読みがな
      SORT_KEY = 'きるてすひしねす'

      # ダイスボットの使い方
      HELP_MESSAGE = <<~INFO_MESSAGE_TEXT
        ・判定
        　JDx or JDx±y or JDx,z JDx#z or JDx±y,z JDx±y#z
        　（x＝難易度、y＝補正、z＝ファンブル率(リスク)）
        ・履歴表 (HST)
        ・願い事表 (-WT)
        　死(DWT)、復讐(RWT)、勝利(VWT)、獲得(PWT)、支配(CWT)、繁栄(FWT)
        　強化(IWT)、健康(HWT)、安全(SAWT)、長寿(LWT)、生(EWT)
        ・万能命名表 (NAME, NAMEx) xに数字(1,2,3)で表を個別ロール
        ・サブプロット表 (-SPT)
        　オカルト(OSPT)、家族(FSPT)、恋愛(LOSPT)、正義(JSPT)、修行(TSPT)
        　笑い(BSPT)、意地悪(MASPT)、恨み(UMSPT)、人気(POSPT)、仕切り(PASPT)
        　金儲け(MOSPT)、対悪魔(ANSPT)
        ・シーン表 (ST)、サービスシーン表 (EST)
        ・CM表 (CMT)
        ・蘇生副作用表 (ERT)
        ・一週間表（WKT)
        ・ソウル放出表 (SOUL)
        ・汎用演出表 (STGT)
        ・ヘルスタイリスト罵倒表 (HSAT、HSATx) xに数字(1,2)で表を個別ロール
        ・指定特技ランダム決定表 (SKLT, RTTn nは分野番号)、指定特技分野ランダム決定表 (RCT, SKLJ)
        ・エキストラ表 (EXT、EXTx) xに数字(1,2,3,4)で表を個別ロール
        ・製作委員決定表　PCDT/実際どうだったのか表　OHT
        ・タスク表　ヘルライオン　PCT1/ヘルクロウ　PCT2/ヘルスネーク　PCT3/
        　ヘルドラゴン　PCT4/ヘルフライ　PCT5/ヘルゴート　PCT6/ヘルベア　PCT7
        ・大喜利スペシャル表 (-OT)
        　お題決定表(TOT)、〇〇を見て一言表(OOT)
        　単語表(WOT, WOTx) xに英字(A,B,C)で単語表A(人物)(AOT)、単語表B(物)(BOT)、単語表C(場所)を個別ロール
        　動詞表(VOT)、長め単語表(LOT)
        　ヘル司会者 リアクション表(好印象ver)(POT)、ヘル司会者 リアクション表(不満ver)(NOT)
        ・D66ダイスあり
      INFO_MESSAGE_TEXT

      def initialize(command)
        super(command)

        @sort_add_dice = true
        @d66_sort_type = D66SortType::ASC
      end

      # ゲーム別成功度判定(2D6)
      def result_2d6(_total, dice_total, _dice_list, cmp_op, _target)
        return nil unless cmp_op == :>=

        if dice_total <= 2
          Result.fumble(translate("KillDeathBusiness.fumble"))
        elsif dice_total >= 12
          Result.critical(translate("KillDeathBusiness.special"))
        end
      end

      def eval_game_system_specific_command(command)
        debug("eval_game_system_specific_command command", command)

        if command.start_with?("JD")
          judgeDice(command)
        else
          rollTableCommand(command)
        end
      end

      private

      def judgeDice(command)
        fumble_match = /,(\d+)$/.match(command)

        parser = Command::Parser.new(/JD\d+/, round_type: round_type)
                                .enable_critical
                                .enable_fumble
                                .restrict_cmp_op_to(nil)
        cmd = parser.parse(fumble_match&.pre_match || command)
        unless cmd
          return nil
        end

        target = cmd.command.delete_prefix("JD").to_i
        modify = cmd.modify_number
        fumble = fumble_match ? fumble_match[1].to_i : cmd.fumble.to_i

        command = judge_expr(target, modify, fumble)

        result = ""

        if target > 12
          result += "【#{command}】 ＞ #{translate('KillDeathBusiness.JD.warning.over_target_number')}\n"
          target = 12
        end

        if target < 5
          result += "【#{command}】 ＞ #{translate('KillDeathBusiness.JD.warning.min_target_is_five')}\n"
          target = 5
        end

        if fumble < 2
          fumble = 2
        elsif fumble > 11
          result += "【#{command}】 ＞ #{translate('KillDeathBusiness.JD.warning.over_fumble')}\n"
          fumble = 11
        end

        dice_list = @randomizer.roll_barabara(2, 6)
        number = dice_list.sum()
        diceText = dice_list.join(",")

        result += [
          translate("KillDeathBusiness.JD.options", target: target, modifier: modify, fumble: fumble),
          " ＞ ",
          translate("KillDeathBusiness.JD.dice_value", dice_value: diceText),
          " ＞ ",
        ].join("")

        if number == 2
          result += translate("KillDeathBusiness.JD.fumble")
        elsif number == 12
          result += translate("KillDeathBusiness.JD.special")
        elsif number <= fumble
          result += translate("KillDeathBusiness.JD.less_than_fumble_target")
        else
          number += modify
          if number < target
            result += translate("KillDeathBusiness.JD.failure", value: number)
          else
            result += translate("KillDeathBusiness.JD.success", value: number)
          end
        end

        return translate("KillDeathBusiness.JD.name") + result
      end

      def judge_expr(target, modifier, fumble)
        modifier = Format.modifier(modifier)
        fumble = ",#{fumble}" if fumble > 0

        "JD#{target}#{modifier}#{fumble}"
      end

      def rollTableCommand(command)
        command = ALIAS[command] || command
        result = roll_tables(command, self.class::TABLES) || self.class::RTT.roll_command(@randomizer, command)
        return result if result

        tableName = ""
        result = ""

        case command
        when /^ST(\d)?$/
          # シーン表
          type = Regexp.last_match(1).to_i
          tableName, result, number = getSceneTableResult(type)
        when /^NAME(\d)?$/
          # 万能命名表
          type = Regexp.last_match(1).to_i
          tableName, result, number = getNameTableResult(type)
        when /^EST$/i, /^sErviceST$/i
          # サービスシーン表
          tableName, result, number = getServiceSceneTableResult()
        when /^HSAT(\d)?$/
          # ヘルスタイリスト罵倒表
          type = Regexp.last_match(1).to_i
          tableName, result, number = getHairStylistAbuseTableResult(type)
        when /^EXT(\d)?$/
          # エキストラ表
          type = Regexp.last_match(1).to_i
          tableName, result, number = getExtraTableResult(type)
        when /^TOT?$/
          # お題決定表
          tableName, result, number = getThemeTableResult()
        when /^OOT?$/
          # 一言決定表
          tableName, result, number = getOneWordTableResult()
        when /^WOT?$/
          # 単語決定表
          tableName, result, number = getWordTableResult()
        when /^POT?$/
          # ヘル司会者 リアクション表(好印象ver)
          tableName, result, number = getPositiveTableResult()
        when /^NOT?$/
          # ヘル司会者 リアクション表(不満ver)
          tableName, result, number = getNegativeTableResult()
        end

        if result.empty?
          return ""
        end

        text = "#{tableName}(#{number}) ＞ #{result}"
        return text
      end

      def getSceneTableResult(type)
        debug("getSceneTableResult type", type)

        tableName = translate("KillDeathBusiness.ST.name")

        sceneTable1 = translate("KillDeathBusiness.ST.table1")
        sceneTable2 = translate("KillDeathBusiness.ST.table2")

        result = ''
        number = 0

        case type
        when 1
          result, number = get_table_by_d66_swap(sceneTable1)
        when 2
          result, number = get_table_by_d66_swap(sceneTable2)
        else
          result1, num1 = get_table_by_d66_swap(sceneTable1)
          result2, num2 = get_table_by_d66_swap(sceneTable2)
          result = translate("KillDeathBusiness.ST.format", result1: result1, result2: result2)
          number = "#{num1},#{num2}"
        end

        return tableName, result, number
      end

      def getNameTableResult(type)
        tableName = translate("KillDeathBusiness.NAME.name")

        nameTable1 = translate("KillDeathBusiness.NAME.table1")
        nameTable2 = translate("KillDeathBusiness.NAME.table2")
        nameTable3 = translate("KillDeathBusiness.NAME.table3")

        result = ''
        number = 0

        case type
        when 1
          result, number = get_table_by_d66_swap(nameTable1)
        when 2
          result, number = get_table_by_d66_swap(nameTable2)
        when 3
          result, number = get_table_by_d66_swap(nameTable3)
        else
          result1, num1 = get_table_by_d66_swap(nameTable1)
          result2, num2 = get_table_by_d66_swap(nameTable2)
          result3, num3 = get_table_by_d66_swap(nameTable3)
          result = "#{result1}#{result2}#{result3}"
          number = "#{num1},#{num2},#{num3}"
        end

        return tableName, result, number
      end

      def getServiceSceneTableResult()
        table_name = translate("KillDeathBusiness.EST.name")
        tables = [
          translate("KillDeathBusiness.EST.tables.undressing"), # 脱衣系サービスシーン表
          translate("KillDeathBusiness.EST.tables.violence"), # 暴力系サービスシーン表
          translate("KillDeathBusiness.EST.tables.travel"), # 旅行系サービスシーン表
          translate("KillDeathBusiness.EST.tables.love"), # 恋愛系サービスシーン表
          translate("KillDeathBusiness.EST.tables.emotion"), # 感動系サービスシーン表
          translate("KillDeathBusiness.EST.tables.other_genre"), # 別ジャンルサービスシーン表
        ]

        number1 = @randomizer.roll_once(6)
        scene_table = tables[number1 - 1]

        number2 = @randomizer.roll_once(6)
        scene = scene_table[:items][number2 - 1]

        result = translate("KillDeathBusiness.EST.format", scene: scene_table[:name], chosen: scene)
        number = "#{number1}#{number2}"

        return table_name, result, number
      end

      def getHairStylistAbuseTableResult(type)
        tableName = translate("KillDeathBusiness.HSAT.name")

        hellStylistAbuseTable1 = translate("KillDeathBusiness.HSAT.abuse_table1")
        hellStylistAbuseTable2 = translate("KillDeathBusiness.HSAT.abuse_table2")
        hellStylistwtable1 = translate("KillDeathBusiness.HSAT.prefix_table")
        hellStylistwtable2 = translate("KillDeathBusiness.HSAT.suffix_table")

        case type
        when 1
          result, number = get_table_by_d66_swap(hellStylistAbuseTable1)
        when 2
          result, number = get_table_by_d66_swap(hellStylistAbuseTable2)
        else
          result1, num1 = get_table_by_d66_swap(hellStylistAbuseTable1)
          result2, num2 = get_table_by_d66_swap(hellStylistAbuseTable2)
          before, = get_table_by_1d6(hellStylistwtable1)
          after, = get_table_by_1d6(hellStylistwtable2)
          result = "#{before}#{result1} #{result2}#{after}"
          number = "#{num1},#{num2}"
        end

        return tableName, result, number
      end

      def getExtraTableResult(type)
        tableName = translate("KillDeathBusiness.EXT.name")
        extraTable1 = [
          [11, translate("KillDeathBusiness.EXT.table1.11")],
          [12, translate("KillDeathBusiness.EXT.table1.12")],
          [13, translate("KillDeathBusiness.EXT.table1.13")],
          [14, translate("KillDeathBusiness.EXT.table1.14")],
          [15, translate("KillDeathBusiness.EXT.table1.15")],
          [16, translate("KillDeathBusiness.EXT.table1.16")],
          [22, translate("KillDeathBusiness.EXT.table1.22")],
          [23, translate("KillDeathBusiness.EXT.table1.23")],
          [24, translate("KillDeathBusiness.EXT.table1.24")],
          [25, translate("KillDeathBusiness.EXT.table1.25")],
          [26, translate("KillDeathBusiness.EXT.table1.26")],
          [33, translate("KillDeathBusiness.EXT.table1.33")],
          [34, translate("KillDeathBusiness.EXT.table1.34")],
          [35, translate("KillDeathBusiness.EXT.table1.35")],
          [36, translate("KillDeathBusiness.EXT.table1.36")],
          [44, translate("KillDeathBusiness.EXT.table1.44")],
          [45, translate("KillDeathBusiness.EXT.table1.45")],
          [46, translate("KillDeathBusiness.EXT.table1.46")],
          [55, translate("KillDeathBusiness.EXT.table1.55")],
          [56, lambda { translate("KillDeathBusiness.EXT.table1.56", name: getNameTableResult(0)[1]) }],
          [66, translate("KillDeathBusiness.EXT.table1.66")],
        ]
        extraTable2 = translate("KillDeathBusiness.EXT.table2")
        extraTable3 = translate("KillDeathBusiness.EXT.table3")
        extraTable4 = translate("KillDeathBusiness.EXT.table4")

        case type
        when 1
          result, number = get_table_by_d66_swap(extraTable1)
        when 2
          result, number = get_table_by_d66_swap(extraTable2)
        when 3
          result, number = get_table_by_d66_swap(extraTable3)
        when 4
          result, number = get_table_by_d66_swap(extraTable4)
        else
          result1, num1 = get_table_by_d66_swap(extraTable1)
          result2, num2 = get_table_by_d66_swap(extraTable2)
          result3, num3 = get_table_by_d66_swap(extraTable3)
          result4, num4 = get_table_by_d66_swap(extraTable4)
          result = "#{result1}#{result2}が#{result3}#{result4}"
          number = "#{num1},#{num2},#{num3},#{num4}"
        end

        return tableName, result, number
      end

      def getThemeTableResult()
        tableName = translate("KillDeathBusiness.table.TOT.name")

        result = ''
        d6 = @randomizer.roll_once(6)

        case d6
        when 1
          oneTableName, oneResult, oneD6, one = getOneWordTableResult()
          result += "[#{oneTableName}]を見て一言。\n#{oneTableName}(#{oneD6}) ＞ #{oneResult}\n＞ "
          result += translate("KillDeathBusiness.table.TOT.items.1", one: one)
        when 2
          word1TableName, word1Result, word1D6, word1 = getWordTableResult()
          word2TableName, word2Result, word2D6, word2 = getWordTableResult()
          result += "この[#{word1TableName}]、ひょっとして[#{word1TableName}]かも、どうしてそう思った？\n#{word1TableName}(#{word1D6}) ＞ #{word1Result}\n#{word2TableName}(#{word2D6}) ＞ #{word2Result}\n＞ "
          result += translate("KillDeathBusiness.table.TOT.items.2", word1: word1, word2: word2)
        when 3
          vot = self.class::TABLES["VOT"].roll(@randomizer)
          verbTableName = vot.table_name
          verb = vot.body
          number = vot.value
          wordTableName, wordResult, wordD6, word = getWordTableResult()
          result += "[#{verbTableName}]した[#{wordTableName}]が言いそうなこと。\n#{verbTableName}(#{number}) ＞ #{verb}\n#{wordTableName}(#{wordD6}) ＞ #{wordResult}\n＞ "
          result += translate("KillDeathBusiness.table.TOT.items.3", verb: verb, word: word)
        when 4
          word1TableName, word1Result, word1D6, word1 = getWordTableResult()
          word2TableName, word2Result, word2D6, word2 = getWordTableResult()
          result += "[#{word1TableName}]が[#{word1TableName}]になった世界ではどんなことが起こる？\n#{word1TableName}(#{word1D6}) ＞ #{word1Result}\n#{word2TableName}(#{word2D6}) ＞ #{word2Result}\n＞ "
          result += translate("KillDeathBusiness.table.TOT.items.4", word1: word1, word2: word2)
        when 5
          wordTableName, wordResult, wordD6, word = getWordTableResult()
          result += "こんな[#{wordTableName}]は嫌だ。どんなの？\n#{wordTableName}(#{wordD6}) ＞ #{wordResult}\n＞ "
          result += translate("KillDeathBusiness.table.TOT.items.5", word: word)
        when 6
          lot = self.class::TABLES["LOT"].roll(@randomizer)
          longTableName = lot.table_name
          long = lot.body
          number = lot.value
          result += "[#{longTableName}]みたいなことを言って下さい。\n#{longTableName}(#{number}) ＞ #{long}\n＞ "
          result += translate("KillDeathBusiness.table.TOT.items.6", long: long)
        end

        return tableName, result, d6
      end

      def getOneWordTableResult()
        tableName = translate("KillDeathBusiness.table.OOT.name")

        result = ''
        d6 = @randomizer.roll_once(6)

        case d6
        when 1, 2
          oneWord = translate("KillDeathBusiness.table.OOT.items.1")
          result = oneWord
        when 3, 4
          oneWord = translate("KillDeathBusiness.table.OOT.items.3")
          result = oneWord
        when 5, 6
          wordTableName, wordResult, wordD6, word = getWordTableResult()
          result += "[#{wordTableName}]で検索して出てくる６番目の画像\n#{wordTableName}(#{wordD6}) ＞ #{wordResult}\n＞ "
          oneWord = translate("KillDeathBusiness.table.OOT.items.5", word: word)
          result += oneWord
        end

        return tableName, result, d6, oneWord
      end

      def getWordTableResult()
        tableName = "単語表"

        d6 = @randomizer.roll_once(6)
        table =
          case d6
          when 1, 2
            self.class::TABLES["WOTA"]
          when 3, 4
            self.class::TABLES["WOTB"]
          when 5, 6
            self.class::TABLES["WOTC"]
          end

        result = table.roll(@randomizer)

        return tableName, result.to_s, d6, result.body
      end

      def getPositiveTableResult()
        tableName = translate("KillDeathBusiness.table.POT.name")

        table = [
          lambda { return translate("KillDeathBusiness.table.POT.items.1", size: @randomizer.roll_sum(1, 6).to_s) },
          lambda { return translate("KillDeathBusiness.table.POT.items.2", size: @randomizer.roll_sum(1, 6).to_s) },
          lambda { return translate("KillDeathBusiness.table.POT.items.3", size: @randomizer.roll_sum(2, 6).to_s) },
          lambda { return translate("KillDeathBusiness.table.POT.items.4", size: @randomizer.roll_sum(2, 6).to_s) },
          translate("KillDeathBusiness.table.POT.items.5"),
          lambda { return translate("KillDeathBusiness.table.POT.items.6", size: (@randomizer.roll_sum(1, 6) - 3).to_s) },
        ]

        result, number = get_table_by_1d6(table)

        return tableName, result, number
      end

      def getNegativeTableResult()
        tableName = translate("KillDeathBusiness.table.NOT.name")

        table = [
          translate("KillDeathBusiness.table.NOT.items.1"),
          translate("KillDeathBusiness.table.NOT.items.2"),
          lambda { return translate("KillDeathBusiness.table.NOT.items.3", size: @randomizer.roll_sum(1, 6).to_s) },
          lambda { return translate("KillDeathBusiness.table.NOT.items.4", size: @randomizer.roll_sum(1, 6).to_s) },
          lambda { return translate("KillDeathBusiness.table.NOT.items.5", size: @randomizer.roll_sum(1, 6).to_s) },
          translate("KillDeathBusiness.table.NOT.items.6"),
        ]

        result, number = get_table_by_1d6(table)

        return tableName, result, number
      end

      ALIAS = {
        "DeathWT" => "DWT",
        "RevengeWT" => "RWT",
        "VictoryWT" => "VWT",
        "PossesionWT" => "PWT",
        "ControlWT" => "CWT",
        "FlourishWT" => "FWT",
        "IntensifyWT" => "IWT",
        "HealthWT" => "HWT",
        "SafetyWT" => "SAWT",
        "LongevityWT" => "LWT",
        "ExistWT" => "EWT",
        "OccultSPT" => "OSPT",
        "FamilySPT" => "FSPT",
        "LoveSPT" => "LOSPT",
        "JusticeSPT" => "JSPT",
        "TrainingSPT" => "TSPT",
        "BeamSPT" => "BSPT",
      }.transform_keys(&:upcase).freeze

      class << self
        private

        def translate_tables(locale)
          {
            "HST" => DiceTable::Table.from_i18n("KillDeathBusiness.table.HST", locale),
            "DWT" => DiceTable::Table.from_i18n("KillDeathBusiness.table.DWT", locale),
            "RWT" => DiceTable::Table.from_i18n("KillDeathBusiness.table.RWT", locale),
            "VWT" => DiceTable::Table.from_i18n("KillDeathBusiness.table.VWT", locale),
            "PWT" => DiceTable::Table.from_i18n("KillDeathBusiness.table.PWT", locale),
            "CWT" => DiceTable::Table.from_i18n("KillDeathBusiness.table.CWT", locale),
            "FWT" => DiceTable::Table.from_i18n("KillDeathBusiness.table.FWT", locale),
            "IWT" => DiceTable::Table.from_i18n("KillDeathBusiness.table.IWT", locale),
            "HWT" => DiceTable::Table.from_i18n("KillDeathBusiness.table.HWT", locale),
            "SAWT" => DiceTable::Table.from_i18n("KillDeathBusiness.table.SAWT", locale),
            "LWT" => DiceTable::Table.from_i18n("KillDeathBusiness.table.LWT", locale),
            "EWT" => DiceTable::Table.from_i18n("KillDeathBusiness.table.EWT", locale),
            "OSPT" => DiceTable::Table.from_i18n("KillDeathBusiness.table.OSPT", locale),
            "FSPT" => DiceTable::Table.from_i18n("KillDeathBusiness.table.FSPT", locale),
            "LOSPT" => DiceTable::Table.from_i18n("KillDeathBusiness.table.LOSPT", locale),
            "JSPT" => DiceTable::Table.from_i18n("KillDeathBusiness.table.JSPT", locale),
            "TSPT" => DiceTable::Table.from_i18n("KillDeathBusiness.table.TSPT", locale),
            "BSPT" => DiceTable::Table.from_i18n("KillDeathBusiness.table.BSPT", locale),
            "CMT" => DiceTable::D66Table.from_i18n("KillDeathBusiness.table.CMT", locale),
            "ERT" => DiceTable::D66Table.from_i18n("KillDeathBusiness.table.ERT", locale),
            "WKT" => DiceTable::D66Table.from_i18n("KillDeathBusiness.table.WKT", locale),
            "SOUL" => DiceTable::Table.from_i18n("KillDeathBusiness.table.SOUL", locale),
            "STGT" => DiceTable::Table.from_i18n("KillDeathBusiness.table.STGT", locale),
            "PCDT" => DiceTable::D66Table.from_i18n("KillDeathBusiness.table.PCDT", locale),
            "OHT" => DiceTable::Table.from_i18n("KillDeathBusiness.table.OHT", locale),
            "PCT1" => DiceTable::Table.from_i18n("KillDeathBusiness.table.PCT1", locale),
            "PCT2" => DiceTable::Table.from_i18n("KillDeathBusiness.table.PCT2", locale),
            "PCT3" => DiceTable::Table.from_i18n("KillDeathBusiness.table.PCT3", locale),
            "PCT4" => DiceTable::Table.from_i18n("KillDeathBusiness.table.PCT4", locale),
            "PCT5" => DiceTable::Table.from_i18n("KillDeathBusiness.table.PCT5", locale),
            "PCT6" => DiceTable::Table.from_i18n("KillDeathBusiness.table.PCT6", locale),
            "PCT7" => DiceTable::Table.from_i18n("KillDeathBusiness.table.PCT7", locale),
            "ANSPT" => DiceTable::Table.from_i18n("KillDeathBusiness.table.ANSPT", locale),
            "MASPT" => DiceTable::Table.from_i18n("KillDeathBusiness.table.MASPT", locale),
            "MOSPT" => DiceTable::Table.from_i18n("KillDeathBusiness.table.MOSPT", locale),
            "PASPT" => DiceTable::Table.from_i18n("KillDeathBusiness.table.PASPT", locale),
            "POSPT" => DiceTable::Table.from_i18n("KillDeathBusiness.table.POSPT", locale),
            "UMSPT" => DiceTable::Table.from_i18n("KillDeathBusiness.table.UMSPT", locale),
            "WOTA" => DiceTable::D66Table.from_i18n("KillDeathBusiness.table.WOTA", locale),
            "WOTB" => DiceTable::D66Table.from_i18n("KillDeathBusiness.table.WOTB", locale),
            "WOTC" => DiceTable::D66Table.from_i18n("KillDeathBusiness.table.WOTC", locale),
            "VOT" => DiceTable::D66Table.from_i18n("KillDeathBusiness.table.VOT", locale),
            "LOT" => DiceTable::D66Table.from_i18n("KillDeathBusiness.table.LOT", locale),
          }
        end

        def translate_rtt(locale)
          DiceTable::SaiFicSkillTable.from_i18n("KillDeathBusiness.RTT", locale, rtt: "SKLT", rct: "SKLJ")
        end
      end

      TABLES = translate_tables(:ja_jp)
      RTT = translate_rtt(:ja_jp)

      register_prefix(
        'ST[1-2]?',
        'NAME[1-3]?',
        'EST', 'sErviceST',
        'HSAT[1-2]?',
        'EXT[1-4]?',
        'JD',
        'TOT',
        'OOT',
        'WOT',
        'POT',
        'NOT'
      )
      register_prefix(TABLES.keys, register_prefix(ALIAS.keys), RTT.prefixes)
    end
  end
end
