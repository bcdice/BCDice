# frozen_string_literal: true

module BCDice
  module GameSystem
    class MagicPunk < Base
      # ゲームシステムの識別子
      ID = "MagicPunk"

      # ゲームシステム名
      NAME = "マジックパンクTRPG"

      # ゲームシステム名の読みがな
      SORT_KEY = "まじっくぱんくTRPG"

      HELP_MESSAGE = <<~TEXT
        ■ 判定 (nMPm)
        nD20のダイスロールをして、m以下の目があれば成功。
        mと同じ目があればジャックポット(自動成功)。
        すべての目が1ならバッドビート(自動失敗)。
        ■ チャレンジ判定 (nMPm>=x、nMPmCx)
        通常の判定に加えてチャレンジ値x以上の目が必要になる。
      TEXT

      register_prefix()

      def eval_game_system_specific_command(command)
        return nil
      end
    end
  end
end
