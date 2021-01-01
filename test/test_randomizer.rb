# frozen_string_literal: true

require "test/unit"
require "bcdice/randomizer"

class TestRandomizer < Test::Unit::TestCase
  def setup
    @randomizer = BCDice::Randomizer.new
  end

  # ダイス面数が上限ぎりぎり
  def test_upper_limit_sides
    assert_not_equal(0, @randomizer.roll_once(1000))
  end

  # ダイス面数が上限超え
  def test_over_upper_limit_sides
    assert_equal(0, @randomizer.roll_once(1001))
  end

  # ダイス個数が上限ぎりぎり
  def test_upper_limit_times
    assert_equal(200, @randomizer.roll_barabara(200, 100).size)
  end

  # ダイス個数が上限超え
  def test_over_upper_limit_times
    assert_equal([], @randomizer.roll_barabara(201, 100))
  end

  # 面数0
  def test_roll_once_d0
    assert_equal(0, @randomizer.roll_once(0))
  end

  def test_roll_barabara_3d0
    assert_equal([0, 0, 0], @randomizer.roll_barabara(3, 0))
  end

  def test_roll_sum_10d0
    assert_equal(0, @randomizer.roll_sum(10, 0))
  end

  # 個数0
  def test_roll_barabara_0d100
    assert_equal([], @randomizer.roll_barabara(0, 100))
  end

  def test_roll_sum_0d10
    assert_equal(0, @randomizer.roll_sum(0, 10))
  end

  # 面数が負数の時には Karnel#rand の挙動に準拠する
  def test_roll_once_d_minus
    assert_nothing_raised do
      @randomizer.roll_once(-1)
    end
  end

  def test_roll_barabara_d_minus
    assert_equal(3, @randomizer.roll_barabara(3, -1).size)
  end

  def test_roll_sum_d_minus
    assert_nothing_raised do
      @randomizer.roll_sum(10, -1)
    end
  end

  def test_roll_barabara_minus_d
    assert_equal([], @randomizer.roll_barabara(-2, 6))
  end

  def test_roll_sum_minus_d
    assert_equal(0, @randomizer.roll_sum(-10, 100))
  end

  def test_no_raise_rands_limit_with_barabara
    assert_nothing_raised do
      @randomizer.roll_barabara(10000, 100)
    end
  end

  def test_raise_rands_limit_with_barabara
    assert_raise_kind_of(BCDice::TooManyRandsError) do
      @randomizer.roll_barabara(10001, 100)
    end
  end

  def test_raise_rands_limit_with_sum
    assert_raise_kind_of(BCDice::TooManyRandsError) do
      @randomizer.roll_sum(10001, 100)
    end
  end

  def test_no_raise_rands_limit_with_ones
    assert_nothing_raised do
      10000.times do
        @randomizer.roll_once(6)
      end
    end
  end

  def test_raise_rands_limit_with_ones
    assert_raise_kind_of(BCDice::TooManyRandsError) do
      10001.times do
        @randomizer.roll_once(6)
      end
    end
  end

  def test_raise_rands_limit_with_roll_tens_d10
    assert_raise_kind_of(BCDice::TooManyRandsError) do
      10001.times do
        @randomizer.roll_tens_d10()
      end
    end
  end

  def test_raise_rands_limit_with_d9
    assert_raise_kind_of(BCDice::TooManyRandsError) do
      10001.times do
        @randomizer.roll_d9()
      end
    end
  end

  def test_raise_rands_limit_with_d66
    assert_raise_kind_of(BCDice::TooManyRandsError) do
      10001.times do
        @randomizer.roll_d66(BCDice::D66SortType::ASC)
      end
    end
  end

  def test_raise_rands_limit_with_eval
    assert_raise_kind_of(BCDice::TooManyRandsError) do
      BCDice::GameSystem::DiceBot.eval("x100 101D6")
    end
  end
end
