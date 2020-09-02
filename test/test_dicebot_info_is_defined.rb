# -*- coding: utf-8 -*-
# frozen_string_literal: true

bcdice_root = File.expand_path('..', File.dirname(__FILE__))
$:.unshift(bcdice_root) unless $:.include?(bcdice_root)

require 'test/unit'
require 'bcdice'
require 'bcdice/game_system/DiceBot'
require 'bcdice/game_system/DiceBotLoader'

class TestDiceBotInfoIsDefined < Test::Unit::TestCase
  # 一般的なダイスボット
  DEFAULT_DICEBOT = BCDice::GameSystem::DiceBot.new

  # ダイスボットの配列
  dicebots = DiceBotLoader.collectDiceBots

  # テストデータを宣言する
  define_data = lambda { |bot| data(bot.id, bot) }

  dicebots.each(&define_data)
  # ゲームシステムの識別子が定義されているか確認する
  # @param [DiceBot] bot 確認するダイスボット
  def test_dicebot_id_is_defined(bot)
    assert_not_nil(bot.id, "#{bot.class}: ゲームシステムの識別子が定義されている")
  end

  dicebots.each(&define_data)
  # ゲームシステム名が定義されているか確認する
  # @param [DiceBot] bot 確認するダイスボット
  def test_dicebot_name_is_defined(bot)
    assert_not_nil(bot.name, "#{bot.class}: ゲームシステム名が定義されている")
  end

  dicebots.each(&define_data)
  # ゲームシステム名の読みがなが定義されているか確認する
  # @param [DiceBot] bot 確認するダイスボット
  def test_dicebot_sort_key_is_defined(bot)
    assert_not_nil(bot.sort_key, "#{bot.class}: ゲームシステム名の読みがなが定義されている")
  end
end
