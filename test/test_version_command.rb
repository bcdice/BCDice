require "test/unit"
require "bcdice"

class TestVersionCommand < Test::Unit::TestCase
  def setup
    @game_system = BCDice::GameSystem::DiceBot.new
  end

  def test_bcdice_version
    out = @game_system.eval("BCDiceVersion")
    assert(out.include?(BCDice::VERSION))
  end
end
