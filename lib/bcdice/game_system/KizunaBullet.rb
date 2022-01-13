# frozen_string_literal: true

require "bcdice/base"

module BCDice
  module GameSystem
    class KizunaBullet < Base
      ID = "KizunaBullet"
      NAME = "キズナバレット"
      SORT_KEY = "きすなはれつと"

      HELP_MESSAGE = <<~MESSAGETEXT
      MESSAGETEXT

      def eval_game_system_specific_command(command)
      end

      TABLES = {
      }.transform_keys(&:upcase).freeze

      register_prefix(TABLES.keys)
    end
  end
end
