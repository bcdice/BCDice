# frozen_string_literal: true

require "test/unit"
require "bcdice"

require_relative "randomizer_mock"

class AddDiceTest < Test::Unit::TestCase
  class DefaultRound < BCDice::Base
    def initialize(command)
      super(command)
      @round_type = BCDice::RoundType::ROUND
    end
  end

  class DefaultFloor < BCDice::Base
    def initialize(command)
      super(command)
      @round_type = BCDice::RoundType::FLOOR
    end
  end

  class DefaultCeil < BCDice::Base
    def initialize(command)
      super(command)
      @round_type = BCDice::RoundType::CEIL
    end
  end

  class ImplicitD10 < BCDice::Base
    def initialize(command)
      super(command)
      @sides_implicit_d = 10
    end
  end

  def test_default_round
    assert_equal("(1D1+3/2) ＞ 1[1]+3/2 ＞ 2", BCDice::Base.eval("1D1+3/2").text) # 1 + 1.5
    assert_equal("(1D1+4/3) ＞ 1[1]+4/3 ＞ 2", BCDice::Base.eval("1D1+4/3").text) # 1 + 1.33
  end

  def test_round
    assert_equal("(1D1+3/2) ＞ 1[1]+3/2 ＞ 3", DefaultRound.eval("1D1+3/2").text) # 1 + 1.5
    assert_equal("(1D1+4/3) ＞ 1[1]+4/3 ＞ 2", DefaultRound.eval("1D1+4/3").text) # 1 + 1.33
  end

  def test_ceil
    assert_equal("(1D1+3/2) ＞ 1[1]+3/2 ＞ 3", DefaultCeil.eval("1D1+3/2").text) # 1 + 1.5
    assert_equal("(1D1+4/3) ＞ 1[1]+4/3 ＞ 3", DefaultCeil.eval("1D1+4/3").text) # 1 + 1.33
  end

  def test_floor
    assert_equal("(1D1+3/2) ＞ 1[1]+3/2 ＞ 2", DefaultFloor.eval("1D1+3/2").text) # 1 + 1.5
    assert_equal("(1D1+4/3) ＞ 1[1]+4/3 ＞ 2", DefaultFloor.eval("1D1+4/3").text) # 1 + 1.33
  end

  def test_implicit_d10
    game_system = ImplicitD10.new("1D+4")
    game_system.randomizer = RandomizerMock.new([[10, 10]])

    assert_equal("(1D10+4) ＞ 10[10]+4 ＞ 14", game_system.eval.text)
  end

  def test_implicit_d_default
    game_system = BCDice::Base.new("1D+4")
    game_system.randomizer = RandomizerMock.new([[6, 6]])

    assert_equal("(1D6+4) ＞ 6[6]+4 ＞ 10", game_system.eval.text)
  end
end
