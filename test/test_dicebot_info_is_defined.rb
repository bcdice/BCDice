# frozen_string_literal: true

bcdice_root = File.expand_path('..', File.dirname(__FILE__))
$:.unshift(bcdice_root) unless $:.include?(bcdice_root)

require 'test/unit'
require 'bcdice'
require 'bcdice/game_system'

class TestDiceBotInfoIsDefined < Test::Unit::TestCase
  # 一般的なダイスボット
  DEFAULT_DICEBOT = BCDice::GameSystem::DiceBot.new

  # ダイスボットの配列
  dicebots = BCDice.all_game_systems

  # テストデータを宣言する
  define_data = lambda { |klass| data(klass.name, klass) }

  dicebots.each(&define_data)
  # ゲームシステムの識別子が定義されているか確認する
  # @param [DiceBot] bot 確認するダイスボット
  def test_dicebot_id_is_defined(bot)
    assert_not_nil(bot::ID, "#{bot}: ゲームシステムの識別子が定義されている")
  end

  dicebots.each(&define_data)
  # ゲームシステム名が定義されているか確認する
  # @param [DiceBot] bot 確認するダイスボット
  def test_dicebot_name_is_defined(bot)
    assert_not_nil(bot::NAME, "#{bot}: ゲームシステム名が定義されている")
  end

  dicebots.each(&define_data)
  # ゲームシステム名の読みがなが定義されているか確認する
  # @param [DiceBot] bot 確認するダイスボット
  def test_dicebot_sort_key_is_defined(bot)
    assert_not_nil(bot::SORT_KEY, "#{bot}: ゲームシステム名の読みがなが定義されている")
  end
end
