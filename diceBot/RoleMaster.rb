#--*-coding:utf-8-*--

class RoleMaster < DiceBot

  def initialize
    super
    @upplerRollThreshold = 96;
    @unlimitedRollDiceType = 100;
  end
  
  def gameType
    "RoleMaster"
  end
  
end
