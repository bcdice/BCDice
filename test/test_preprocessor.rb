require "test/unit"
require "bcdice/preprocessor"

class TestPreprocessor < Test::Unit::TestCase
  class Mock < BCDice::Base; end

  def setup
    @game_system = Mock.new("")
  end

  # カッコが個別に展開される
  def test_replace_parentheses
    text = BCDice::Preprocessor.process("10dx(8-1)+(5+5)", @game_system)
    assert_equal("10dx7+10", text)
  end

  # カッコがネストされていても展開される
  def test_replace_parentheses_nested
    text = BCDice::Preprocessor.process("1D(100+10*(20+30))", @game_system)
    assert_equal("1D600", text)
  end

  # 不正な式はそのまま
  def test_invalid_expr
    text = BCDice::Preprocessor.process("(10**2*(3+4))D6", @game_system)
    assert_equal("(10**2*7)D6", text)
  end

  # ネストが深くても展開される
  def test_replace_parentheses_nested_nested
    text = BCDice::Preprocessor.process("1D((((((((((((((((((10))))))))))))))))))", @game_system)
    assert_equal("1D10", text)
  end

  def test_implicit_d
    text = BCDice::Preprocessor.process("1D+3", @game_system)
    assert_equal("1D6+3", text)
  end

  def test_no_implicit_d
    text = BCDice::Preprocessor.process("1Dhoge", @game_system)
    assert_equal("1Dhoge", text)
  end
end
