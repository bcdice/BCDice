# -*- coding: utf-8 -*-

require 'bcdiceCore'
require 'bcdice/game_system/DiceBotLoader'
require 'DiceBotTestData'

class DiceBotTest
  def initialize(testDataPath = nil, dataIndex = nil)
    testBaseDir = File.expand_path(File.dirname(__FILE__))

    @testDataPath = testDataPath
    @dataIndex = dataIndex

    @dataDir = "#{testBaseDir}/data"
    @tableDir = "#{testBaseDir}/../../extratables"

    @testDataSet = []
    @errorLog = []

    $isDebug = !@dataIndex.nil?
  end

  # テストを実行する
  # @return [true] テストを実行できたとき
  # @return [false] テストに失敗した、あるいは実行できなかったとき
  def execute
    readTestDataSet

    if @testDataSet.empty?
      warn('No matched test data!')
      return false
    end

    doTests

    if @errorLog.empty?
      # テスト成功
      puts('OK.')

      true
    else
      puts('[Failures]')
      puts(@errorLog.join("\n===========================\n"))

      false
    end
  end

  # テストデータを読み込む
  def readTestDataSet
    if @testDataPath
      # 指定されたファイルが存在しない場合、中断する
      return unless File.exist?(@testDataPath)

      targetFiles = [@testDataPath]
    else
      # すべてのテストデータを読み込む
      targetFiles = Dir.glob("#{@dataDir}/*.txt")
    end

    targetFiles.each do |filename|
      next if /^_/ === File.basename(filename)

      source = File.read(filename, :encoding => 'UTF-8')

      dataSetSources = source.
                       gsub("\r\n", "\n").
                       tr("\r", "\n").
                       split("============================\n").
                       map(&:chomp)

      # ゲームシステムをファイル名から判断する
      gameType = File.basename(filename, '.txt')

      dataSet =
        dataSetSources.map.with_index(1) do |dataSetSource, i|
          DiceBotTestData.parse(dataSetSource, gameType, i)
        end

      @testDataSet +=
        if @dataIndex.nil?
          dataSet
        else
          dataSet.select { |data| data.index == @dataIndex }
        end
    end
  end

  private :readTestDataSet

  # 各テストを実行する
  def doTests
    @testDataSet.each do |testData|
      begin
        result = executeCommand(testData).lstrip

        unless result == testData.output
          @errorLog << logTextForUnexpected(result, testData)
          print('X')

          # テスト失敗、次へ
          next
        end
      rescue StandardError => e
        @errorLog << logTextForException(e, testData)
        print('E')

        # テスト失敗、次へ
        next
      end

      # テスト成功
      print('.')
    end

    puts
  end

  # ダイスコマンドを実行する
  def executeCommand(testData)
    rands = testData.rands
    @bot = load_dicebot(testData.gameType)
    @bot.bcdice.setRandomValues(rands)
    @bot.bcdice.setTest(true)

    result = ''
    testData.input.each do |message|
      result += @bot.eval(message)
    end

    unless rands.empty?
      result += "\nダイス残り："
      result += rands.map { |r| r.join('/') }.join(', ')
    end

    result
  end

  def load_dicebot(game_system)
    loader = DiceBotLoaderList.find(game_system)

    if loader
      loader.loadDiceBot
    else
      DiceBotLoader.loadUnknownGame(game_system) || DiceBot.new
    end
  end

  # 期待された出力と異なる場合のログ文字列を返す
  def logTextForUnexpected(result, data)
    logText = <<EOS
Game type: #{data.gameType}
Index: #{data.index}
Input:
#{indent(data.input)}
Expected:
#{indent(data.output)}
Result:
#{indent(result)}
Rands: #{data.randsText}
EOS

    logText.chomp
  end
  private :logTextForUnexpected

  # 例外が発生した場合のログ文字列を返す
  def logTextForException(e, data)
    logText = <<EOS
Game type: #{data.gameType}
Index: #{data.index}
Exception: #{e.message}
Backtrace:
#{indent(e.backtrace)}
Input:
#{indent(data.input)}
Expected:
#{indent(data.output)}
Rands: #{data.randsText}
EOS

    logText.chomp
  end
  private :logTextForException

  # インデントした結果を返す
  def indent(s)
    target =
      if s.is_a?(Array)
        s
      elsif s.is_a?(String)
        s.lines
      else
        raise TypeError
      end

    target.map { |line| "  #{line.chomp}" }.join("\n")
  end
  private :indent
end
