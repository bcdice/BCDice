require "bcdice/randomizer"

class RandomizerMock < BCDice::Randomizer
  def initialize(rands)
    super()
    @rands = rands
  end

  def random(sides)
    dice, expected_sides = @rands.shift

    if dice.nil?
      raise "@rands is empty!"
    elsif sides != expected_sides
      raise "unexpected sides at [#{dice}/#{expected_sides}], side (given #{sides}, expected #{expected_sides})"
    end

    return dice
  end
end
