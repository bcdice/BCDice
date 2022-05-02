# frozen_string_literal: true

module BCDice
  module GameSystem
    class GhostLive < Base
      # ゲームシステムの識別子
      ID = 'GhostLive'

      # ゲームシステム名
      NAME = '実況ゴーストライヴ'

      # ゲームシステム名の読みがな
      SORT_KEY = 'しつきようこおすとらいふ'

      # ダイスボットの使い方
      HELP_MESSAGE = <<~MESSAGE
        ■追加目標表（p11）
        ATT, AdditionalTargetTable
      MESSAGE

      def eval_game_system_specific_command(command)
        command = ALIAS[command] || command
        roll_tables(command, TABLES)
      end

      TABLES = {
        "AdditionalTargetTable" => DiceTable::Table.new(
          "追加目標表",
          "1D6",
          [
            "オバケを撮影する。（依頼主：専門家／報酬：１Ｌ）",
            "誰かひとりが霊障を［サイクル数］回受ける。（依頼主：専門家／報酬：［サイクル数］Ｌ）",
            "誰かひとりが［精神力］を10以下の状態で帰る。（依頼主：専門家／報酬：３Ｌ）",
            "［精神力］の平均が20以下の状態で帰る。（依頼主：リスナー／報酬：［視聴回数］を10倍）",
            "全員がスマホ以外の［アイテム］を１個だけ持ち込んで生還する。（依頼主：リスナー／報酬：［視聴回数］を10倍）",
            "すべての［回収品］を集める。（依頼主：専門家／報酬：５Ｌ）",
          ]
        ),
      }.transform_keys(&:upcase).freeze

      ALIAS = {
        "ATT" => "AdditionalTargetTable",
      }.transform_values(&:upcase).freeze

      register_prefix(TABLES.keys, ALIAS.keys)
    end
  end
end
