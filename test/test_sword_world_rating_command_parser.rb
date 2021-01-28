# frozen_string_literal: true

require "test/unit"
require "bcdice/base"
require "bcdice/game_system/sword_world/rating_parser"

class TestSwordWorldRatingCommandParser < Test::Unit::TestCase
  def setup
    @parser = BCDice::GameSystem::SwordWorld::RatingParser.new().set_debug()
  end

  def test_parse_v1_full_first_modify
    parsed = @parser.parse("K20+5+3@9$+1H+2")

    assert_not_nil(parsed)
    assert_equal(20, parsed.rate)
    assert_equal(8, parsed.modifier)
    assert_equal(9, parsed.critical)
    assert_nil(parsed.kept_modify)
    assert_nil(parsed.first_to)
    assert_equal(1, parsed.first_modify)
    assert_false(parsed.greatest_fortune)
    assert_nil(parsed.rateup)
    assert_true(parsed.half)
    assert_equal(2, parsed.modifier_after_half)
  end

  def test_parse_v1_full_first_to
    parsed = @parser.parse("K20+5+3@9$8H+2")

    assert_not_nil(parsed)
    assert_equal(20, parsed.rate)
    assert_equal(8, parsed.modifier)
    assert_equal(9, parsed.critical)
    assert_nil(parsed.kept_modify)
    assert_equal(8, parsed.first_to)
    assert_nil(parsed.first_modify)
    assert_false(parsed.greatest_fortune)
    assert_nil(parsed.rateup)
    assert_true(parsed.half)
    assert_equal(2, parsed.modifier_after_half)
  end

  def test_parse_v1_head_half
    parsed = @parser.parse("HK30+5+3")

    assert_not_nil(parsed)
    assert_equal(30, parsed.rate)
    assert_equal(8, parsed.modifier)
    assert_nil(parsed.critical)
    assert_nil(parsed.kept_modify)
    assert_nil(parsed.first_to)
    assert_nil(parsed.first_modify)
    assert_false(parsed.greatest_fortune)
    assert_nil(parsed.rateup)
    assert_true(parsed.half)
    assert_equal(0, parsed.modifier_after_half)
  end

  def test_parse_v1_brace_critical
    parsed = @parser.parse("K50[8]+5+3")

    assert_not_nil(parsed)
    assert_equal(50, parsed.rate)
    assert_equal(8, parsed.modifier)
    assert_equal(8, parsed.critical)
    assert_nil(parsed.kept_modify)
    assert_nil(parsed.first_to)
    assert_nil(parsed.first_modify)
    assert_false(parsed.greatest_fortune)
    assert_nil(parsed.rateup)
    assert_false(parsed.half)
    assert_nil(parsed.modifier_after_half)
  end

  def test_parse_v1_brace_critical_only
    parsed = @parser.parse("K50[8]")
    assert_not_nil(parsed)
    assert_equal(50, parsed.rate)
    assert_equal(0, parsed.modifier)
    assert_equal(8, parsed.critical)
    assert_nil(parsed.kept_modify)
    assert_nil(parsed.first_to)
    assert_nil(parsed.first_modify)
    assert_false(parsed.greatest_fortune)
    assert_nil(parsed.rateup)
    assert_false(parsed.half)
    assert_nil(parsed.modifier_after_half)
  end

  def test_parse_v1_brace_critical_duplicate
    parsed = @parser.parse("K50[8]+5+3@9")

    assert_nil(parsed)
  end

  def test_parse_v1_gf_unsupported
    parsed = @parser.parse("K50[8]+5+3gf")

    assert_nil(parsed)
  end

  def test_parse_v1_kept_modify_unsupported
    parsed = @parser.parse("K50[8]+5+3#+1")

    assert_nil(parsed)
  end

  def test_parse_v1_rateup_unsupported
    parsed = @parser.parse("K50[8]+5+3r10")

    assert_nil(parsed)
  end

  def test_parse_v20_full
    @parser.set_version(:v2_0)
    parsed = @parser.parse("K20+5+3@9$+1gfr5H+2")

    assert_not_nil(parsed)
    assert_equal(20, parsed.rate)
    assert_equal(8, parsed.modifier)
    assert_equal(9, parsed.critical)
    assert_nil(parsed.kept_modify)
    assert_nil(parsed.first_to)
    assert_equal(1, parsed.first_modify)
    assert_true(parsed.greatest_fortune)
    assert_equal(5, parsed.rateup)
    assert_true(parsed.half)
    assert_equal(2, parsed.modifier_after_half)
  end

  def test_parse_v20_kept_modify_unsupported
    @parser.set_version(:v2_0)
    parsed = @parser.parse("K20+5+3#1")

    assert_nil(parsed)
  end

  def test_parse_v25_full
    @parser.set_version(:v2_5)
    parsed = @parser.parse("K20+5+3@9#+2$+1gfr5H+2")

    assert_not_nil(parsed)
    assert_equal(20, parsed.rate)
    assert_equal(8, parsed.modifier)
    assert_equal(9, parsed.critical)
    assert_equal(2, parsed.kept_modify)
    assert_nil(parsed.first_to)
    assert_equal(1, parsed.first_modify)
    assert_true(parsed.greatest_fortune)
    assert_equal(5, parsed.rateup)
    assert_true(parsed.half)
    assert_equal(2, parsed.modifier_after_half)
  end
end
