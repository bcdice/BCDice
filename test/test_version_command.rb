# frozen_string_literal: true

require "test/unit"
require "bcdice"

class TestVersionCommand < Test::Unit::TestCase
  def test_bcdice_version
    game_system = BCDice::GameSystem::DiceBot.new("BCDiceVersion")
    out = game_system.eval()
    assert(out.text.include?(BCDice::VERSION))
  end
end
