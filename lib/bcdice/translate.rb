module BCDice
  # i18n用のモジュール
  module Translate
    # i18n用の翻訳メソッド
    # @param key [String]
    # @return [String]
    def translate(key, **options)
      I18n.translate(key, locale: @locale, raise: true, **options)
    end
  end
end
