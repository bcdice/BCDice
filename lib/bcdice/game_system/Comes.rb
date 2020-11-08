# frozen_string_literal: true

module BCDice
  module GameSystem
    class Comes < Base
      # ゲームシステムの識別子
      ID = 'Comes'

      # ゲームシステム名
      NAME = 'カムズ'

      # ゲームシステム名の読みがな
      SORT_KEY = 'かむす'

      # ダイスボットの使い方
      HELP_MESSAGE = <<~INFO_MESSAGE_TEXT
        ・各種表
        　判定ペナルティ表 PT
      INFO_MESSAGE_TEXT

      def initialize(command)
        super(command)

        @sort_add_dice = true
        @d66_sort_type = D66SortType::ASC
      end

      def eval_game_system_specific_command(command)
        return roll_tables(command, self.class::TABLES)
      end

      TABLES = {
        'PT' => DiceTable::Table.new(
          '判定ペナルティ表',
          '1D6',
          [
            '恐ろしい目に合う。『恐怖』を与える。',
            '今見ているものを理解できない。『混乱』を与える。',
            '我を忘れて見とれてしまう。『魅了』を与える。',
            '思わぬ遠回りをしてしまう。『疲労』を与える。',
            '大きな失態を演じてしまう。『負傷』を与える。',
            '別の困難が立ちはだかる。新たに判定を行わせる。',
          ]
        )
      }.freeze

      register_prefix(TABLES.keys)
    end
  end
end
