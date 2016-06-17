# -*- coding: utf-8 -*-

class OneWayHeroics < DiceBot
  
  def initialize
    super
    @d66Type = 2        #d66の差し替え(0=D66無し, 1=順番そのまま([5,3]->53), 2=昇順入れ替え([5,3]->35)
  end
  
  
  def prefixs
    ['JD.*'] + @@tables.keys
  end
  
  def gameName
    '片道勇者'
  end
  
  def gameType
    "OneWayHeroics"
  end
  
  def getHelpMessage
    return <<MESSAGETEXT
・判定　JDx+y,z
　x:能力値、y:修正値（省略可。「＋」のみなら＋１）、z:目標値、
　例１）JD2+1,8 or JD2+,8　：能力値２、修正＋１、目標値８
　例２）JD3,10 能力値３、修正なし、目標値10
・ファンブル表 FT
・魔王追撃表   DC
・進行ルート表 PR
・会話テーマ表 TT
・逃走判定表   EC
MESSAGETEXT
  end
  
  def rollDiceCommand(command)
    debug("rollDiceCommand command", command)
    
    text = judgeDice(command)
    return text unless text.nil?
    
    info = @@tables[command.upcase]
    return nil if info.nil?
    
    name = info[:name]
    type = info[:type]
    table = info[:table]
    
    number, text = 
      case type
      when '1D6'
        dice, = roll(1, 6)
        getTableResult(table, dice)
      else
        nil
      end
    
    return nil if( text.nil? )
    
    return "#{name}(#{number}) ＞ #{text}"
  end
  
  
  def judgeDice(command)
    return nil unless /^JD(\d*)(\+(\d*))?,(\d+)$/ === command
    
    ability = $1.to_i
    target = $4.to_i
    
    modifyText = ($2 || "")
    modifyText = "+1" if modifyText == "+" 
    modifyValue = modifyText.to_i
    
    dice, diceText, = roll(2, 6)
    total = dice + ability + modifyValue
    
    text = "#{command}"
    text += " ＞ 2D6[#{diceText}]+#{ability}#{modifyText}"
    text += " ＞ #{total}"
    
    result = getJudgeReusltText(dice, total, target)
    text += " ＞ #{result}"
    
    return text
  end
  
  def getJudgeReusltText(dice, total, target)
    return "ファンブル" if dice == 2
    return "クリティカル" if dice == 12
    
    return "成功" if total >= target
    return "失敗"
  end
      
  
  def getTableResult(table, dice)
    number, text, command = table.assoc(dice)
    
    text += eval(command) unless command.nil?
    
    return number, text
  end
      
  
  def getLossGoldText(diceCount, times)
    total, diceText = roll(diceCount, 6)
    gold = total * times
    
    return " ＞ #{diceCount}D6[#{diceText}]×#{times} ＞ 【所持金】 #{gold} を失う"
  end
  
  def getDownText(name, diceCount)
    total, diceText = roll(diceCount, 6)
    
    return " ＞ #{diceCount}D6[#{diceText}] ＞ #{name}が #{total} 減少する"
  end
  
  
  @@tables =
    {
    "FT" => {
      :name => "ファンブル表",
      :type => '1D6',
      :table => 
      [
       [1, "装備以外のアイテムのうちプレイヤー指定の１つを失う"],
       [2, "装備のうちプレイヤー指定の１つを失う"],
       [3, "１Ｄ６に１００を掛け、それだけの【所持金】を失う", 'getLossGoldText(1, 100)'],
       [4, "１Ｄ６に１００を掛け、それだけの【所持金】を拾う", 'getLossGoldText(1, 100)'],
       [5, "【経験値】２を獲得する"],
       [6, "【経験値】４を獲得する"],
      ],},
    
    "DC" => {
      :name => "魔王追撃表",
      :type => '1D6',
      :table => 
      [[1, "装備以外のアイテムのうちＧＭ指定の１つを失う"],
       [2, "装備のうちＧＭ指定の１つを失う"],
       [3, "２Ｄ６に１００を掛け、それだけの【所持金】を失う", 'getLossGoldText(2, 100)'],
       [4, "【ＬＩＦＥ】が１Ｄ６減少する", 'getDownText("【ＬＩＦＥ】", 1)'],
       [5, "【ＳＴ】が１Ｄ６減少する", 'getDownText("【ＳＴ】", 1)'],
       [6, "【ＬＩＦＥ】が２Ｄ６減少する", 'getDownText("【ＬＩＦＥ】", 2)'],
      ],},
    
    "PR" => {
      :name => "進行ルート表",
      :type => '1D6',
      :table => 
      [[1, "少し荒れた地形が続く。【日数】から【筋力】を引いただけ【ＳＴ】が減少する（最低０）。"],
       [2, "穏やかな地形が続く。【日数】から【敏捷】を引いただけ【ＳＴ】が減少する（最低０）。"],
       [3, "険しい岩山だ。【日数】に１を足して【生命】を引いただけ【ＳＴ】が減少する（最低０）。「登山」"],
       [4, "山で迷った。【日数】に２を足して【知力】を引いただけ【ＳＴ】が減少する（最低０）。「登山」"],
       [5, "川を泳ぐ。【日数】に１を足して【意志】を引いただけ【ＳＴ】が減少する（最低０）。「水泳」"],
       [6, "広い川を船で渡る。【日数】に２を足して【魅力】を引いただけ【ＳＴ】が減少する（最低０）。「水泳」"],
      ],},
    
    "TT" => {
      :name => "会話テーマ表",
      :type => '1D6',
      :table => 
      [[1, "身体の悩みごとについて話す。【筋力】で判定。"],
       [2, "仕事の悩みごとについて話す。【敏捷】で判定。"],
       [3, "家族の悩みごとについて話す。【生命】で判定。"],
       [4, "勇者としてこれでいいのか的悩みごとを話す。【知力】で判定。"],
       [5, "友人関係の悩みごとを話す。【意志】で判定。"],
       [6, "恋の悩みごとを話す。【魅力】で判定。"],
      ],},
    
    "EC" => {
      :name => "逃走判定表",
      :type => '1D6',
      :table => 
      [[1, "崖を登れば逃げられそうだ。【筋力】を使用する。"],
       [2, "障害物はない。走るしかない。【敏捷】を使用する。"],
       [3, "しつこく追われる。【生命】を使用する。"],
       [4, "隠れられる地形がある。【知力】を使用する。"],
       [5, "背中を向ける勇気が出るか？　【意志】を使用す"],
       [6, "もう人徳しか頼れない。【魅力】を使用する。"],
      ],},
    
  }
  
end
