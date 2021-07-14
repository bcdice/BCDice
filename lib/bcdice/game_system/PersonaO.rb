# frozen_string_literal: true

module BCDice
  module GameSystem
    class PersonaO < Base
      # ゲームシステムのの識別子
      ID = 'PersonaO'

      # ゲームシステム名
      NAME = 'ペルソナTRPG-O'

      # ゲームシステム名の読みがな
      SORT_KEY = 'へるそなTRPGO'

      # ダイスボットの使い方
      HELP_MESSAGE = <<~INFO_MESSAGE_TEXT
        ・基本判定
        　PTx@y　x：目標値、y：クリティカル値（省略時は5）
        　例）PT60　PT90@10

        ・ダメージ計算
        　
        　例）ソニックパンチ、力B2点、
        　　　タルカジャがかかっており、打撃耐性あり、
        　　　目標の物理防御力は2点
        　　　
        　　　2PD+(20+2*2)%(100+50-50)-2
      INFO_MESSAGE_TEXT

      register_prefix(
        'PT(\-?\d+)?(@(\-?\d+))?',
        '(\d+)PD\+(\-?\d+)%(\-?\d+)\-(\d+)'
      )

      def eval_game_system_specific_command(command)
        case command
        when /PT(-?\d+)?(@(-?\d+))?/i
          success_rate = Regexp.last_match(1).to_i
          critical_border_text = Regexp.last_match(3)
          critical_border = get_critical_border(critical_border_text, success_rate)

          return attack(success_rate, critical_border)

        when /(\d+)PD\+(-?\d+)%(-?\d+)-(\d+)/i
          dice = Regexp.last_match(1).to_i
          kotei = Regexp.last_match(2).to_i
          hosei = Regexp.last_match(3).to_i
          bougyo = Regexp.last_match(4).to_i
          return damage(dice, kotei, hosei, bougyo)
        end

        return nil
      end

      def get_critical_border(critical_border_text, _success_rate)
        return critical_border_text.to_i unless critical_border_text.nil?

        critical_border = 5
        return critical_border
      end

      def attack(success_rate, critical_border)
        dice_value = @randomizer.roll_once(100)
        result = get_check_result(dice_value, success_rate, critical_border)

        text = "D100<=#{success_rate}@#{critical_border} ＞ #{dice_value} ＞ #{result}"
        return text
      end

      def get_check_result(dice_value, success_rate, critical_border)
        return "クリティカル" if dice_value <= critical_border
        return "成功" if dice_value <= success_rate

        return "失敗"
      end

      def damage(dice, kotei, hosei, bougyo)
        dice_list = @randomizer.roll_barabara(dice, 10)
        dice_sum = dice_list.sum

        dice_sumF = dice_sum.to_f
        koteiF = kotei.to_f
        hoseiF = hosei.to_f
        bougyoF = bougyo.to_f

        inhoseiF = (hoseiF / 100) * koteiF
        dmgF = dice_sumF + inhoseiF - bougyoF
        dmg = dmgF.to_i

        return "#{dice}D10+#{kotei}＊#{hosei}%-#{bougyo} ＞ [#{dice_list.join(',')}]+#{kotei}＊#{hosei}%-#{bougyo} ＞ #{dmg} ダメージ！"
      end
    end
  end
end
