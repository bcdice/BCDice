#!/perl/bin/ruby -Ku
#--*-coding:utf-8-*--

require 'kconv'
require 'fileutils'
require 'configBcDice.rb'

# extratables ディレクトリに置かれたテーブル定義ファイルを読み込む。
# 詳細はREADME.txtの「７．オリジナルの表追加」を参照。
# 
# 定義ファイルの内容を @tableData として保持する。
# この @tableData は
# 
# @tableData : {
#   コマンド : {
#          :file : (表ファイル名),
#          :title : (表タイトル),
#          :dice : (ダイス文字),
#          :table : {
#            (数値) : (テキスト),
#            (数値) : (テキスト),
#            (数値) : (テキスト),
#          }
#   }
# }
# 
# というデータフォーマットとなる。


class TableFileData
  
  def initialize(isLoadCommonTable = true)
    @tableData = Hash.new
    
    return unless( isLoadCommonTable )
    
    @dir = './extratables'
    @tableData = searchTableFileDefine(@dir)
  end
  
  def setDir(dir, prefix = '')
    tableData = searchTableFileDefine(dir, prefix)
    @tableData.merge!( tableData )
  end
  
  def searchTableFileDefine(dir, prefix = '')
    tableData = Hash.new
    
    return tableData if( dir.nil? )
    return tableData if( not File.exist?(dir) )
    return tableData if( not File.directory?(dir) )
    
    fileNames = Dir.glob("#{dir}/#{prefix}*.txt")
    
    fileNames.each do |fileName|
      fileName = fileName.untaint
      
      info = readGameCommandInfo(fileName, prefix)
      command = info[:command]
      next if(command.empty?)
      
      tableData[command] = info
    end
    
    return tableData
  end
  
  
  def readGameCommandInfo(fileName, prefix)
    info = {
      :fileName => fileName,
      :gameType => '',
      :command => '',
    }
    
    baseName = File.basename(fileName, '.txt')
    
    unless( /^#{prefix}([^_]+)(_(.+))?$/ === baseName )
      return info 
    end
    
    header = $1
    tail = $3
    
    if( tail.nil? )
      info[:gameType] = ''
      info[:command] = header
    else
      info[:gameType] = header
      info[:command] = tail
    end
    
    return info
  end
  
  
  def getAllTableInfo
    result = []
    
    @tableData.each do |key, oneTableData|
      tableData = readOneTableData(oneTableData)
      result << tableData
    end
    
    return result
  end
  
  def getGameCommandInfos
    commandInfos = []
    
    @tableData.each do |command, info|
      commandInfo = {
        :gameType => info[:gameType],
        :command => info[:command],
      }
      
      commandInfos << commandInfo
    end
    
    return commandInfos
  end
  
  
  def getTableDataFromFile(fileName)
    table = []
    lines = splitLines(fileName)
    
    defineLine = lines.shift
    dice, title = getDiceAndTitle(defineLine)
    
    lines.each do |line|
      key, value = getLineKeyValue(line)
      next if( key.empty? )
      
      key = key.to_i
      table << [key, value]
    end
    
    return dice, title, table
  end
  
  def splitLines(fileName)
    buffer = ""
    open(fileName, 'r') do |file|
      buffer = file.read
    end
    
    lines = buffer.split(/(\r\n|\n|\r)/)
    
    return lines
  end
  
  def getLineKeyValue(line)
    self.class.getLineKeyValue(line)
  end
  
  def self.getLineKeyValue(line)
    line = line.toutf8.chomp
    
    if(/^[\s　]*([^:：]+)[\s　]*[:：][\s　]*(.+)/ === line)
      return $1, $2
    end
    
    return '', ''
  end
      
  
  def getDiceAndTitle(line)
    dice, title = getLineKeyValue(line)
    
    return dice, title
  end
  
  
  def getTableData(arg, targetGameType)
    oneTableData = Hash.new
    isSecret = false
    
    @tableData.keys.each do |key|
      next unless(/^(s|S)?#{key}(\s|$)/ === arg)
      
      data = @tableData[key]
      gameType = data[:gameType]
      
      next unless( isTargetGameType(gameType, targetGameType) )
      
      oneTableData = data
      isSecret = (not $1.nil?)
      break
    end
    
    readOneTableData(oneTableData)
    
    dice  = oneTableData[:dice]
    title = oneTableData[:title]
    table = oneTableData[:table]
    
    return dice, title, table, isSecret
  end
  
  def isTargetGameType(gameType, targetGameType)
    return true if( gameType.empty? )
    return ( gameType == targetGameType )
  end
  
  
  def readOneTableData(oneTableData)
    return if( oneTableData.nil? )
    return unless( oneTableData[:table].nil? )
    
    command = oneTableData[:command]
    gameType = oneTableData[:gameType]
    fileName = oneTableData[:fileName]
    
    return if( command.nil? )
    
    return if( not File.exist?(fileName) )
    
    dice, title, table  = getTableDataFromFile(fileName)
    
    oneTableData[:dice] = dice
    oneTableData[:title] = title
    oneTableData[:table] = table
    
    return oneTableData
  end
  
end



class TableFileCreator
  def initialize(dir, prefix, params)
    @dir = dir
    @prefix = prefix
    @params = params
  end
  
  def execute
    fileName = getTableFileName()
    checkFile(fileName)
    
    text = getTableText()
    
    createFile(fileName, text)
  end
  
  def checkFile(fileName)
    checkFileNotExist(fileName)
  end
  
  def checkFileNotExist(fileName)
    raise "table already exist!" if( File.exist?(fileName) )
  end
  
  def checkFileExist(fileName)
    raise "table is NOT exist!" unless( File.exist?(fileName) )
  end
  
  
  def getTableFileName(command = nil)
    gameType = @params['gameType']
    gameType ||= ''
    
    if( command.nil? )
      initCommand
      command = @command
    end
    
    checkCommand(command)
    
    if( gameType.empty? )
      return "#{@dir}/#{@prefix}#{command}.txt"
    end
    
    return "#{@dir}/#{@prefix}#{gameType}_#{command}.txt"
  end

  def initCommand
    @command = @params['command']
    @command ||= ''
  end
  
  def checkCommand(command)
    raise "command is empty" if( command.empty? )
    
    unless( /^[a-zA-Z\d]+$/ === command )
      raise "コマンド名には英数字のみ使用できます"
    end
  end
  
  def getTableText()
    dice = @params['dice']
    title = @params['title']
    table = @params['table']
    
    text = ""
    text << "#{dice}:#{title}\n"
    
    table = getFormatedTableText(table)
    
    text << table
  end
  
  def getFormatedTableText(table)
    result = ""
    
    table.each_with_index do |line, index|
      key, value = TableFileData.getLineKeyValue(line)
      
      key.tr!('　', '')
      key.tr!(' ', '')
      key.tr!('０-９', '0-9')
      key = checkTableKey(key, index)
      
      result << "#{key}:#{value}\n".toutf8
    end
    
    return result
  end
  
  def checkTableKey(key, index)
    return if( key == "0" )
    
    keyValue = key.to_i
    
    if( keyValue == 0 )
      raise "#{index + 1}行目の表記(#{key}〜)は「数字:文字列」になっていません。"
    end
    
    return keyValue
  end
  
  def createFile(fileName, text)
    open(fileName, "w+") do |file|
      file.write(text)
    end
  end
  
end



class TableFileEditer < TableFileCreator
  
  def checkFile(fileName)
    @originalCommand = @params['originalCommand']
    
    if( @originalCommand == @command )
      checkFileWhenCommandNotChanged(fileName)
    else
      checkFileWhenCommandChanged(fileName)
    end
  end
  
  
  def checkFileWhenCommandNotChanged(fileName)
    checkFileExist(fileName)
  end
  
  
  def checkFileWhenCommandChanged(fileName)
    originalFileName = getTableFileName(@originalCommand)
    checkFileExist(originalFileName)
    
    checkFileNotExist(fileName)
    
    begin
      FileUtils.mv(originalFileName, fileName)
    rescue => e
      raise "change command name faild(file move error)"
    end
  end
  
  
end
