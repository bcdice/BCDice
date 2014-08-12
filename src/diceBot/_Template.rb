#--*-coding:utf-8-*--

class _Template < DiceBot
  
  def initialize
    super
    
    # @d66Type = 0;        #d66の差し替え(0=D66無し, 1=順番そのまま([5,3]->53), 2=昇順入れ替え([5,3]->35)
  end
  
  
  def prefixs
    #ダイスボットで使用するコマンドを配列で列挙すること。
    []
  end
  
  
  def gameName
    'ゲーム名'
  end
  
  def gameType
    "GameType"
  end
  
  
  def getHelpMessage
    return <<MESSAGETEXT
ダイスボットの使い方をここに書きます
MESSAGETEXT
  end
  
  
  
  def rollDiceCommand(command)
    ''
  end
  
  
  
  #以下のメソッドはテーブルの参照用に便利
  #get_table_by_nD6(table, count)
  #get_table_by_number(index, table)
  #get_table_by_d66(table)
  
  #getDiceList を呼び出すとロース結果のダイス目の配列が手に入ります。
  
end
