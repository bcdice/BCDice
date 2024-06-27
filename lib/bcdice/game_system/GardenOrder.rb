# frozen_string_literal: true

require 'bcdice/arithmetic_evaluator'
require 'bcdice/dice_table/range_table'

module BCDice
  module GameSystem
    class GardenOrder < Base
      # ゲームシステムのの識別子
      ID = 'GardenOrder'

      # ゲームシステム名
      NAME = 'ガーデンオーダー'

      # ゲームシステム名の読みがな
      SORT_KEY = 'かあてんおおたあ'

      # ダイスボットの使い方
      HELP_MESSAGE = <<~INFO_MESSAGE_TEXT
        ・基本判定
        　GOx/y@z　x：成功率、y：連続攻撃回数（省略可）、z：クリティカル値（省略可）
        　（連続攻撃では1回の判定のみが実施されます）
        　例）GO55　GO100/2　GO70@10　GO155/3@44
        ・負傷表
        　DCxxy
        　xx：属性（切断：SL，銃弾：BL，衝撃：IM，灼熱：BR，冷却：RF，電撃：EL）
        　y：ダメージ
        　例）DCSL7　DCEL22
      INFO_MESSAGE_TEXT

      register_prefix(
        'GO',
        'DC(SL|BL|IM|BR|RF|EL).+'
      )

      def eval_game_system_specific_command(command)
        case command
        when %r{GO(-?\d+)(/(\d+))?(@(\d+))?}i
          success_rate = Regexp.last_match(1).to_i
          repeat_count = (Regexp.last_match(3) || 1).to_i
          critical_border_text = Regexp.last_match(5)
          critical_border = get_critical_border(critical_border_text, success_rate)

          return check_roll_repeat_attack(success_rate, repeat_count, critical_border)

        when /^DC(SL|BL|IM|BR|RF|EL)(\d+)/i
          type = Regexp.last_match(1)
          damage_value = Regexp.last_match(2).to_i
          return look_up_damage_chart(type, damage_value)
        end

        return nil
      end

      def get_critical_border(critical_border_text, success_rate)
        return critical_border_text.to_i unless critical_border_text.nil?

        critical_border = [success_rate / 5, 1].max
        return critical_border
      end

      def check_roll_repeat_attack(success_rate, repeat_count, critical_border)
        success_rate_per_one = success_rate / repeat_count
        # 連続攻撃は最終的な成功率が50%以上であることが必要 cf. p217
        if repeat_count > 1 && success_rate_per_one < 50
          return "D100<=#{success_rate_per_one}@#{critical_border} ＞ 連続攻撃は成功率が50％以上必要です"
        end

        check_roll(success_rate_per_one, critical_border)
      end

      def check_roll(success_rate, critical_border)
        success_rate = 0 if success_rate < 0
        fumble_border = (success_rate < 100 ? 96 : 99)

        dice_value = @randomizer.roll_once(100)
        result = get_check_result(dice_value, success_rate, critical_border, fumble_border)

        result.text = "D100<=#{success_rate}@#{critical_border} ＞ #{dice_value} ＞ #{result.text}"
        return result
      end

      def get_check_result(dice_value, success_rate, critical_border, fumble_border)
        # クリティカルとファンブルが重なった場合は、ファンブルとなる。 cf. p175
        return Result.fumble(translate("fumble")) if dice_value >= fumble_border
        return Result.critical(translate("GardenOrder.critical")) if dice_value <= critical_border
        return Result.success(translate("success")) if dice_value <= success_rate

        return Result.failure(translate("failure"))
      end

      def look_up_damage_chart(type, damage_value)
        name, texts, damage = get_damage_table_info_by_type(type, damage_value)
        row = get_table_by_number(damage_value, name, texts, damage, nil)
        return nil if row.nil?

        translate("GardenOrder.Damage_name") + "：#{name}[#{damage_value}] ＞ #{row[:damage]} ｜ #{row[:name]} … #{row[:text]}"
      end

      def get_damage_table_info_by_type(type, damage_value)
        data = self.class: DAMAGE_TABLE[type].roll(damage_value)
        return nil if data.nil?

        return data[:name], data[:texts], data[:damage]
      end

      class << self
        private

        def translate_tables(locale)
          {
            "SL" => DiceTable::RangeTable.new(
              I18n.translate("GardenOrder.SL.name", locale: locale),
              "1D9999",
              [
                [1..5, I18n.translate("GardenOrder.SL.items.5", locale: locale)],
                [6..10, I18n.translate("GardenOrder.SL.items.10", locale: locale)],
                [11..13, I18n.translate("GardenOrder.SL.items.13", locale: locale)],
                [14..16, I18n.translate("GardenOrder.SL.items.16", locale: locale)],
                [17..19, I18n.translate("GardenOrder.SL.items.19", locale: locale)],
                [20..22, I18n.translate("GardenOrder.SL.items.22", locale: locale)],
                [23..25, I18n.translate("GardenOrder.SL.items.25", locale: locale)],
                [26..28, I18n.translate("GardenOrder.SL.items.28", locale: locale)],
                [29..31, I18n.translate("GardenOrder.SL.items.31", locale: locale)],
                [32..34, I18n.translate("GardenOrder.SL.items.34", locale: locale)],
                [35..37, I18n.translate("GardenOrder.SL.items.37", locale: locale)],
                [38..39, I18n.translate("GardenOrder.SL.items.39", locale: locale)],
                [40..9999, I18n.translate("GardenOrder.SL.items.9999", locale: locale)],
              ]
            ),

            "BL" => DiceTable::RangeTable.new(
              I18n.translate("GardenOrder.BL.name", locale: locale),
              "1D9999",
              [
                [1..5, I18n.translate("GardenOrder.BL.items.5", locale: locale)],
                [6..10, I18n.translate("GardenOrder.BL.items.10", locale: locale)],
                [11..13, I18n.translate("GardenOrder.BL.items.13", locale: locale)],
                [14..16, I18n.translate("GardenOrder.BL.items.16", locale: locale)],
                [17..19, I18n.translate("GardenOrder.BL.items.19", locale: locale)],
                [20..22, I18n.translate("GardenOrder.BL.items.22", locale: locale)],
                [23..25, I18n.translate("GardenOrder.BL.items.25", locale: locale)],
                [26..28, I18n.translate("GardenOrder.BL.items.28", locale: locale)],
                [29..31, I18n.translate("GardenOrder.BL.items.31", locale: locale)],
                [32..34, I18n.translate("GardenOrder.BL.items.34", locale: locale)],
                [35..37, I18n.translate("GardenOrder.BL.items.37", locale: locale)],
                [38..39, I18n.translate("GardenOrder.BL.items.39", locale: locale)],
                [40..9999, I18n.translate("GardenOrder.BL.items.9999", locale: locale)],
              ]
            ),

            "IM" => DiceTable::RangeTable.new(
              I18n.translate("GardenOrder.IM.name", locale: locale),
              "1D9999",
              [
                [1..5, I18n.translate("GardenOrder.IM.items.5", locale: locale)],
                [6..10, I18n.translate("GardenOrder.IM.items.10", locale: locale)],
                [11..13, I18n.translate("GardenOrder.IM.items.13", locale: locale)],
                [14..16, I18n.translate("GardenOrder.IM.items.16", locale: locale)],
                [17..19, I18n.translate("GardenOrder.IM.items.19", locale: locale)],
                [20..22, I18n.translate("GardenOrder.IM.items.22", locale: locale)],
                [23..25, I18n.translate("GardenOrder.IM.items.25", locale: locale)],
                [26..28, I18n.translate("GardenOrder.IM.items.28", locale: locale)],
                [29..31, I18n.translate("GardenOrder.IM.items.31", locale: locale)],
                [32..34, I18n.translate("GardenOrder.IM.items.34", locale: locale)],
                [35..37, I18n.translate("GardenOrder.IM.items.37", locale: locale)],
                [38..39, I18n.translate("GardenOrder.IM.items.39", locale: locale)],
                [40..9999, I18n.translate("GardenOrder.IM.items.9999", locale: locale)],
              ]
            ),

            "BR" => DiceTable::RangeTable.new(
              I18n.translate("GardenOrder.BR.name", locale: locale),
              "1D9999",
              [
                [1..5, I18n.translate("GardenOrder.BR.items.5", locale: locale)],
                [6..10, I18n.translate("GardenOrder.BR.items.10", locale: locale)],
                [11..13, I18n.translate("GardenOrder.BR.items.13", locale: locale)],
                [14..16, I18n.translate("GardenOrder.BR.items.16", locale: locale)],
                [17..19, I18n.translate("GardenOrder.BR.items.19", locale: locale)],
                [20..22, I18n.translate("GardenOrder.BR.items.22", locale: locale)],
                [23..25, I18n.translate("GardenOrder.BR.items.25", locale: locale)],
                [26..28, I18n.translate("GardenOrder.BR.items.28", locale: locale)],
                [29..31, I18n.translate("GardenOrder.BR.items.31", locale: locale)],
                [32..34, I18n.translate("GardenOrder.BR.items.34", locale: locale)],
                [35..37, I18n.translate("GardenOrder.BR.items.37", locale: locale)],
                [38..39, I18n.translate("GardenOrder.BR.items.39", locale: locale)],
                [40..9999, I18n.translate("GardenOrder.BR.items.9999", locale: locale)],
              ]
            ),

            "RF" => DiceTable::RangeTable.new(
              I18n.translate("GardenOrder.RF.name", locale: locale),
              "1D9999",
              [
                [1..5, I18n.translate("GardenOrder.RF.items.5", locale: locale)],
                [6..10, I18n.translate("GardenOrder.RF.items.10", locale: locale)],
                [11..13, I18n.translate("GardenOrder.RF.items.13", locale: locale)],
                [14..16, I18n.translate("GardenOrder.RF.items.16", locale: locale)],
                [17..19, I18n.translate("GardenOrder.RF.items.19", locale: locale)],
                [20..22, I18n.translate("GardenOrder.RF.items.22", locale: locale)],
                [23..25, I18n.translate("GardenOrder.RF.items.25", locale: locale)],
                [26..28, I18n.translate("GardenOrder.RF.items.28", locale: locale)],
                [29..31, I18n.translate("GardenOrder.RF.items.31", locale: locale)],
                [32..34, I18n.translate("GardenOrder.RF.items.34", locale: locale)],
                [35..37, I18n.translate("GardenOrder.RF.items.37", locale: locale)],
                [38..39, I18n.translate("GardenOrder.RF.items.39", locale: locale)],
                [40..9999, I18n.translate("GardenOrder.RF.items.9999", locale: locale)],
              ]
            ),

            "EL" => DiceTable::RangeTable.new(
              I18n.translate("GardenOrder.EL.name", locale: locale),
              "1D9999",
              [
                [1..5, I18n.translate("GardenOrder.EL.items.5", locale: locale)],
                [6..10, I18n.translate("GardenOrder.EL.items.10", locale: locale)],
                [11..13, I18n.translate("GardenOrder.EL.items.13", locale: locale)],
                [14..16, I18n.translate("GardenOrder.EL.items.16", locale: locale)],
                [17..19, I18n.translate("GardenOrder.EL.items.19", locale: locale)],
                [20..22, I18n.translate("GardenOrder.EL.items.22", locale: locale)],
                [23..25, I18n.translate("GardenOrder.EL.items.25", locale: locale)],
                [26..28, I18n.translate("GardenOrder.EL.items.28", locale: locale)],
                [29..31, I18n.translate("GardenOrder.EL.items.31", locale: locale)],
                [32..34, I18n.translate("GardenOrder.EL.items.34", locale: locale)],
                [35..37, I18n.translate("GardenOrder.EL.items.37", locale: locale)],
                [38..39, I18n.translate("GardenOrder.EL.items.39", locale: locale)],
                [40..9999, I18n.translate("GardenOrder.EL.items.9999", locale: locale)],
              ]
            )
          }.freeze
        end
      end

      DAMAGE_TABLE = translate_tables(:ja_jp).freeze
    end
  end
end
