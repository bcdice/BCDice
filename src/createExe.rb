require 'fileutils'


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
  
  print text
  
  open(fileName, "wb+") do |file|
    file.write(text)
  end
  
end


updateConfig

`ruby -Ku -r exerb/mkexy bcdice.rb exerb`
sleep 2
`call exerb  -c gui bcdice.exy`
sleep 2
FileUtils.move('bcdice.exe', '..')


