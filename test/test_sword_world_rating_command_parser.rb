# frozen_string_literal: true

require "test/unit"
require "bcdice/base"
require "bcdice/game_system/sword_world/rating_parser"

class TestSwordWorldRatingCommandParser < Test::Unit::TestCase
  def test_parse_v1_full_first_modify
    parser = BCDice::GameSystem::SwordWorld::RatingParser.new().set_debug()
    parsed = parser.parse("K20+5+3@9$+1H+2")

    assert_not_nil(parsed)
    assert_equal(20, parsed.rate)
    assert_equal(8, parsed.modifier)
    assert_equal(9, parsed.critical)
    assert_equal(0, parsed.kept_modify)
    assert_equal(0, parsed.first_to)
    assert_equal(1, parsed.first_modify)
    assert_false(parsed.greatest_fortune)
    assert_equal(0, parsed.rateup)
    assert_true(parsed.half)
    assert_equal(2, parsed.modifier_after_half)
  end

  def test_parse_v1_full_first_to
    parser = BCDice::GameSystem::SwordWorld::RatingParser.new().set_debug()
    parsed = parser.parse("K20+5+3@9$8H+2")

    assert_not_nil(parsed)
    assert_equal(20, parsed.rate)
    assert_equal(8, parsed.modifier)
    assert_equal(9, parsed.critical)
    assert_equal(0, parsed.kept_modify)
    assert_equal(8, parsed.first_to)
    assert_equal(0, parsed.first_modify)
    assert_false(parsed.greatest_fortune)
    assert_equal(0, parsed.rateup)
    assert_true(parsed.half)
    assert_equal(2, parsed.modifier_after_half)
  end

  def test_parse_v1_head_half
    parser = BCDice::GameSystem::SwordWorld::RatingParser.new().set_debug()
    parsed = parser.parse("HK30+5+3")

    assert_not_nil(parsed)
    assert_equal(30, parsed.rate)
    assert_equal(8, parsed.modifier)
    assert_equal(13, parsed.critical)
    assert_equal(0, parsed.kept_modify)
    assert_equal(0, parsed.first_to)
    assert_equal(0, parsed.first_modify)
    assert_false(parsed.greatest_fortune)
    assert_equal(0, parsed.rateup)
    assert_true(parsed.half)
    assert_equal(0, parsed.modifier_after_half)
  end

  def test_parse_v1_brace_critical
    parser = BCDice::GameSystem::SwordWorld::RatingParser.new().set_debug()
    parsed = parser.parse("K50[8]+5+3")

    assert_not_nil(parsed)
    assert_equal(50, parsed.rate)
    assert_equal(8, parsed.modifier)
    assert_equal(8, parsed.critical)
    assert_equal(0, parsed.kept_modify)
    assert_equal(0, parsed.first_to)
    assert_equal(0, parsed.first_modify)
    assert_false(parsed.greatest_fortune)
    assert_equal(0, parsed.rateup)
    assert_false(parsed.half)
    assert_equal(0, parsed.modifier_after_half)
  end

  def test_parse_v1_brace_critical_only
    parser = BCDice::GameSystem::SwordWorld::RatingParser.new().set_debug()
    parsed = parser.parse("K50[8]")

    assert_not_nil(parsed)
    assert_equal(50, parsed.rate)
    assert_equal(0, parsed.modifier)
    assert_equal(8, parsed.critical)
    assert_equal(0, parsed.kept_modify)
    assert_equal(0, parsed.first_to)
    assert_equal(0, parsed.first_modify)
    assert_false(parsed.greatest_fortune)
    assert_equal(0, parsed.rateup)
    assert_false(parsed.half)
    assert_equal(0, parsed.modifier_after_half)
  end

  def test_parse_v1_brace_critical_duplicate
    parser = BCDice::GameSystem::SwordWorld::RatingParser.new().set_debug()
    parsed = parser.parse("K50[8]+5+3@9")

    assert_nil(parsed)
  end

  def test_parse_v1_multiple_modifier
    parser = BCDice::GameSystem::SwordWorld::RatingParser.new().set_debug()
    parsed = parser.parse("K20+5H+3+2")

    assert_nil(parsed)
  end

  def test_parse_v1_gf_unsupported
    parser = BCDice::GameSystem::SwordWorld::RatingParser.new().set_debug()
    parsed = parser.parse("K50[8]+5+3gf")

    assert_nil(parsed)
  end

  def test_parse_v1_kept_modify_unsupported
    parser = BCDice::GameSystem::SwordWorld::RatingParser.new().set_debug()
    parsed = parser.parse("K50[8]+5+3#+1")

    assert_nil(parsed)
  end

  def test_parse_v1_rateup_unsupported
    parser = BCDice::GameSystem::SwordWorld::RatingParser.new().set_debug()
    parsed = parser.parse("K50[8]+5+3r10")

    assert_nil(parsed)
  end

  def test_parse_v1_arithmetic
    parser = BCDice::GameSystem::SwordWorld::RatingParser.new().set_debug()
    parsed = parser.parse("K50+5*4/2-1+3@10")

    assert_not_nil(parsed)
    assert_equal(50, parsed.rate)
    assert_equal(12, parsed.modifier)
    assert_equal(10, parsed.critical)
    assert_equal(0, parsed.kept_modify)
    assert_equal(0, parsed.first_to)
    assert_equal(0, parsed.first_modify)
    assert_false(parsed.greatest_fortune)
    assert_equal(0, parsed.rateup)
    assert_false(parsed.half)
    assert_equal(0, parsed.modifier_after_half)
  end

  def test_parse_v20_full_gf
    parser = BCDice::GameSystem::SwordWorld::RatingParser.new(version: :v2_0).set_debug()
    parsed = parser.parse("K20+5+3@9$+1gfr5H+2")

    assert_not_nil(parsed)
    assert_equal(20, parsed.rate)
    assert_equal(8, parsed.modifier)
    assert_equal(9, parsed.critical)
    assert_equal(0, parsed.kept_modify)
    assert_equal(0, parsed.first_to)
    assert_equal(1, parsed.first_modify)
    assert_true(parsed.greatest_fortune)
    assert_equal(5, parsed.rateup)
    assert_true(parsed.half)
    assert_equal(2, parsed.modifier_after_half)
  end

  def test_parse_v20_full_sf
    parser = BCDice::GameSystem::SwordWorld::RatingParser.new(version: :v2_0).set_debug()
    parsed = parser.parse("K20+5+3@9$+1sf4r5H+2")

    assert_not_nil(parsed)
    assert_equal(20, parsed.rate)
    assert_equal(8, parsed.modifier)
    assert_equal(9, parsed.critical)
    assert_equal(0, parsed.kept_modify)
    assert_equal(0, parsed.first_to)
    assert_equal(1, parsed.first_modify)
    assert_equal(4, parsed.semi_fixed_val)
    assert_equal(5, parsed.rateup)
    assert_true(parsed.half)
    assert_equal(2, parsed.modifier_after_half)
  end

  def test_parse_v20_full_tf
    parser = BCDice::GameSystem::SwordWorld::RatingParser.new(version: :v2_0).set_debug()
    parsed = parser.parse("K20+5+3@9$+1tf4r5H+2")

    assert_not_nil(parsed)
    assert_equal(20, parsed.rate)
    assert_equal(8, parsed.modifier)
    assert_equal(9, parsed.critical)
    assert_equal(0, parsed.kept_modify)
    assert_equal(0, parsed.first_to)
    assert_equal(1, parsed.first_modify)
    assert_equal(4, parsed.tmp_fixed_val)
    assert_equal(5, parsed.rateup)
    assert_true(parsed.half)
    assert_equal(2, parsed.modifier_after_half)
  end

  def test_parse_v20_kept_modify_unsupported
    parser = BCDice::GameSystem::SwordWorld::RatingParser.new(version: :v2_0).set_debug()
    parsed = parser.parse("K20+5+3#1")

    assert_nil(parsed)
  end

  def test_parse_v20_gf_sf_unsupported
    parser = BCDice::GameSystem::SwordWorld::RatingParser.new(version: :v2_5).set_debug()
    parsed = parser.parse("K20+5+3gfsf4")

    assert_nil(parsed)
  end

  def test_parse_v20_gf_tf_unsupported
    parser = BCDice::GameSystem::SwordWorld::RatingParser.new(version: :v2_5).set_debug()
    parsed = parser.parse("K20+5+3gftf4")

    assert_nil(parsed)
  end

  def test_parse_v20_sf_tf_unsupported
    parser = BCDice::GameSystem::SwordWorld::RatingParser.new(version: :v2_5).set_debug()
    parsed = parser.parse("K20+5+3sf4tf4")

    assert_nil(parsed)
  end

  def test_parse_v25_full_gf
    parser = BCDice::GameSystem::SwordWorld::RatingParser.new(version: :v2_5).set_debug()
    parsed = parser.parse("K20+5+3@9#+2$+1gfr5H+2")

    assert_not_nil(parsed)
    assert_equal(20, parsed.rate)
    assert_equal(8, parsed.modifier)
    assert_equal(9, parsed.critical)
    assert_equal(2, parsed.kept_modify)
    assert_equal(0, parsed.first_to)
    assert_equal(1, parsed.first_modify)
    assert_true(parsed.greatest_fortune)
    assert_equal(5, parsed.rateup)
    assert_true(parsed.half)
    assert_equal(2, parsed.modifier_after_half)
  end

  def test_parse_v25_full_sf
    parser = BCDice::GameSystem::SwordWorld::RatingParser.new(version: :v2_5).set_debug()
    parsed = parser.parse("K20+5+3@9#+2$+1sf4r5H+2")

    assert_not_nil(parsed)
    assert_equal(20, parsed.rate)
    assert_equal(8, parsed.modifier)
    assert_equal(9, parsed.critical)
    assert_equal(2, parsed.kept_modify)
    assert_equal(0, parsed.first_to)
    assert_equal(1, parsed.first_modify)
    assert_equal(4, parsed.semi_fixed_val)
    assert_equal(5, parsed.rateup)
    assert_true(parsed.half)
    assert_equal(2, parsed.modifier_after_half)
  end

  def test_parse_v25_full_tf
    parser = BCDice::GameSystem::SwordWorld::RatingParser.new(version: :v2_5).set_debug()
    parsed = parser.parse("K20+5+3@9#+2$+1tf4r5H+2")

    assert_not_nil(parsed)
    assert_equal(20, parsed.rate)
    assert_equal(8, parsed.modifier)
    assert_equal(9, parsed.critical)
    assert_equal(2, parsed.kept_modify)
    assert_equal(0, parsed.first_to)
    assert_equal(1, parsed.first_modify)
    assert_equal(4, parsed.tmp_fixed_val)
    assert_equal(5, parsed.rateup)
    assert_true(parsed.half)
    assert_equal(2, parsed.modifier_after_half)
  end

  def test_parse_v25_gf_sf_unsupported
    parser = BCDice::GameSystem::SwordWorld::RatingParser.new(version: :v2_5).set_debug()
    parsed = parser.parse("K20+5+3gfsf4")

    assert_nil(parsed)
  end

  def test_parse_v25_gf_tf_unsupported
    parser = BCDice::GameSystem::SwordWorld::RatingParser.new(version: :v2_5).set_debug()
    parsed = parser.parse("K20+5+3gftf4")

    assert_nil(parsed)
  end

  def test_parse_v25_sf_tf_unsupported
    parser = BCDice::GameSystem::SwordWorld::RatingParser.new(version: :v2_5).set_debug()
    parsed = parser.parse("K20+5+3sf4tf4")

    assert_nil(parsed)
  end
end
