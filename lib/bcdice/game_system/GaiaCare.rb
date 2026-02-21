# frozen_string_literal: true

require "bcdice/game_system/Emoklore"

module BCDice
  module GameSystem
    class GaiaCare < Emoklore
      # ゲームシステムの識別子
      ID = "GaiaCare"

      # ゲームシステム名
      NAME = "ガイアケアTRPG"

      # ゲームシステム名の読みがな
      SORT_KEY = "かいあけあTRPG"

      # 親クラスのコマンドを継承
      register_prefix_from_super_class()

      # ダイスボットの使い方
      HELP_MESSAGE = <<~MESSAGETEXT
        ・技能値判定（xDM<=y / xDM<=yEz）
          "(個数)DM<=(判定値)"で指定します。
          ダイスの個数は省略可能で、省略した場合1個になります。
          個数や判定値には四則演算（+-*/）を使用できます。
          末尾にEzを付けるとダイス数にzを加算します。E-zで減算も可能です。
          例）2DM<=5 DM<=8 2+2DM<=5 → 4個で判定値5
              2DM<=5E2 → 4個で判定値5 / 3DM<=5E-1 → 2個で判定値5
          ※ダイス数が0以下になる場合は確定失敗

        ・技能値判定（sDAa+z)
          "(技能レベル)DA(能力値)+(ダイスボーナス)"で指定します。
          ダイスボーナスの個数は省略可能で、省略した場合0になります。
          技能レベルは1～3の数値、またはベース技能の場合"b"が入ります。
          ダイスの個数は技能レベルとダイスボーナスの個数により決定し、s+z個のダイスを振ります。（s="b"の場合はs=1）
          判定値はs+aとなります。（s="b"の場合はs=0）
      MESSAGETEXT
    end
  end
end
