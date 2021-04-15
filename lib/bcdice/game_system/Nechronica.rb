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
        　ダイス数n、修正値mで判定ロールを行います。
        　ダイス数が2以上の時のパーツ破損数も表示します。
        ・攻撃判定　(nNA+m)
        　ダイス数n、修正値mで攻撃判定ロールを行います。
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

      private

      def replace_text(string)
        string = string.gsub(/(\d+)NC(10)?([+\-][+\-\d]+)/i) { "#{Regexp.last_match(1)}R10#{Regexp.last_match(3)}[0]" }
        string = string.gsub(/(\d+)NC(10)?/i) { "#{Regexp.last_match(1)}R10[0]" }
        string = string.gsub(/(\d+)NA(10)?([+\-][+\-\d]+)/i) { "#{Regexp.last_match(1)}R10#{Regexp.last_match(3)}[1]" }
        string = string.gsub(/(\d+)NA(10)?/i) { "#{Regexp.last_match(1)}R10[1]" }

        return string
      end

      public

      def eval_game_system_specific_command(command)
        return roll_tables(command, self.class::TABLES) || nechronica_check(command)
      end

      private

      def check_nD10(total, _dice_total, dice_list, cmp_op, target) # ゲーム別成功度判定(nD10)
        return '' if target == '?'
        return '' unless cmp_op == :>=

        result =
          if total >= 11
            translate("Nechronica.critical")
          elsif total >= target
            translate("success")
          elsif dice_list.count { |i| i <= 1 } == 0
            translate("failure")
          elsif dice_list.size > 1
            fumble = translate("Nechronica.fumble")
            break_all_parts = translate("Nechronica.break_all_parts")
            "#{fumble} ＞ #{break_all_parts}"
          else
            translate("Nechronica.fumble")
          end

        return " ＞ #{result}"
      end

      def nechronica_check(string)
        string = replace_text(string)
        debug("nechronica_check string", string)

        unless /(^|\s)S?((\d+)[rR]10([+\-\d]+)?(\[(\d+)\])?)(\s|$)/i =~ string
          return nil
        end

        string = Regexp.last_match(2)

        dice_n = 1
        dice_n = Regexp.last_match(3).to_i if Regexp.last_match(3)

        battleMode = Regexp.last_match(6).to_i

        modText = Regexp.last_match(4)
        mod = ArithmeticEvaluator.eval(modText)

        # 0=判定モード, 1=戦闘モード
        isBattleMode = (battleMode == 1)
        debug("nechronica_check string", string)
        debug("isBattleMode", isBattleMode)

        diff = 6

        dice = @randomizer.roll_barabara(dice_n, 10).sort
        n_max = dice.max

        total_n = n_max + mod

        output = "(#{string}) ＞ [#{dice.join(',')}]"
        if mod < 0
          output += mod.to_s
        elsif mod > 0
          output += "+#{mod}"
        end

        dice.map! { |i| i + mod }

        dice_str = dice.join(",")
        output += "  ＞ #{total_n}[#{dice_str}]"

        output += check_nD10(total_n, dice_n, dice, :>=, diff)

        if isBattleMode
          hit_loc = getHitLocation(total_n)
          if hit_loc != '1'
            output += " ＞ #{hit_loc}"
          end
        end

        return output
      end

      def getHitLocation(dice)
        output = '1'

        debug("getHitLocation dice", dice)
        return output if dice <= 5

        table = translate("Nechronica.hit_location.table")
        index = dice - 6

        addDamage = ""
        if dice > 10
          index = 5
          addDamage = translate("Nechronica.hit_location.additional_damage", damage: dice - 10)
        end

        output = table[index] + addDamage

        return output
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

      register_prefix('\d+NC', '\d+NA', '\d+R10', TABLES.keys)
    end
  end
end
