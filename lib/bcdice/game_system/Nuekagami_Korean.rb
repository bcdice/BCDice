# frozen_string_literal: true

module BCDice
  module GameSystem
    class Nuekagami_Korean < Nuekagami
      # ゲームシステムの識別子
      ID = 'Nuekagami:Korean'

      # ゲームシステム名
      NAME = '누에카가미'

      # ゲームシステム名の読みがな
      SORT_KEY = '国際化:Korean:누에카가미'

      # ダイスボットの使い方
      HELP_MESSAGE = <<~MESSAGETEXT
        ・상실표（xL）
        　BL：혈맥, LL：생기(生様), SL：혼백, FL：인연

        ・LR：상실 회복표

        ・문 통과 묘사표（xG）
        　HG：지옥문, RG：나생문, VG：주작문, OG：응천문
      MESSAGETEXT

      def initialize(command)
        super(command)

        @locale = :ko_kr
      end

      TABLES = translate_tables(:ko_kr)

      def eval_game_system_specific_command(command)
        roll_tables(command, TABLES)
      end

      register_prefix(TABLES.keys)
    end
  end
end
