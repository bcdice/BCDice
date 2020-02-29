# -*- coding: utf-8 -*-
# frozen_string_literal: true

# 新しいtest/unitが対応しているRubyバージョンのみでテストケースを定義する
if RUBY_VERSION >= '2.0'
  bcdice_root = File.expand_path('..', File.dirname(__FILE__))
  $:.unshift(bcdice_root) unless $:.include?(bcdice_root)

  require 'test/unit'
  require 'diceBot/DiceBot'
  require 'diceBot/DiceBotLoader'

  class TestDiceBotInfoIsDefined < Test::Unit::TestCase
    DEFAULT_DICEBOT = DiceBot.new

    dicebots = DiceBotLoader.collectDiceBots

    define_data = lambda { |bot| data(bot.id, bot) }

    dicebots.each(&define_data)
    # ゲームシステムの識別子が定義されているか確認する
    # @param [DiceBot] bot 確認するダイスボット
    def test_dicebot_id_is_defined(bot)
      assert_not_equal(DEFAULT_DICEBOT.id, bot.id)
    end

    dicebots.each(&define_data)
    # ゲームシステム名が定義されているか確認する
    # @param [DiceBot] bot 確認するダイスボット
    def test_dicebot_name_is_defined(bot)
      assert_not_equal(DEFAULT_DICEBOT.name, bot.name)
    end

    dicebots.each(&define_data)
    # ダイスボットの使い方が定義されているか確認する
    # @param [DiceBot] bot 確認するダイスボット
    def test_dicebot_help_message_is_defined(bot)
      assert_not_equal(DEFAULT_DICEBOT.help_message, bot.help_message)
    end
  end
end
