#!/usr/bin/env ruby

# txt形式のテストデータをYAMLに変換するスクリプト

require 'yaml'
require './DiceBotTestData'

def listDataFiles
  Dir.glob('data/*.txt')
end

def parseDataFile(filename)
  gameType = File.basename(filename, '.txt')
  tests = File.open(filename).read.
          gsub("\r\n", "\n").
          tr("\r", "\n").
          split("============================\n").
          map do |testSource, index|
    DiceBotTestData.parse(testSource.chomp, gameType, index)
  end

  return gameType, tests
end

def toHash(test)
  {
    'input' => test.input,
    'output' => test.output,
    'rands' => test.rands,
  }
end

listDataFiles.map do |filename|
  gameType, tests = parseDataFile(filename)
  testHashList = tests.map do |test|
    toHash(test)
  end
  content = YAML.dump('tests' => testHashList, 'gameType' => gameType).
            gsub(/^  - - ([0-9]+)\n    - ([0-9]+)$/) { "  - [#{Regexp.last_match(1)}, #{Regexp.last_match(2)}]" }
  File.open(filename.gsub(/\.txt$/, '.yml'), 'w') do |file|
    file.write(content)
  end
end
