require "test/unit"
require "bcdice"

class DummySystem < BCDice::Base
  register_prefix("ABC", "XYZ", 'IP\d+')
end

class TestBase < Test::Unit::TestCase
  def test_command_pattern
    assert_equal(/^S?([+\-\dD(\[]+|\d+B\d+|C|choice|D66|(repeat|rep|x)\d+|\d+R\d+|\d+U\d+|BCDiceVersion|ABC|XYZ|IP\d+)/i, DummySystem.command_pattern)

    assert(DummySystem.command_pattern.match?("ABC+123"))
    assert(DummySystem.command_pattern.match?("XYZ[hoge]"))
    assert(DummySystem.command_pattern.match?("IP900+1000"))
    assert_false(DummySystem.command_pattern.match?("IP+1000"))
    assert_false(DummySystem.command_pattern.match?("EFG"))

    assert(DummySystem.command_pattern.match?("1D100<=70"))
    assert(DummySystem.command_pattern.match?("4D6+2D8"))
    assert(DummySystem.command_pattern.match?("4B6+2B8"))
    assert(DummySystem.command_pattern.match?("C2+4*3/2"))
    assert(DummySystem.command_pattern.match?("choice[うさぎ,かめ]"))
    assert(DummySystem.command_pattern.match?("D66s"))
    assert(DummySystem.command_pattern.match?("1R10+5R6"))
    assert(DummySystem.command_pattern.match?("1U10+2U20"))
    assert(DummySystem.command_pattern.match?("bcdiceversion"))

    assert(DummySystem.command_pattern.match?("(1+2)D100<=70"))
    assert(DummySystem.command_pattern.match?("[1...3]D100<=70"))
    assert(DummySystem.command_pattern.match?("-3+2D100<=70"))
    assert(DummySystem.command_pattern.match?("+3+2D100<=70"))
  end
end
