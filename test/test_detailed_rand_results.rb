# -*- coding: utf-8 -*-

require 'test/unit'
require 'bcdice'
require 'bcdice/randomizer'

# ダイスロール結果詳細のテストケース
# 10の位用にダイスロールした場合などの確認
class TestDetailedRandResults < Test::Unit::TestCase
  def setup
    @randomier = BCDice::Randomizer.new
  end

  def test_rand
    @randomier.setRandomValues([[49, 100]])

    value = @randomier.rand(100)

    assert_equal(49 - 1, value)

    assert_equal(1, @randomier.detailed_rand_results.size)
    assert_equal(:normal, @randomier.detailed_rand_results[0].kind)
    assert_equal(100, @randomier.detailed_rand_results[0].sides)
    assert_equal(49, @randomier.detailed_rand_results[0].value)

    assert_equal(1, @randomier.rand_results.size)
    assert_equal(100, @randomier.rand_results[0][1])
    assert_equal(49, @randomier.rand_results[0][0])
  end

  def test_tens_d10
    @randomier.setRandomValues([[3, 10]])
    value = @randomier.roll_tens_d10()

    assert_equal(30, value)

    assert_equal(1, @randomier.detailed_rand_results.size)
    assert_equal(:tens_d10, @randomier.detailed_rand_results[0].kind)
    assert_equal(10, @randomier.detailed_rand_results[0].sides)
    assert_equal(30, @randomier.detailed_rand_results[0].value)

    assert_equal(1, @randomier.rand_results.size)
    assert_equal(10, @randomier.rand_results[0][1])
    assert_equal(3, @randomier.rand_results[0][0])
  end

  def test_tens_d10_zero
    @randomier.setRandomValues([[10, 10]])
    value = @randomier.roll_tens_d10()

    assert_equal(0, value)
    assert_equal(0, @randomier.detailed_rand_results[0].value)
    assert_equal(10, @randomier.rand_results[0][0])
  end

  def test_d9
    @randomier.setRandomValues([[3, 10]])
    value = @randomier.roll_d9()

    assert_equal(2, value)

    assert_equal(1, @randomier.detailed_rand_results.size)
    assert_equal(:d9, @randomier.detailed_rand_results[0].kind)
    assert_equal(10, @randomier.detailed_rand_results[0].sides)
    assert_equal(2, @randomier.detailed_rand_results[0].value)

    assert_equal(1, @randomier.rand_results.size)
    assert_equal(10, @randomier.rand_results[0][1])
    assert_equal(3, @randomier.rand_results[0][0])
  end

  def test_coc7th
    dicebot = DiceBotLoader.loadUnknownGame("Cthulhu7th")
    dicebot.randomizer.setRandomValues([[5, 10], [6, 10], [7, 10], [4, 10]])
    dicebot.eval("CC(2)")

    details = dicebot.randomizer.detailed_rand_results
    assert_equal(4, details.size)

    assert_equal(:tens_d10, details[0].kind)
    assert_equal(10, details[0].sides)
    assert_equal(50, details[0].value)

    assert_equal(:tens_d10, details[1].kind)
    assert_equal(10, details[1].sides)
    assert_equal(60, details[1].value)

    assert_equal(:tens_d10, details[2].kind)
    assert_equal(10, details[2].sides)
    assert_equal(70, details[2].value)

    assert_equal(:normal, details[3].kind)
    assert_equal(10, details[3].sides)
    assert_equal(4, details[3].value)
  end
end
