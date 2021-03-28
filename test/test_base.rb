# frozen_string_literal: true

require "test/unit"
require "bcdice"

class DummySystem < BCDice::Base
  register_prefix("ABC", "XYZ", 'IP\d+')
end

class TestBase < Test::Unit::TestCase
  def test_command_pattern
    assert_equal(/^S?([+\-\dD(]+|\d+B\d+|C|choice|D66|(repeat|rep|x)\d+|\d+R\d+|\d+U\d+|BCDiceVersion|ABC|XYZ|IP\d+)/i, DummySystem.command_pattern)

    assert_match(DummySystem.command_pattern, "ABC+123")
    assert_match(DummySystem.command_pattern, "XYZ[hoge]")
    assert_match(DummySystem.command_pattern, "IP900+1000")
    assert_not_match(DummySystem.command_pattern, "IP+1000")
    assert_not_match(DummySystem.command_pattern, "EFG")

    assert_match(DummySystem.command_pattern, "1D100<=70")
    assert_match(DummySystem.command_pattern, "4D6+2D8")
    assert_match(DummySystem.command_pattern, "4B6+2B8")
    assert_match(DummySystem.command_pattern, "C2+4*3/2")
    assert_match(DummySystem.command_pattern, "choice[うさぎ,かめ]")
    assert_match(DummySystem.command_pattern, "D66s")
    assert_match(DummySystem.command_pattern, "1R10+5R6")
    assert_match(DummySystem.command_pattern, "1U10+2U20")
    assert_match(DummySystem.command_pattern, "bcdiceversion")

    assert_match(DummySystem.command_pattern, "(1+2)D100<=70")
    assert_not_match(DummySystem.command_pattern, "[1...3]D100<=70")
    assert_match(DummySystem.command_pattern, "-3+2D100<=70")
    assert_match(DummySystem.command_pattern, "+3+2D100<=70")
  end
end
