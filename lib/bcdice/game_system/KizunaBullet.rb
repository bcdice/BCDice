# frozen_string_literal: true

require "bcdice/base"

module BCDice
  module GameSystem
    class KizunaBullet < Base
      ID = "KizunaBullet"
      NAME = "キズナバレット"
      SORT_KEY = "きすなはれつと"

      HELP_MESSAGE = <<~MESSAGETEXT
        ■表
        日常表・場所  DLL
      MESSAGETEXT

      def eval_game_system_specific_command(command)
        roll_tables(command, TABLES)
      end

      TABLES = {
        'DLL' => DiceTable::Table.new(
          "日常表・場所",
          "1D6",
          [
            "ケージ → ハウンドの私室にオーナーがお邪魔している。",
            "公園 → 緑地公園、運動公園、あるいは小さな広場など。",
            "病院 → 組織の管理下にある病院、あるいは医務室など。",
            "オーナーの家 → オーナーの家に、ハウンドがお邪魔している。",
            "訓練場 → 武道場、ジム、体育館、あるいは射撃場など。",
            "資料室 → 組織の資料室や書庫、証拠品の保管庫など。",
          ]
        ),
      }.transform_keys(&:upcase).freeze

      register_prefix(TABLES.keys)
    end
  end
end
