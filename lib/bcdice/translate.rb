module BCDice
  # i18n用のモジュール
  module Translate
    # i18n用の翻訳メソッド
    # @param key [String]
    # @return [Object]
    def translate(key, **options)
      I18n.translate(key, locale: @locale, raise: true, **options)
    end

    # デフォルトロケールの翻訳結果とHashをマージして返す
    # @param key [String]
    # @return [Hash]
    def translate_with_hash_merge(key)
      hash = I18n.translate(key, locale: @locale, raise: true)
      base = I18n.translate(key, locale: I18n.default_locale, raise: true)

      hash.merge(base)
    end

    # デフォルトロケールの翻訳結果とArrayをマージして返す
    # @param key [String]
    # @return [Array]
    def translate_with_array_merge(key)
      array = I18n.translate(key, locale: @locale, raise: true)
      base = I18n.translate(key, locale: I18n.default_locale, raise: true)

      return array if array.size >= base.size

      ret = base.dup
      ret[0, array.length] = array

      ret
    end
  end
end
