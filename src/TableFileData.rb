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
  
  @@dir = "./extratables"
  @@tableDataCommon = nil
  
  def initialize
    initTableDataCommon
    
    @tableData = Hash.new
    @tableData.merge!( @@tableDataCommon.clone )
  end
  
  def initTableDataCommon
    if( @@tableDataCommon.nil? )
      @@tableDataCommon = searchTableFileDefine(@@dir)
    end
  end
  
  def setDir(dir)
    tableData = searchTableFileDefine(dir)
    @tableData.merge!( tableData )
  end
  
  def searchTableFileDefine(dir)
    tableData = Hash.new
    
    return tableData if( dir.nil? )
    return tableData if( not File.exist?(dir) )
    return tableData if( not File.directory?(dir) )
    
    files = Dir.glob("#{dir}/*.txt")
    
    files.each do |fileName|
      fileName = fileName.untaint
      command, info = readGameCommandInfo(fileName, dir)
      tableData[command] = info
    end
    
    return tableData
  end

  def readGameCommandInfo(fileName, dir)
    fileBase = File.basename(fileName, ".txt")
    
    gameType, command = fileBase.split("_")
    
    if( command.nil? )
      command = gameType
      gameType = ""
    end
    
    
    info = {
      "dir" => dir,
      "gameType" => gameType,
      "command" => command,
    }
    
    debug("readGameCommandInfo info", info)
    
    return command, info
  end
  
  def getGameCommandInfos
    commandInfos = []
    
    @tableData.each do |command, info|
      commandInfo = {
        "gameType" => info['gameType'],
        "command" => info['command']
      }
      
      commandInfos << commandInfo
    end
    
    return commandInfos
  end
  
  
  def readOneTableData(oneTableData)
    return if( oneTableData.nil? )
    return unless( oneTableData["data"].nil? )
    
    dir = oneTableData["dir"]
    command = oneTableData["command"]
    gameType = oneTableData["gameType"]
    return if( command.nil? )
    
    fileName = 
      if( gameType.nil? )
        "#{dir}/#{command}.txt"
      else
        fileName = "#{dir}/#{gameType}_#{command}.txt"
      end
    
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
    debug("getTableData arg", arg)
    debug("getTableData targetGameType", targetGameType)
    
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
    debug("getTableData result oneTableData", oneTableData)
    
    return oneTableData, isSecret
  end
  
  def isTargetGameType(gameType, targetGameType)
    return true if( gameType.empty? )
    return ( gameType == targetGameType )
  end
  
end
