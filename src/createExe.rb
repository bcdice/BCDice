#!/bin/ruby -Ku 
#--*-coding:utf-8-*--

require 'fileutils'

$LOAD_PATH << File.dirname(__FILE__) # require_relative対策

def updateConfig
  ignoreBotNames = ['DiceBot', 'DiceBotLoader', 'baseBot', '_Template', 'test']

  require 'diceBot/DiceBot'
  
  botFiles = Dir.glob("diceBot/*.rb")
  
  botNames = botFiles.collect{|i| File.basename(i, ".rb").untaint}
  botNames.delete_if{|i| ignoreBotNames.include?(i) }
  
  nameList = []
  botNames.each do |botName|
    require "diceBot/#{botName}"
    diceBot = Module.const_get(botName).new
    nameList << diceBot.gameType.gsub(/ /, '_')
  end
  
  nameList.sort!
  
  writeToConfig(nameList)
end


def writeToConfig(nameList)
  fileName = 'configBcDice.rb'
  text = File.readlines(fileName).join
  
  text.gsub!(/\$allGameTypes = \%w\{.+\}/m) do
    "$allGameTypes = %w{\n" + nameList.join("\n") + "\n}"
  end
  
  open(fileName, "wb+") do |file|
    file.write(text)
  end
  
end



updateConfig

# EXEファイルをocraでコンパイルする時用に
# __createExe__.txt という名前で一時ファイルを用意しておく。
# 
# B&C はこのファイルがある場合には全ダイスボットを読み込んで自動的に終了する。
# こうしないと、EXEの中に全ダイスボットの情報が出力されないため。
# 
# exerb では exerb bcdice.rb createExe のように
# createExe という引数を渡すことで上記の全ダイスボット読み込みモードで起動させていたが、
# ocra ではEXEコンパイル時に渡した引数は EXE 起動時にも強制的に付与されるため、
# 一時ファイルを作ることでコンパイル時かどうかを区別しています。
# 
compileMarkerFile = "__createExe__.txt"
File.open(compileMarkerFile, "w+") {|f| f.write("")}

`ocra bcdice.rb -- createExe`
sleep 2
FileUtils.move('bcdice.exe', '..')

FileUtils.remove(compileMarkerFile)
