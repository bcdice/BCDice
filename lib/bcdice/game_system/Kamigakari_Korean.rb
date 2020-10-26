# frozen_string_literal: true

require "bcdice/game_system/Kamigakari"

module BCDice
  module GameSystem
    class Kamigakari_Korean < Kamigakari
      # ゲームシステムの識別子
      ID = 'Kamigakari:Korean'

      # ゲームシステム名
      NAME = '카미가카리'

      # ゲームシステム名の読みがな
      SORT_KEY = '国際化:Korean:카미가카리'

      # ダイスボットの使い方
      HELP_MESSAGE = <<~INFO_MESSAGE_TEXT
        ・각종표
         ・감정표(ET)
         ・영문소비의 댓가표(RT)
         ・전기 성씨・이름 결정표(NT)
         ・마경임계표(KT)
         ・획득 소재 차트(MTx x는［법칙장해］의［강도］.생략할 때는１)
        　　예） MT　MT3　MT9
        ・D66주사위 가능
      INFO_MESSAGE_TEXT

      register_prefix_from_super_class()

      def initialize(command)
        super(command)

        @locale = :ko_kr
      end

      TABLES = translate_tables(:ko_kr).freeze
    end
  end
end
