# -*- coding: utf-8 -*-

# ダイスボットの読み込みを担当するクラス
class DiceBotLoader
  # 登録されていないタイトルのダイスボットを読み込む
  # @param [String] gameTitle ゲームタイトル
  # @return [DiceBot] ダイスボットが存在した場合
  # @return [nil] 読み込み時にエラーが発生した場合
  def self.loadUnknownGame(gameTitle)
    debug("loadUnknownGame gameTitle", gameTitle)

    escapedGameTitle = gameTitle.gsub(/(\.\.|\/|:|-)/, '_')

    begin
      # ダイスボットファイルがこのディレクトリ内に存在すると仮定して読み込む
      require(
        File.expand_path("#{escapedGameTitle}.rb", File.dirname(__FILE__))
      )

      Module.const_get(gameTitle).new
    rescue LoadError, StandardError => e
      debug("DiceBot load ERROR!!!", e.to_s)
      nil
    end
  end

  def initialize
  end
end
