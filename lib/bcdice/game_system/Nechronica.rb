# frozen_string_literal: true

require 'bcdice/dice_table/table'

module BCDice
  module GameSystem
    class Nechronica < Base
      # ゲームシステムの識別子
      ID = 'Nechronica'

      # ゲームシステム名
      NAME = 'ネクロニカ'

      # ゲームシステム名の読みがな
      SORT_KEY = 'ねくろにか'

      # ダイスボットの使い方
      HELP_MESSAGE = <<~INFO_MESSAGE_TEXT
        ・判定　(nNC+m)
        　ダイス数n、修正値mで判定ロールを行います(省略=1)
        　ダイス数が2以上の時のパーツ破損数も表示します。
        ・攻撃判定　(nNA+m)
        　ダイス数n、修正値mで攻撃判定ロールを行います(省略=1)
        　命中部位とダイス数が2以上の時のパーツ破損数も表示します。

        表
        ・姉妹への未練表 nm
        ・中立者への未練表 nmn
        ・敵への未練表 nme
      INFO_MESSAGE_TEXT

      def initialize(command)
        super(command)

        @sort_add_dice = true
        @sort_barabara_dice = true
        @default_target_number = 6 # 目標値が空欄の時の目標値
      end

      def eval_game_system_specific_command(command)
        roll_tables(command, self.class::TABLES) || nechronica_check(command)
      end

      def result_nd10(total, _dice_total, value_list, cmp_op, target)
        # 後方互換を維持するため、1d10>=nを目標値nの1NCとして処理
        return nil unless value_list.count == 1 && cmp_op == :>=

        result_nechronica([total], target)
      end

      private

      def result_nechronica(value_list, target, output = [], na = nil)
        if value_list.max >= target
          if value_list.max >= 11
            output << translate("Nechronica.critical") << na
            Result.critical(output.compact.join(" ＞ "))
          else
            output << translate("success") << na
            Result.success(output.compact.join(" ＞ "))
          end
        elsif value_list.count { |i| i <= 1 } == 0
          output << translate("failure") << na
          Result.failure(output.compact.join(" ＞ "))
        elsif value_list.size > 1
          break_all_parts = translate("Nechronica.break_all_parts")
          fumble = translate("Nechronica.fumble")
          output << "#{fumble} ＞ #{break_all_parts}" << na
          Result.fumble(output.compact.join(" ＞ "))
        else
          output << translate("Nechronica.fumble") << na
          Result.fumble(output.compact.join(" ＞ "))
        end
      end

      # Rコマンドの後方互換を維持する
      def r_backward_compatibility(command)
        m = command.match(/^(\d)?R10([+\-\d]+)?(\[(\d+)\])?$/)
        return command unless m

        if m[4] == "1"
          "#{m[1]}NA#{m[2]}"
        else
          "#{m[1]}NC#{m[2]}"
        end
      end

      def nechronica_check(command)
        command = r_backward_compatibility(command)
        # 歴史的経緯で10を受理する
        parser = Command::Parser.new(/\d?N(C|A)(10)?/, round_type: round_type)
        cmd = parser.parse(command)
        return nil unless cmd

        dice_count = [1, cmd.command.to_i].max
        modify_number = cmd.modify_number || 0

        dice = @randomizer.roll_barabara(dice_count, 10).sort
        dice_mod = dice.map { |i| i + modify_number }
        total = dice_mod.max

        output = [
          "(#{cmd})",
          "[#{dice.join(',')}]#{Format.modifier(modify_number)}",
          "#{total}[#{dice_mod.join(',')}]",
        ]
        na = get_hit_location(total) if cmd.command.include?("NA")
        result_nechronica(dice_mod, 6, output, na)
      end

      def get_hit_location(value)
        return nil if value <= 5

        table = translate("Nechronica.hit_location.table")
        text = table[(value - 6).clamp(0, 5)]

        if value > 10
          text + translate("Nechronica.hit_location.additional_damage", damage: value - 10)
        else
          text
        end
      end

      class << self
        private

        def translate_tables(locale)
          {
            "NM" => DiceTable::Table.from_i18n("Nechronica.table.NM", locale),
            "NMN" => DiceTable::Table.from_i18n("Nechronica.table.NMN", locale),
            "NME" => DiceTable::Table.from_i18n("Nechronica.table.NME", locale),
          }
        end
      end

      TABLES = translate_tables(:ja_jp)

      register_prefix('\d?NC', '\d?NA', '\dR10', TABLES.keys)
    end
  end
end
