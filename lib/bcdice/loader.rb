# frozen_string_literal: true

module BCDice
  class << self
    # IDを指定してゲームシステムのクラスを取得する
    # ゲームシステム一覧がロードされていなければロードする
    #
    # @param id [String] ID
    # @return [Class, nil]
    def game_system_class(id)
      all_game_systems.find { |game_system| id == game_system::ID }
    end

    # ゲームシステムのクラス一覧を返す
    # ゲームシステム一覧がロードされていなければロードする
    #
    # @return [Array<Class>]
    def all_game_systems()
      require "bcdice/game_system"
      BCDice::GameSystem.constants.map { |class_name| BCDice::GameSystem.const_get(class_name) }
    end

    # IDを指定して対象のソースコードを動的にロードし、そのクラスを取得する
    #
    # @param id [String] ID
    # @return [Class, nil]
    def dynamic_load(id)
      class_name = id.tr(":.", "_")

      # 対象ディレクトリの外にあるファイルをロードされないように制約を設ける
      unless /\A[A-Z]\w*\z/.match?(class_name)
        return nil
      end

      require "bcdice/game_system/#{class_name}"

      return BCDice::GameSystem.const_get(class_name)
    rescue LoadError, NameError
      return nil
    end
  end
end
