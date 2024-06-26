# frozen_string_literal: true

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
        name, table = get_damage_table_info_by_type(type)

        row = get_table_by_number(damage_value, table, nil)
        return nil if row.nil?

        translate("GardenOrder.Damage_name")"：#{name}[#{damage_value}] ＞ #{row[:damage]} ｜ #{row[:name]} … #{row[:text]}"
      end

      def get_damage_table_info_by_type(type)
        data = self.class::DAMAGE_TABLE[type]
        return nil if data.nil?

        return data[:name], data[:table]
      end

      class << self
        private

        def translate_tables(locale)
          {
            "SL" => {
              name: translate("GardenOrder.SL.name"),
              table: [
                [5,
                 {name: translate("GardenOrder.SL.5.name"),
                  text: translate("GardenOrder.SL.5.text"),
                  damage: translate("GardenOrder.SL.5.damage")}],
                [10,
                 {name: translate("GardenOrder.SL.10.name"),
                  text: translate("GardenOrder.SL.10.text"),
                  damage: translate("GardenOrder.SL.10.damage")}],
                [13,
                 {name: translate("GardenOrder.SL.13.name"),
                  text: translate("GardenOrder.SL.13.text"),
                  damage: translate("GardenOrder.SL.13.damage")}],
                [16,
                 {name: translate("GardenOrder.SL.16.name"),
                  text: translate("GardenOrder.SL.16.text"),
                  damage: translate("GardenOrder.SL.16.damage")}],
                [19,
                 {name: translate("GardenOrder.SL.19.name"),
                  text: translate("GardenOrder.SL.19.text"),
                  damage: translate("GardenOrder.SL.19.damage")}],
                [22,
                 {name: translate("GardenOrder.SL.22.name"),
                  text: translate("GardenOrder.SL.22.text"),
                  damage: translate("GardenOrder.SL.22.damage")}],
                [25,
                 {name: translate("GardenOrder.SL.25.name"),
                  text: translate("GardenOrder.SL.25.text"),
                  damage: translate("GardenOrder.SL.25.damage")}],
                [28,
                 {name: translate("GardenOrder.SL.28.name"),
                  text: translate("GardenOrder.SL.28.text"),
                  damage: translate("GardenOrder.SL.28.damage")}],
                [31,
                 {name: translate("GardenOrder.SL.31.name"),
                  text: translate("GardenOrder.SL.31.text"),
                  damage: translate("GardenOrder.SL.31.damage")}],
                [34,
                 {name: translate("GardenOrder.SL.34.name"),
                  text: translate("GardenOrder.SL.34.text"),
                  damage: translate("GardenOrder.SL.34.damage")}],
                [37,
                 {name: translate("GardenOrder.SL.37.name"),
                  text: translate("GardenOrder.SL.37.text"),
                  damage: translate("GardenOrder.SL.37.damage")}],
                [39,
                 {name: translate("GardenOrder.SL.39.name"),
                  text: translate("GardenOrder.SL.39.text"),
                  damage: translate("GardenOrder.SL.39.damage")}],
                [9999,
                 {name: translate("GardenOrder.SL.9999.name"),
                  text: translate("GardenOrder.SL.9999.text"),
                  damage: translate("GardenOrder.SL.9999.damage")}],
              ]
            },

            "BL" => {
              name: translate("GardenOrder.BL.name"),
              table: [
                [5,
                 {name: translate("GardenOrder.BL.5.name"),
                  text: translate("GardenOrder.BL.5.text"),
                  damage: translate("GardenOrder.BL.5.damage")}],
                [10,
                 {name: translate("GardenOrder.BL.10.name"),
                  text: translate("GardenOrder.BL.10.text"),
                  damage: translate("GardenOrder.BL.10.damage")}],
                [13,
                 {name: translate("GardenOrder.BL.13.name"),
                  text: translate("GardenOrder.BL.13.text"),
                  damage: translate("GardenOrder.BL.13.damage")}],
                [16,
                 {name: translate("GardenOrder.BL.16.name"),
                  text: translate("GardenOrder.BL.16.text"),
                  damage: translate("GardenOrder.BL.16.damage")}],
                [19,
                 {name: translate("GardenOrder.BL.19.name"),
                  text: translate("GardenOrder.BL.19.text"),
                  damage: translate("GardenOrder.BL.19.damage")}],
                [22,
                 {name: translate("GardenOrder.BL.22.name"),
                  text: translate("GardenOrder.BL.22.text"),
                  damage: translate("GardenOrder.BL.22.damage")}],
                [25,
                 {name: translate("GardenOrder.BL.25.name"),
                  text: translate("GardenOrder.BL.25.text"),
                  damage: translate("GardenOrder.BL.25.damage")}],
                [28,
                 {name: translate("GardenOrder.BL.28.name"),
                  text: translate("GardenOrder.BL.28.text"),
                  damage: translate("GardenOrder.BL.28.damage")}],
                [31,
                 {name: translate("GardenOrder.BL.31.name"),
                  text: translate("GardenOrder.BL.31.text"),
                  damage: translate("GardenOrder.BL.31.damage")}],
                [34,
                 {name: translate("GardenOrder.BL.34.name"),
                  text: translate("GardenOrder.BL.34.text"),
                  damage: translate("GardenOrder.BL.34.damage")}],
                [37,
                 {name: translate("GardenOrder.BL.37.name"),
                  text: translate("GardenOrder.BL.37.text"),
                  damage: translate("GardenOrder.BL.37.damage")}],
                [39,
                 {name: translate("GardenOrder.BL.39.name"),
                  text: translate("GardenOrder.BL.39.text"),
                  damage: translate("GardenOrder.BL.39.damage")}],
                [9999,
                 {name: translate("GardenOrder.BL.9999.name"),
                  text: translate("GardenOrder.BL.9999.text"),
                  damage: translate("GardenOrder.BL.9999.damage")}],
              ]
            },

            "IM" => {
              name: translate("GardenOrder.IM.name"),
              table: [
                [5,
                 {name: translate("GardenOrder.IM.5.name"),
                  text: translate("GardenOrder.IM.5.text"),
                  damage: translate("GardenOrder.IM.5.damage")}],
                [10,
                 {name: translate("GardenOrder.IM.10.name"),
                  text: translate("GardenOrder.IM.10.text"),
                  damage: translate("GardenOrder.IM.10.damage")}],
                [13,
                 {name: translate("GardenOrder.IM.13.name"),
                  text: translate("GardenOrder.IM.13.text"),
                  damage: translate("GardenOrder.IM.13.damage")}],
                [16,
                 {name: translate("GardenOrder.IM.16.name"),
                  text: translate("GardenOrder.IM.16.text"),
                  damage: translate("GardenOrder.IM.16.damage")}],
                [19,
                 {name: translate("GardenOrder.IM.19.name"),
                  text: translate("GardenOrder.IM.19.text"),
                  damage: translate("GardenOrder.IM.19.damage")}],
                [22,
                 {name: translate("GardenOrder.IM.22.name"),
                  text: translate("GardenOrder.IM.22.text"),
                  damage: translate("GardenOrder.IM.22.damage")}],
                [25,
                 {name: translate("GardenOrder.IM.25.name"),
                  text: translate("GardenOrder.IM.25.text"),
                  damage: translate("GardenOrder.IM.25.damage")}],
                [28,
                 {name: translate("GardenOrder.IM.28.name"),
                  text: translate("GardenOrder.IM.28.text"),
                  damage: translate("GardenOrder.IM.28.damage")}],
                [31,
                 {name: translate("GardenOrder.IM.31.name"),
                  text: translate("GardenOrder.IM.31.text"),
                  damage: translate("GardenOrder.IM.31.damage")}],
                [34,
                 {name: translate("GardenOrder.IM.34.name"),
                  text: translate("GardenOrder.IM.34.text"),
                  damage: translate("GardenOrder.IM.34.damage")}],
                [37,
                 {name: translate("GardenOrder.IM.37.name"),
                  text: translate("GardenOrder.IM.37.text"),
                  damage: translate("GardenOrder.IM.37.damage")}],
                [39,
                 {name: translate("GardenOrder.IM.39.name"),
                  text: translate("GardenOrder.IM.39.text"),
                  damage: translate("GardenOrder.IM.39.damage")}],
                [9999,
                 {name: translate("GardenOrder.IM.9999.name"),
                  text: translate("GardenOrder.IM.9999.text"),
                  damage: translate("GardenOrder.IM.9999.damage")}],
              ]
            },

            "BR" => {
              name: translate("GardenOrder.BR.name"),
              table: [
                [5,
                 {name: translate("GardenOrder.BR.5.name"),
                  text: translate("GardenOrder.BR.5.text"),
                  damage: translate("GardenOrder.BR.5.damage")}],
                [10,
                 {name: translate("GardenOrder.BR.10.name"),
                  text: translate("GardenOrder.BR.10.text"),
                  damage: translate("GardenOrder.BR.10.damage")}],
                [13,
                 {name: translate("GardenOrder.BR.13.name"),
                  text: translate("GardenOrder.BR.13.text"),
                  damage: translate("GardenOrder.BR.13.damage")}],
                [16,
                 {name: translate("GardenOrder.BR.16.name"),
                  text: translate("GardenOrder.BR.16.text"),
                  damage: translate("GardenOrder.BR.16.damage")}],
                [19,
                 {name: translate("GardenOrder.BR.19.name"),
                  text: translate("GardenOrder.BR.19.text"),
                  damage: translate("GardenOrder.BR.19.damage")}],
                [22,
                 {name: translate("GardenOrder.BR.22.name"),
                  text: translate("GardenOrder.BR.22.text"),
                  damage: translate("GardenOrder.BR.22.damage")}],
                [25,
                 {name: translate("GardenOrder.BR.25.name"),
                  text: translate("GardenOrder.BR.25.text"),
                  damage: translate("GardenOrder.BR.25.damage")}],
                [28,
                 {name: translate("GardenOrder.BR.28.name"),
                  text: translate("GardenOrder.BR.28.text"),
                  damage: translate("GardenOrder.BR.28.damage")}],
                [31,
                 {name: translate("GardenOrder.BR.31.name"),
                  text: translate("GardenOrder.BR.31.text"),
                  damage: translate("GardenOrder.BR.31.damage")}],
                [34,
                 {name: translate("GardenOrder.BR.34.name"),
                  text: translate("GardenOrder.BR.34.text"),
                  damage: translate("GardenOrder.BR.34.damage")}],
                [37,
                 {name: translate("GardenOrder.BR.37.name"),
                  text: translate("GardenOrder.BR.37.text"),
                  damage: translate("GardenOrder.BR.37.damage")}],
                [39,
                 {name: translate("GardenOrder.BR.39.name"),
                  text: translate("GardenOrder.BR.39.text"),
                  damage: translate("GardenOrder.BR.39.damage")}],
                [9999,
                 {name: translate("GardenOrder.BR.9999.name"),
                  text: translate("GardenOrder.BR.9999.text"),
                  damage: translate("GardenOrder.BR.9999.damage")}],
              ]
            },

            "RF" => {
              name: translate("GardenOrder.RF.name"),
              table: [
                [5,
                 {name: translate("GardenOrder.RF.5.name"),
                  text: translate("GardenOrder.RF.5.text"),
                  damage: translate("GardenOrder.RF.5.damage")}],
                [10,
                 {name: translate("GardenOrder.RF.10.name"),
                  text: translate("GardenOrder.RF.10.text"),
                  damage: translate("GardenOrder.RF.10.damage")}],
                [13,
                 {name: translate("GardenOrder.RF.13.name"),
                  text: translate("GardenOrder.RF.13.text"),
                  damage: translate("GardenOrder.RF.13.damage")}],
                [16,
                 {name: translate("GardenOrder.RF.16.name"),
                  text: translate("GardenOrder.RF.16.text"),
                  damage: translate("GardenOrder.RF.16.damage")}],
                [19,
                 {name: translate("GardenOrder.RF.19.name"),
                  text: translate("GardenOrder.RF.19.text"),
                  damage: translate("GardenOrder.RF.19.damage")}],
                [22,
                 {name: translate("GardenOrder.RF.22.name"),
                  text: translate("GardenOrder.RF.22.text"),
                  damage: translate("GardenOrder.RF.22.damage")}],
                [25,
                 {name: translate("GardenOrder.RF.25.name"),
                  text: translate("GardenOrder.RF.25.text"),
                  damage: translate("GardenOrder.RF.25.damage")}],
                [28,
                 {name: translate("GardenOrder.RF.28.name"),
                  text: translate("GardenOrder.RF.28.text"),
                  damage: translate("GardenOrder.RF.28.damage")}],
                [31,
                 {name: translate("GardenOrder.RF.31.name"),
                  text: translate("GardenOrder.RF.31.text"),
                  damage: translate("GardenOrder.RF.31.damage")}],
                [34,
                 {name: translate("GardenOrder.RF.34.name"),
                  text: translate("GardenOrder.RF.34.text"),
                  damage: translate("GardenOrder.RF.34.damage")}],
                [37,
                 {name: translate("GardenOrder.RF.37.name"),
                  text: translate("GardenOrder.RF.37.text"),
                  damage: translate("GardenOrder.RF.37.damage")}],
                [39,
                 {name: translate("GardenOrder.RF.39.name"),
                  text: translate("GardenOrder.RF.39.text"),
                  damage: translate("GardenOrder.RF.39.damage")}],
                [9999,
                 {name: translate("GardenOrder.RF.9999.name"),
                  text: translate("GardenOrder.RF.9999.text"),
                  damage: translate("GardenOrder.RF.9999.damage")}],
              ]
            },

            "EL" => {
              name: translate("GardenOrder.EL.name"),
              table: [
                [5,
                 {name: translate("GardenOrder.EL.5.name"),
                  text: translate("GardenOrder.EL.5.text"),
                  damage: translate("GardenOrder.EL.5.damage")}],
                [10,
                 {name: translate("GardenOrder.EL.10.name"),
                  text: translate("GardenOrder.EL.10.text"),
                  damage: translate("GardenOrder.EL.10.damage")}],
                [13,
                 {name: translate("GardenOrder.EL.13.name"),
                  text: translate("GardenOrder.EL.13.text"),
                  damage: translate("GardenOrder.EL.13.damage")}],
                [16,
                 {name: translate("GardenOrder.EL.16.name"),
                  text: translate("GardenOrder.EL.16.text"),
                  damage: translate("GardenOrder.EL.16.damage")}],
                [19,
                 {name: translate("GardenOrder.EL.19.name"),
                  text: translate("GardenOrder.EL.19.text"),
                  damage: translate("GardenOrder.EL.19.damage")}],
                [22,
                 {name: translate("GardenOrder.EL.22.name"),
                  text: translate("GardenOrder.EL.22.text"),
                  damage: translate("GardenOrder.EL.22.damage")}],
                [25,
                 {name: translate("GardenOrder.EL.25.name"),
                  text: translate("GardenOrder.EL.25.text"),
                  damage: translate("GardenOrder.EL.25.damage")}],
                [28,
                 {name: translate("GardenOrder.EL.28.name"),
                  text: translate("GardenOrder.EL.28.text"),
                  damage: translate("GardenOrder.EL.28.damage")}],
                [31,
                 {name: translate("GardenOrder.EL.31.name"),
                  text: translate("GardenOrder.EL.31.text"),
                  damage: translate("GardenOrder.EL.31.damage")}],
                [34,
                 {name: translate("GardenOrder.EL.34.name"),
                  text: translate("GardenOrder.EL.34.text"),
                  damage: translate("GardenOrder.EL.34.damage")}],
                [37,
                 {name: translate("GardenOrder.EL.37.name"),
                  text: translate("GardenOrder.EL.37.text"),
                  damage: translate("GardenOrder.EL.37.damage")}],
                [39,
                 {name: translate("GardenOrder.EL.39.name"),
                  text: translate("GardenOrder.EL.39.text"),
                  damage: translate("GardenOrder.EL.39.damage")}],
                [9999,
                 {name: translate("GardenOrder.EL.9999.name"),
                  text: translate("GardenOrder.EL.9999.text"),
                  damage: translate("GardenOrder.EL.9999.damage")}],
              ]
            }
          }.freeze
        end
      end

      DAMAGE_TABLE = translate_tables(:ja_jp).freeze

    end
  end
end
