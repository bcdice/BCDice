# frozen_string_literal: true

require "test/unit"
require "bcdice"

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
end
