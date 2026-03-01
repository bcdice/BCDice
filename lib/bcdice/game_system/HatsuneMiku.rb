# frozen_string_literal: true

module BCDice
  module GameSystem
    class HatsuneMiku < Base
      # ゲームシステムの識別子
      ID = 'HatsuneMiku'

      # ゲームシステム名
      NAME = '初音ミクTRPG ココロダンジョン'

      # ゲームシステム名の読みがな
      SORT_KEY = 'はつねみくTRPGこころたんしよん'

      # ダイスボットの使い方
      HELP_MESSAGE = <<~INFO_MESSAGE_TEXT
        ・判定(Rx±y@z>=t)
        　能力値のダイスごとに成功・失敗の判定を行います。
        　x：能力ランク(S,A～D)。数字指定で直接その個数のダイスが振れます
        　y：修正値。A+2 あるいは A++ のように表記。混在時は A++,+1 のように記述も可能
        　z：スペシャル最低値（省略：6）　t：目標値（省略：4）
        　　例） RA　R2　RB+1　RC++　RD+,+2　RA>=5　RS-1@5>=6
        　結果はネイロを取得した残りで最大値を表示
        例） RB
        　HatsuneMiku : (RB>=4) ＞ [3,5] ＞
        　　ネイロに3(青)を取得した場合 5:成功
        　　ネイロに5(白)を取得した場合 3:失敗
        ・各種表
        　ファンブル表 FT／致命傷表 CWT／休憩表 BT／目標表 TT／関係表 RT
        　障害表 OT／リクエスト表 RQT／クロウル表 CLT／報酬表 RWT／悪夢表 NMT／情景表 ST
        ・キーワード表
        　ダーク DKT／ホット HKT／ラブ LKT／エキセントリック EKT／メランコリー MKT
        ・名前表 NT
        　コア別　ダーク DNT／ホット HNT／ラブ LNT／エキセントリック ENT／メランコリー MNT
        ・オトダマ各種表
        　性格表A OPA／性格表B OPB／趣味表 OHT／外見表 OLT／一人称表 OIT／呼び名表 OYT
        　リアクション表 ORT／出会い表 OMT
      INFO_MESSAGE_TEXT

      def initialize(command)
        super(command)

        @d66_sort_type = D66SortType::ASC
      end

      def eval_game_system_specific_command(command)
        text = judgeRoll(command)
        return text unless text.nil?

        return roll_tables(command, self.class::TABLES)
      end

      def judgeRoll(command)
        return nil unless /^(R([A-DS]|\d+)([+\-\d,]*))(@(\d))?((>(=)?)([+\-\d]*))?(@(\d))?$/i =~ command

        skillRank = Regexp.last_match(2)
        modifyText = Regexp.last_match(3)
        signOfInequality = (Regexp.last_match(7).nil? ? ">=" : Regexp.last_match(7))
        targetText = (Regexp.last_match(9).nil? ? "4" : Regexp.last_match(9))

        specialNum = Regexp.last_match(5)
        specialNum ||= Regexp.last_match(11)
        specialNum ||= 6
        specialNum = specialNum.to_i
        specialText = (specialNum == 6 ? "" : "@#{specialNum}")

        modifyText = getChangedModifyText(modifyText)

        commandText = "R#{skillRank}#{modifyText}"

        rankDiceList = {"S" => 4, "A" => 3, "B" => 2, "C" => 1, "D" => 2}
        diceCount = rankDiceList[skillRank]
        diceCount = skillRank.to_i if skillRank =~ /^\d+$/

        modify = ArithmeticEvaluator.eval(modifyText)
        target = ArithmeticEvaluator.eval(targetText)

        diceList = @randomizer.roll_barabara(diceCount, 6).sort
        diceText = diceList.join(",")

        diceList = [diceList.min] if skillRank == "D"

        message = "(#{commandText}#{specialText}#{signOfInequality}#{targetText}) ＞ [#{diceText}]#{modifyText} ＞ "

        if diceList.length <= 1
          dice = diceList.first
          total = dice + modify
          result = check_success(total, dice, signOfInequality, target, specialNum)
          message += "#{total}:#{result}"
        else
          texts = []
          diceList.each_with_index do |pickup_dice, index|
            rests = diceList.clone
            rests.delete_at(index)
            dice = rests.max
            total = dice + modify
            result = check_success(total, dice, signOfInequality, target, specialNum)

            colorList = [
              translate('HatsuneMiku.color_black'),
              translate('HatsuneMiku.color_red'),
              translate('HatsuneMiku.color_blue'),
              translate('HatsuneMiku.color_green'),
              translate('HatsuneMiku.color_white'),
              translate('HatsuneMiku.color_any'),
            ]
            color = colorList[pickup_dice - 1]
            texts << translate('HatsuneMiku.neiro_acquire', pickup_dice: pickup_dice, color: color, total: total, result: result)
          end
          texts.uniq!
          message += "\n" + texts.join("\n")
        end

        return message
      end

      def getChangedModifyText(text)
        modifyText = ""
        values = text.split(/,/)

        values.each do |value|
          case value
          when "++"
            modifyText += "+2"
          when "+"
            modifyText += "+1"
          else
            modifyText += value
          end
        end

        return modifyText
      end

      def check_success(total_n, dice_n, signOfInequality, diff, special_n)
        return translate('fumble') if dice_n == 1
        return translate('HatsuneMiku.special') if dice_n >= special_n

        cmp_op = Normalize.comparison_operator(signOfInequality)
        target_num = diff.to_i

        if total_n.send(cmp_op, target_num)
          translate('success')
        else
          translate('failure')
        end
      end

      class << self
        private

        def translate_tables(locale)
          {
            'FT' => DiceTable::Table.from_i18n('HatsuneMiku.FT', locale),
            'CWT' => DiceTable::Table.from_i18n('HatsuneMiku.CWT', locale),
            'BT' => DiceTable::Table.from_i18n('HatsuneMiku.BT', locale),
            'TT' => DiceTable::Table.from_i18n('HatsuneMiku.TT', locale),
            'RT' => DiceTable::Table.from_i18n('HatsuneMiku.RT', locale),
            'OT' => DiceTable::Table.from_i18n('HatsuneMiku.OT', locale),
            'RQT' => DiceTable::Table.from_i18n('HatsuneMiku.RQT', locale),
            'CLT' => DiceTable::Table.from_i18n('HatsuneMiku.CLT', locale),
            'RWT' => DiceTable::Table.from_i18n('HatsuneMiku.RWT', locale),
            'NMT' => DiceTable::Table.from_i18n('HatsuneMiku.NMT', locale),
            'ST' => DiceTable::D66Table.new(
              I18n.t('HatsuneMiku.ST.name', locale: locale),
              D66SortType::ASC,
              (11..66).select { |i| i % 10 <= 6 && i % 10 >= 1 }.each_with_object({}) do |k, h|
                h[k] = I18n.t("HatsuneMiku.ST.#{k}", locale: locale)
              end
            ),
            'DKT' => DiceTable::D66Table.new(
              I18n.t('HatsuneMiku.DKT.name', locale: locale),
              D66SortType::ASC,
              (11..66).select { |i| i % 10 <= 6 && i % 10 >= 1 }.each_with_object({}) do |k, h|
                h[k] = I18n.t("HatsuneMiku.DKT.#{k}", locale: locale)
              end
            ),
            'DNT' => DiceTable::D66Table.new(
              I18n.t('HatsuneMiku.DNT.name', locale: locale),
              D66SortType::ASC,
              (11..66).select { |i| i % 10 <= 6 && i % 10 >= 1 }.each_with_object({}) do |k, h|
                h[k] = I18n.t("HatsuneMiku.DNT.#{k}", locale: locale)
              end
            ),
            'HKT' => DiceTable::D66Table.new(
              I18n.t('HatsuneMiku.HKT.name', locale: locale),
              D66SortType::ASC,
              (11..66).select { |i| i % 10 <= 6 && i % 10 >= 1 }.each_with_object({}) do |k, h|
                h[k] = I18n.t("HatsuneMiku.HKT.#{k}", locale: locale)
              end
            ),
            'HNT' => DiceTable::D66Table.new(
              I18n.t('HatsuneMiku.HNT.name', locale: locale),
              D66SortType::ASC,
              (11..66).select { |i| i % 10 <= 6 && i % 10 >= 1 }.each_with_object({}) do |k, h|
                h[k] = I18n.t("HatsuneMiku.HNT.#{k}", locale: locale)
              end
            ),
            'LKT' => DiceTable::D66Table.new(
              I18n.t('HatsuneMiku.LKT.name', locale: locale),
              D66SortType::ASC,
              (11..66).select { |i| i % 10 <= 6 && i % 10 >= 1 }.each_with_object({}) do |k, h|
                h[k] = I18n.t("HatsuneMiku.LKT.#{k}", locale: locale)
              end
            ),
            'LNT' => DiceTable::D66Table.new(
              I18n.t('HatsuneMiku.LNT.name', locale: locale),
              D66SortType::ASC,
              (11..66).select { |i| i % 10 <= 6 && i % 10 >= 1 }.each_with_object({}) do |k, h|
                h[k] = I18n.t("HatsuneMiku.LNT.#{k}", locale: locale)
              end
            ),
            'EKT' => DiceTable::D66Table.new(
              I18n.t('HatsuneMiku.EKT.name', locale: locale),
              D66SortType::ASC,
              (11..66).select { |i| i % 10 <= 6 && i % 10 >= 1 }.each_with_object({}) do |k, h|
                h[k] = I18n.t("HatsuneMiku.EKT.#{k}", locale: locale)
              end
            ),
            'ENT' => DiceTable::D66Table.new(
              I18n.t('HatsuneMiku.ENT.name', locale: locale),
              D66SortType::ASC,
              (11..66).select { |i| i % 10 <= 6 && i % 10 >= 1 }.each_with_object({}) do |k, h|
                h[k] = I18n.t("HatsuneMiku.ENT.#{k}", locale: locale)
              end
            ),
            'MKT' => DiceTable::D66Table.new(
              I18n.t('HatsuneMiku.MKT.name', locale: locale),
              D66SortType::ASC,
              (11..66).select { |i| i % 10 <= 6 && i % 10 >= 1 }.each_with_object({}) do |k, h|
                h[k] = I18n.t("HatsuneMiku.MKT.#{k}", locale: locale)
              end
            ),
            'MNT' => DiceTable::D66Table.new(
              I18n.t('HatsuneMiku.MNT.name', locale: locale),
              D66SortType::ASC,
              (11..66).select { |i| i % 10 <= 6 && i % 10 >= 1 }.each_with_object({}) do |k, h|
                h[k] = I18n.t("HatsuneMiku.MNT.#{k}", locale: locale)
              end
            ),
            'OPA' => DiceTable::D66Table.new(
              I18n.t('HatsuneMiku.OPA.name', locale: locale),
              D66SortType::ASC,
              (11..66).select { |i| i % 10 <= 6 && i % 10 >= 1 }.each_with_object({}) do |k, h|
                h[k] = I18n.t("HatsuneMiku.OPA.#{k}", locale: locale)
              end
            ),
            'OPB' => DiceTable::D66Table.new(
              I18n.t('HatsuneMiku.OPB.name', locale: locale),
              D66SortType::ASC,
              (11..66).select { |i| i % 10 <= 6 && i % 10 >= 1 }.each_with_object({}) do |k, h|
                h[k] = I18n.t("HatsuneMiku.OPB.#{k}", locale: locale)
              end
            ),
            'OHT' => DiceTable::D66Table.new(
              I18n.t('HatsuneMiku.OHT.name', locale: locale),
              D66SortType::ASC,
              (11..66).select { |i| i % 10 <= 6 && i % 10 >= 1 }.each_with_object({}) do |k, h|
                h[k] = I18n.t("HatsuneMiku.OHT.#{k}", locale: locale)
              end
            ),
            'OLT' => DiceTable::D66Table.new(
              I18n.t('HatsuneMiku.OLT.name', locale: locale),
              D66SortType::ASC,
              (11..66).select { |i| i % 10 <= 6 && i % 10 >= 1 }.each_with_object({}) do |k, h|
                h[k] = I18n.t("HatsuneMiku.OLT.#{k}", locale: locale)
              end
            ),
            'OIT' => DiceTable::Table.from_i18n('HatsuneMiku.OIT', locale),
            'OYT' => DiceTable::Table.from_i18n('HatsuneMiku.OYT', locale),
            'ORT' => DiceTable::Table.from_i18n('HatsuneMiku.ORT', locale),
            'OMT' => DiceTable::Table.from_i18n('HatsuneMiku.OMT', locale),
          }
        end
      end

      TABLES = translate_tables(:ja_jp).freeze

      register_prefix('R[A-DS]?', TABLES.keys)
    end
  end
end
