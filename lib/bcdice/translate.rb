# frozen_string_literal: true

module BCDice
  # i18n用のモジュール
  module Translate
    # i18n用の翻訳メソッド
    # @param key [String]
    # @return [Object]
    def translate(key, **options)
      I18n.translate(key, locale: @locale, raise: true, **options)
    end
  end
end
