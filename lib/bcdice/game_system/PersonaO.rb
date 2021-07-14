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
        'PT',
        '\d+PD'
      )

      def eval_game_system_specific_command(command)
        roll_attack(command) || roll_damage(command)
      end

      private

      def roll_attack(command)
        m = /^PT(-?\d+)?(@(-?\d+))?$/i.match(command)
        unless m
          return nil
        end

        success_rate = m[1].to_i
        critical_border = m[3]&.to_i || 5

        dice_value = @randomizer.roll_once(100)
        result =
          if dice_value <= critical_border
            "クリティカル"
          elsif dice_value <= success_rate
            "成功"
          else
            "失敗"
          end

        return "D100<=#{success_rate}@#{critical_border} ＞ #{dice_value} ＞ #{result}"
      end

      def roll_damage(command)
        m = /^(\d+)PD\+(-?\d+)%(-?\d+)-(\d+)$/i.match(command)
        unless m
          return nil
        end

        dice = m[1].to_i
        kotei = m[2].to_i
        hosei = m[3].to_i
        bougyo = m[4].to_i

        dice_list = @randomizer.roll_barabara(dice, 10)
        dice_sum = dice_list.sum

        dmg = dice_sum + (hosei * kotei / 100.0).to_i - bougyo

        return "#{dice}D10+#{kotei}＊#{hosei}%-#{bougyo} ＞ [#{dice_list.join(',')}]+#{kotei}＊#{hosei}%-#{bougyo} ＞ #{dmg} ダメージ！"
      end
    end
  end
end
