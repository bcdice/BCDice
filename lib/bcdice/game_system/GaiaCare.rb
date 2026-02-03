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
        ・技能値判定（xDM<=y）
          "(個数)DM<=(判定値)"で指定します。
          ダイスの個数は省略可能で、省略した場合1個になります。
          例）2DM<=5 DM<=8

        ・ダイスボーナス付き判定（xDM<=yDz / xDM<=yDt-z / xDM<=yDxz）
          末尾にDz、Dt-z、Dxzを付けることでダイス数を変更できます。
          Dz: ダイス数にzを加算
          Dt-z: ダイス数からzを減算
          Dxz: ダイス数をz倍
          例）2DM<=5D2 → 4個のダイスで判定値5
              3DM<=5Dt-1 → 2個のダイスで判定値5
              2DM<=5Dx2 → 4個のダイスで判定値5
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
