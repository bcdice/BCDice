#--*-coding:utf-8-*--

class ShadowRun < DiceBot

  def initialize
    super
    @sortType = 3;
    @upplerRollThreshold = 6;
    @unlimitedRollDiceType = 6;
  end
  
  def gameType
    "ShadowRun"
  end
  
end
