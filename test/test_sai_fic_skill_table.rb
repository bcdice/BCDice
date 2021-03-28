# frozen_string_literal: true

require "test/unit"
require "bcdice"
require "bcdice/dice_table/sai_fic_skill_table"

class TestSaiFicSkillTable < Test::Unit::TestCase
  class DummySystem < BCDice::Base
    table = BCDice::DiceTable::SaiFicSkillTable.new([])

    register_prefix(table.prefixes)
  end

  def test_command_pattern
    assert_equal(/^S?([+\-\dD(]+|\d+B\d+|C|choice|D66|(repeat|rep|x)\d+|\d+R\d+|\d+U\d+|BCDiceVersion|RTT[1-6]?|RCT)/i, DummySystem.command_pattern)
  end
end
