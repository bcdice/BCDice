# frozen_string_literal: true

require "test/unit"
require "bcdice"

class TestChecknDx < Test::Unit::TestCase
  SUFFIX = " ＞ Called MockSystem#check_2D6"

  class MockSystem < BCDice::Base
    def check_2D6(_total, _dice_total, _dice_list, _cmp_op, _target)
      SUFFIX
    end
  end

  def test_2D6_with_compare
    result = MockSystem.eval("2D6>=5")
    assert_include(result.text, SUFFIX)
  end

  def test_2D6_without_compare
    result = MockSystem.eval("2D6")
    assert_not_include(result.text, SUFFIX)
  end

  def test_1D6_1D6
    result = MockSystem.eval("1D6+1D6>5")
    assert_include(result.text, SUFFIX)
  end

  def test_1D4_1D6
    result = MockSystem.eval("1D4+1D6>5")
    assert_not_include(result.text, SUFFIX)
  end
end
