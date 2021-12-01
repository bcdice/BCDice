# frozen_string_literal: true

require "test/unit"
require "bcdice/command/parser"

class TestCommandParser < Test::Unit::TestCase
  def setup
    @parser = BCDice::Command::Parser.new("LL", "SA", round_type: BCDice::RoundType::FLOOR)
                                     .enable_critical
                                     .enable_fumble
                                     .enable_dollar
  end

  def test_parse_full
    parsed = @parser.parse("LL@1#2$9+4<=5")

    assert_not_nil(parsed)
    assert_equal("LL", parsed.command)
    assert_equal(1, parsed.critical)
    assert_equal(2, parsed.fumble)
    assert_equal(9, parsed.dollar)
    assert_equal(4, parsed.modify_number)
    assert_equal(:<=, parsed.cmp_op)
    assert_equal(5, parsed.target_number)
  end

  def test_command_only
    parsed = @parser.parse("LL")

    assert_not_nil(parsed)
    assert_equal("LL", parsed.command)
    assert_equal(nil, parsed.critical)
    assert_equal(nil, parsed.fumble)
    assert_equal(nil, parsed.dollar)
    assert_equal(0, parsed.modify_number)
    assert_equal(nil, parsed.cmp_op)
    assert_equal(nil, parsed.target_number)
  end

  def test_not_match
    parsed = @parser.parse("RR@1#2+4<=5")

    assert_equal(nil, parsed)
  end

  def test_negative_suffix
    parsed = @parser.parse("LL@-1#-2$-5")

    assert_not_nil(parsed)
    assert_equal("LL", parsed.command)
    assert_equal(-1, parsed.critical)
    assert_equal(-2, parsed.fumble)
    assert_equal(-5, parsed.dollar)
  end

  def test_suffix_after_modify_number
    parsed = @parser.parse("LL+4@1#2$9<=5")

    assert_not_nil(parsed)
    assert_equal("LL", parsed.command)
    assert_equal(1, parsed.critical)
    assert_equal(2, parsed.fumble)
    assert_equal(9, parsed.dollar)
    assert_equal(4, parsed.modify_number)
    assert_equal(:<=, parsed.cmp_op)
    assert_equal(5, parsed.target_number)
  end

  def test_expr
    parsed = @parser.parse("LL@1#2-4*3+6/2<=-10/5+2*6")

    assert_not_nil(parsed)
    assert_equal("LL", parsed.command)
    assert_equal(1, parsed.critical)
    assert_equal(2, parsed.fumble)
    assert_equal(-9, parsed.modify_number)
    assert_equal(:<=, parsed.cmp_op)
    assert_equal(10, parsed.target_number)
  end

  def test_reverse_critical
    parsed = @parser.parse("LL#1@2+4<=5")

    assert_not_nil(parsed)
    assert_equal("LL", parsed.command)
    assert_equal(2, parsed.critical)
    assert_equal(1, parsed.fumble)
    assert_equal(4, parsed.modify_number)
    assert_equal(:<=, parsed.cmp_op)
    assert_equal(5, parsed.target_number)
  end

  def test_critical_only
    parsed = @parser.parse("LL@23")

    assert_not_nil(parsed)
    assert_equal("LL", parsed.command)
    assert_equal(23, parsed.critical)
    assert_equal(nil, parsed.fumble)
    assert_equal(nil, parsed.dollar)
  end

  def test_fumble_only
    parsed = @parser.parse("LL#23")

    assert_not_nil(parsed)
    assert_equal("LL", parsed.command)
    assert_equal(nil, parsed.critical)
    assert_equal(23, parsed.fumble)
    assert_equal(nil, parsed.dollar)
  end

  def test_dollar_only
    parsed = @parser.parse("LL$23")

    assert_not_nil(parsed)
    assert_equal("LL", parsed.command)
    assert_equal(nil, parsed.critical)
    assert_equal(nil, parsed.fumble)
    assert_equal(23, parsed.dollar)
  end

  def test_duplicate_critical
    parsed = @parser.parse("LL@2@5")

    assert_equal(nil, parsed)
  end

  def test_duplicate_fumble
    parsed = @parser.parse("LL#2#5")

    assert_equal(nil, parsed)
  end

  def test_duplicate_dollar
    parsed = @parser.parse("LL$2$5")

    assert_equal(nil, parsed)
  end

  def test_no_suffix
    parsed = @parser.parse("LL+10>30")

    assert_equal("LL", parsed.command)
    assert_equal(nil, parsed.critical)
    assert_equal(nil, parsed.fumble)
    assert_equal(nil, parsed.dollar)
    assert_equal(10, parsed.modify_number)
    assert_equal(:>, parsed.cmp_op)
    assert_equal(30, parsed.target_number)
  end

  def test_question_target
    @parser.enable_question_target
    parsed = @parser.parse("LL>=?")

    assert_equal("LL", parsed.command)
    assert_equal(nil, parsed.critical)
    assert_equal(nil, parsed.fumble)
    assert_equal(nil, parsed.dollar)
    assert_equal(0, parsed.modify_number)
    assert_equal(:>=, parsed.cmp_op)
    assert_true(parsed.question_target?)
  end

  def test_command_with_regexp
    parser = BCDice::Command::Parser.new(/\d+ABC\d+/, round_type: BCDice::RoundType::FLOOR)
    parsed = parser.parse("10ABC412>=40")

    assert_equal("10ABC412", parsed.command)
    assert_equal(:>=, parsed.cmp_op)
    assert_equal(40, parsed.target_number)
  end

  def test_prefix_number
    @parser.has_prefix_number
    parsed = @parser.parse("2LL")

    assert_equal("LL", parsed.command)
    assert_equal(2, parsed.prefix_number)
    assert_equal(nil, parsed.suffix_number)
  end

  def test_no_prefix_number
    @parser.has_prefix_number
    assert_nil(@parser.parse("LL"))
    assert_nil(@parser.parse("LL6"))
  end

  def test_optional_prefix_number
    @parser.enable_prefix_number

    assert_equal(2, @parser.parse("2LL").prefix_number)
    assert_equal(nil, @parser.parse("LL").prefix_number)
  end

  def test_suffix_number
    @parser.has_suffix_number
    parsed = @parser.parse("LL6")

    assert_equal("LL", parsed.command)
    assert_equal(nil, parsed.prefix_number)
    assert_equal(6, parsed.suffix_number)
  end

  def test_no_suffix_number
    @parser.has_suffix_number
    assert_nil(@parser.parse("LL"))
    assert_nil(@parser.parse("2LL"))
  end

  def test_optional_suffix_number
    @parser.enable_suffix_number

    assert_equal(10, @parser.parse("LL10").suffix_number)
    assert_equal(nil, @parser.parse("LL").suffix_number)
  end

  def test_prefix_suffix_number
    @parser.has_prefix_number
           .has_suffix_number
    parsed = @parser.parse("3LL10<=10+34")

    assert_equal("LL", parsed.command)
    assert_equal(3, parsed.prefix_number)
    assert_equal(10, parsed.suffix_number)
    assert_equal("3LL10<=44", parsed.to_s)
  end

  def test_no_prefix_suffix_number
    @parser.has_prefix_number
           .has_suffix_number

    assert_nil(@parser.parse("LL"))
    assert_nil(@parser.parse("4LL"))
    assert_nil(@parser.parse("LL5"))
  end

  def test_prefix_suffix_number_with_regexp
    parser = BCDice::Command::Parser.new(/[A-Z_]+/, round_type: BCDice::RoundType::FLOOR)
                                    .has_prefix_number
                                    .has_suffix_number
    parsed = parser.parse("16N_B62")

    assert_equal("N_B", parsed.command)
    assert_equal(16, parsed.prefix_number)
    assert_equal(62, parsed.suffix_number)
  end

  def test_ampersand
    parser = BCDice::Command::Parser.new("EX", round_type: BCDice::RoundType::FLOOR)
                                    .enable_ampersand

    parsed = parser.parse("EX&5")

    assert_equal("EX", parsed.command)
    assert_equal(5, parsed.ampersand)
  end
end
