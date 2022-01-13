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
        日常表・内容  DLA
        交流表・場所  INL
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
        'DLA' => DiceTable::Table.new(
          "日常表・内容",
          "1D6",
          [
            "仕事／勉強 → 片方の仕事や勉強を、もう片方が手伝っている。",
            "ゲーム → ふたりでゲームを楽しんでいる。",
            "趣味 → 片方の趣味にもう片方がつきあっている。",
            "食事 → 食事をとっている。もしくは料理をしている。",
            "掃除／整頓 → ふたりで、その場の掃除や整頓を行なっている。",
            "訓練／手入れ → 戦闘訓練や、武器の手入れなどを行なっている。",
          ]
        ),
        'INL' => DiceTable::Table.new(
          "交流表・場所",
          "1D6",
          [
            "カフェ → お洒落なカフェ。一息つくには丁度いい。",
            "路地裏 → 薄暗い路地裏。少なくとも人目は気にならない。",
            "公園 → 解放感のある公園。自動販売機もある。",
            "拠点 → 組織が管理している隠れ家。安全な場所だ。",
            "車内 → 車や電車の中。他の人がいるなら声量には気をつけて。",
            "屋上 → 街を見下ろせるビルの屋上。風が気持ちいい。",
          ]
        ),
      }.transform_keys(&:upcase).freeze

      register_prefix(TABLES.keys)
    end
  end
end
