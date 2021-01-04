# frozen_string_literal: true

module BCDice
  module GameSystem
    class DetatokoSaga < Base
      # ゲームシステムの識別子
      ID = 'DetatokoSaga'

      # ゲームシステム名
      NAME = 'でたとこサーガ'

      # ゲームシステム名の読みがな
      SORT_KEY = 'てたとこさあか'

      # ダイスボットの使い方
      HELP_MESSAGE = <<~INFO_MESSAGE_TEXT
        ・通常判定　xDS or xDSy or xDS>=z or xDSy>=z
        　(x＝スキルランク、y＝現在フラグ値(省略時0)、z＝目標値(省略時８))
        　例）3DS　2DS5　0DS　3DS>=10　3DS7>=12
        ・判定値　xJD or xJDy or xJDy+z or xJDy-z or xJDy/z
        　(x＝スキルランク、y＝現在フラグ値(省略時0)、z＝修正値(省略時０))
        　例）3JD　2JD5　3JD7+1　4JD/3
        ・体力烙印表　SST (StrengthStigmaTable)
        ・気力烙印表　WST (WillStigmaTable)
        ・体力バッドエンド表　SBET (StrengthBadEndTable)
        ・気力バッドエンド表　WBET (WillBadEndTable)
      INFO_MESSAGE_TEXT

      register_prefix('\d+DS', '\d+JD')

      def initialize(command)
        super(command)

        @sort_add_dice = true
        @d66_sort_type = D66SortType::ASC
      end

      def eval_game_system_specific_command(command)
        debug("eval_game_system_specific_command begin string", command)

        result = checkRoll(command)
        return result if result

        result = checkJudgeValue(command)
        return result if result

        debug("各種表として処理")
        return roll_tables(ALIAS[command] || command, self.class::TABLES)
      end

      # 通常判定　xDS or xDSy or xDS>=z or xDSy>=z
      def checkRoll(string)
        debug("checkRoll begin string", string)

        m = /^(\d+)DS(\d+)?(?:>=(\d+))?$/i.match(string)
        unless m
          return nil
        end

        skill = m[1].to_i
        flag = m[2].to_i
        target = m[3]&.to_i || 8

        result = translate("DetatokoSaga.DS.input_options", skill: skill, flag: flag, target: target)

        total, rollText = getRollResult(skill)
        result += " ＞ #{total}[#{rollText}] ＞ " + translate("DetatokoSaga.total_value", total: total)

        success = getSuccess(total, target)
        result += " ＞ #{success}"

        result += getCheckFlagResult(total, flag)

        return result
      end

      def getRollResult(skill)
        diceCount = skill + 1
        diceCount = 3 if  skill == 0

        dice = @randomizer.roll_barabara(diceCount, 6)
        diceText = dice.join(',')

        dice = dice.sort
        dice = dice.reverse if skill != 0

        total = dice[0] + dice[1]

        return total, diceText
      end

      def getSuccess(check, target)
        if check >= target
          translate("DetatokoSaga.DS.success")
        else
          translate("DetatokoSaga.DS.failure")
        end
      end

      def getCheckFlagResult(total, flag)
        if total > flag
          return ""
        end

        will = getDownWill(flag)
        return translate("DetatokoSaga.less_than_flag", will: will)
      end

      def getDownWill(flag)
        if flag >= 10
          return "6"
        end

        dice = @randomizer.roll_once(6)
        return "1D6->#{dice}"
      end

      # スキル判定値　xJD or xJDy or xJDy+z or xJDy-z or xJDy/z
      def checkJudgeValue(string)
        debug("checkJudgeValue begin string", string)

        m = %r{^(\d+)JD(\d+)?(([+-/])(\d+))?$}i.match(string)
        unless m
          return nil
        end

        skill = m[1].to_i
        flag = m[2].to_i
        operator = m[4]
        value = m[5].to_i

        result = translate("DetatokoSaga.JD.input_options", skill: skill, flag: flag)

        modifyText = getModifyText(operator, value)
        result += translate("DetatokoSaga.JD.modifier", modifier: modifyText) unless modifyText.empty?

        total, rollText = getRollResult(skill)
        result += " ＞ #{total}[#{rollText}]#{modifyText}"

        totalResult = getTotalResultValue(total, value, operator)
        result += " ＞ #{totalResult}"

        result += getCheckFlagResult(total, flag)

        return result
      end

      def getModifyText(operator, value)
        return '' if value == 0

        operatorText =
          case operator
          when "+"
            "＋"
          when "-"
            "－"
          when "/"
            "÷"
          else
            return ""
          end

        return "#{operatorText}#{value}"
      end

      def getTotalResultValue(total, value, operator)
        case operator
        when "+"
          return "#{total}+#{value} ＞ " + translate("DetatokoSaga.total_value", total: total + value)
        when "-"
          return "#{total}-#{value} ＞ " + translate("DetatokoSaga.total_value", total: total - value)
        when "/"
          return getTotalResultValueWhenSlash(total, value)
        else
          return translate("DetatokoSaga.total_value", total: total)
        end
      end

      def getTotalResultValueWhenSlash(total, value)
        return translate("DetatokoSaga.division_by_zero_error") if value == 0

        quotient = ((1.0 * total) / value).ceil

        result = "#{total}÷#{value} ＞ " + translate("DetatokoSaga.total_value", total: quotient)
        return result
      end

      ALIAS = {
        "StrengthStigmaTable" => "SST",
        "WillStigmaTable" => "WST",
        "StrengthBadEndTable" => "SBET",
        "WillBadEndTable" => "WBET",
      }.transform_keys(&:upcase).freeze

      def self.translate_tables(locale)
        {
          "SST" => DiceTable::Table.from_i18n("DetatokoSaga.table.SST", locale),
          "WST" => DiceTable::Table.from_i18n("DetatokoSaga.table.WST", locale),
          "SBET" => DiceTable::Table.from_i18n("DetatokoSaga.table.SBET", locale),
          "WBET" => DiceTable::Table.from_i18n("DetatokoSaga.table.WBET", locale),
        }
      end

      TABLES = translate_tables(:ja_jp).freeze

      register_prefix(TABLES.keys, ALIAS.keys)
    end
  end
end
