# frozen_string_literal: true

module BCDice
  module GameSystem
    class Aionia < Base
      # ゲームシステムの識別子
      ID = "Aionia"

      # ゲームシステム名
      NAME = "慈悲なきアイオニア"

      # ゲームシステム名の読みがな
      SORT_KEY = "じひなきあいおにあ"

      HELP_MESSAGE = <<~INFO_MESSAGE_TEXT
        - 技能判定（クリティカル・ファンブルなし）
        s{n}>={dif} n=10面ダイスの数、dif=難易度
        - 技能判定（クリティカル・ファンブルあり）
        st{n}>={dif} n=10面ダイスの数、dif=難易度

        例:s2>=5        （一般技能を活用して難易度5の技能判定。 クリファンなし。）
        例:st3>=15      （専門技能を活用して難易度15の技能判定。クリファンあり。）
        例:s1+2>=8      （一般技能を活用せず難易度8の技能判定。 ボーナスとして+2点の補正あり。  クリファンなし。）
        例:st3-3>=10    （専門技能を活用して難易度10の技能判定。ペナルティとして-3点の補正あり。クリファンあり。）
        例:st2>=4/8/12  （一般技能を活用して難易度4/8/12の段階的な技能判定。クリファンあり。）
      INFO_MESSAGE_TEXT

      register_prefix('ST?\d+([\+\-]\d+)?>=\d+(\/\d+)*')

      def eval_game_system_specific_command(command)
        return roll_skills(command)
      end

      def roll_skills(command)
        m = %r{ST?(\d+)([+-]\d+)?>=(\d+)((/\d+)*)}.match(command)
        return nil unless m

        sides = m[1].to_i
        bonus = m[2].to_i
        target = m[3].to_i
        extra_target = m[4]
        return "sides: #{sides}, bonus: #{bonus}, target: #{target}, extra_target: #{extra_target}"
      end
    end
  end
end
