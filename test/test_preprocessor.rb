require "test/unit"
require "bcdice/preprocessor"

class TestPreprocessor < Test::Unit::TestCase
  class Mock < BCDice::Base; end

  class ImplicitD10 < BCDice::Base
    def initialize(command)
      super(command)
      @sides_implicit_d = 10
    end
  end

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

  # 丸め指定
  def test_replace_parentheses_with_specific_round_type
    text = BCDice::Preprocessor.process("(1/2C),(1/2U),(1/2R),(1/2F)", @game_system)
    assert_equal("1,1,1,0", text)
  end

  def test_implicit_d
    text = BCDice::Preprocessor.process("1D+3", @game_system)
    assert_equal("1D6+3", text)
  end

  def test_no_implicit_d
    text = BCDice::Preprocessor.process("1Dhoge", @game_system)
    assert_equal("1Dhoge", text)
  end

  def test_implicit_d10
    game_system = ImplicitD10.new("")
    text = BCDice::Preprocessor.process("1D+3", game_system)
    assert_equal("1D10+3", text)
  end
end
