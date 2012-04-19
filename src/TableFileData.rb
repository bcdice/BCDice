#!/perl/bin/ruby -Ku
#--*-coding:utf-8-*--

require 'configBcDice.rb'

# extratables ディレクトリに置かれたテーブル定義ファイルを読み込む。
# 詳細はREADME.txtの「７．オリジナルの表追加」を参照。
# 
# 定義ファイルの内容を @tableData として保持する。
# この @tableData は
# 
# @tableData : {
#   コマンド : {
#          "dice" : (実際のダイス),
#          "file" : (ファイル名),
#          "data" : {
#            (数値) : (テキスト),
#            (数値) : (テキスト),
#            (数値) : (テキスト),
#          }
#   }
# }
# 
# というデータフォーマットとなる。


class TableFileData
  
  def initialize
    @tableData = Hash.new
    @dir = "./extratables"
    
    readFiles()
  end
  
  def readFiles
    searchTableFileDefine
    return  if( @tableData.empty? )
  end
  
  def searchTableFileDefine
    return if( not File.exist?(@dir) )
    return if( not File.directory?(@dir) )
    
    files = Dir.glob("#{@dir}/*.txt")
    
    files.each do |fileName|
      command, info = readGameCommandInfo(fileName)
      @tableData[command] = info
    end
  end
  
  def readGameCommandInfo(fileName)
    fileBase = File.basename(fileName, ".txt")
    
    gameType, command = fileBase.split("_")
    
    if( command.nil? )
      command = gameType
      gameType = ""
    end
    
    info = {
      "gameType" => gameType,
      "command" => command,
    }
    
    return command, info
  end
  
  
  def readOneTableData(oneTableData)
    return if( oneTableData.nil? )
    return unless( oneTableData["data"].nil? )
    
    command = oneTableData["command"]
    return if( command.nil? )
    
    fileName = "#{@dir}/#{command}.txt"
    debug("readOneTableData fileName", fileName)
    return if( not File.exist?(fileName) )
    
    debug("file exist!")
    
    dice, title, data  = getTableDataFromFile(fileName)
    
    oneTableData["dice"] = dice
    oneTableData["title"] = title
    oneTableData["data"] = data
  end
  
  def getTableDataFromFile(fileName)
    debug("getTableDataFromFile Begin")
    
    data = Hash.new
    lines = File.readlines(fileName)
    
    defineLine = lines.shift
    dice, title = getDiceAndTitle(defineLine)
    
    lines.each do |line|
      key, value = getLineKeyValue(line)
      next if( key.empty? )
      
      key = key.to_i
      data[key] = value
    end
    
    debug("dice", dice)
    debug("title", title)
    debug("data", data)
    debug("getTableDataFromFile End")
    
    return dice, title, data
  end
  
  def getLineKeyValue(line)
    if(/^[\s　]*([^:：]+)[\s　]*[:：][\s　]*(.+)/ === line)
      return $1, $2
    end
    
    return "", ""
  end
      
  
  def getDiceAndTitle(line)
    dice, title = getLineKeyValue(line)
    
    return dice, title
  end
  
  
  def getTableData(arg, targetGameType)
    oneTableData = nil
    isSecret = false
    
    @tableData.keys.each do |key|
      next unless(/^(s|S)?#{key}(\s|$)/ === arg)
      debug("arg match with", key)
      
      data = @tableData[key]
      gameType = data["gameType"]
      
      next unless( isTargetGameType(gameType, targetGameType) )
      
      oneTableData = data
      isSecret = (not $1.nil?)
      break
    end
    
    readOneTableData(oneTableData)
    debug("oneTableData", oneTableData)
    
    return oneTableData, isSecret
  end
  
  def isTargetGameType(gameType, targetGameType)
    return true if( gameType.empty? )
    return ( gameType == targetGameType )
  end
  
end
