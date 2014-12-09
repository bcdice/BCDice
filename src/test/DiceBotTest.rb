#--*-coding:utf-8-*--

require 'bcdiceCore'
require 'diceBot/DiceBotLoader'
require 'cgiDiceBot'
require 'DiceBotTestData'

class DiceBotTest
  def initialize(gameType = nil, dataIndex = nil)
    testBaseDir = File.expand_path(File.dirname(__FILE__))

    @gameType = gameType
    @dataIndex = dataIndex

    @dataDir = "#{testBaseDir}/data"
    @tableDir = "#{testBaseDir}/../../extratables"
    src_bcdice = "#{testBaseDir}/../../src_bcdice"
    DiceBotLoader.setBcDicePath(
      File.directory?(src_bcdice) ? src_bcdice : "#{testBaseDir}/../../src"
    )
    @bot = CgiDiceBot.new

    @testDataSet = []
    @errorLog = []

    $isDebug = !!@dataIndex
  end

  # テストを実行する
  # @return [true] テストを実行できたとき
  # @return [false] テストを実行できなかったとき
  def execute
    readTestDataSet

    if @testDataSet.empty?
      $stderr.puts('No matched test data!')
      return false
    end

    doTests

    puts
    if @errorLog.empty?
      puts('OK.')
    else
      if /mswin(?!ce)|mingw|cygwin|bccwin/ === RUBY_PLATFORM.downcase
        @errorLog.map!(&:tosjis)
      end

      puts('[Failures]')
      puts(@errorLog.join("\n===========================\n"))
    end

    true
  end

  # テストデータを読み込む
  def readTestDataSet
    if @gameType
      # ゲームシステムが指定された場合、そのテストデータを読み込む
      testDataPath = "#{@dataDir}/#{@gameType}.txt"
      # ゲームシステム名に対応するテストデータファイルが存在しない場合
      # 中断する
      return unless File.exist?(testDataPath)

      targetFiles = [testDataPath]
    else
      # すべてのテストデータを読み込む
      targetFiles = Dir.glob("#{@dataDir}/*.txt")
    end

    targetFiles.each do |filename|
      dataSetSources = File.read(filename, encoding: 'UTF-8').
        gsub("\r\n", "\n").
        tr("\r", "\n").
        split("============================\n").
        map(&:chomp)

      gameTypeLine = dataSetSources.shift || ''
      matches = gameTypeLine.match(/^gametype:(.+)/)
      raise "missing gametype: #{filename}" unless matches
      gameType = matches[1]

      dataSet = dataSetSources.map.with_index(1) do |dataSetSource, i|
        DiceBotTestData.parse(dataSetSource, gameType, i)
      end

      dataSet.select! { |data| data.index == @dataIndex } if @dataIndex

      @testDataSet += dataSet
    end
  end
  private :readTestDataSet

  # 各テストを実行する
  def doTests
    @testDataSet.each do |testData|
      success = true
      begin
        result = executeCommand(testData).lstrip

        unless result == testData.output
          success = false
          @errorLog << logTextForUnexpected(result, testData)
          print('X')
        end
      rescue => e
        success = false
        @errorLog << logTextForException(e, testData)
        print('E')
      end

      print('.') if success
    end

    puts
  end

  # ダイスコマンドを実行する
  def executeCommand(testData)
    rands = testData.rands
    @bot.setRandomValues(rands)
    @bot.setTest

    result = ''
    testData.input.each do |message|
      result << @bot.roll(message, testData.gameType, @tableDir).first
    end

    unless rands.empty?
      result << "\nダイス残り："
      result << rands.map { |r| r.join('/') }.join(', ')
    end

    result
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
      if s.kind_of?(Array)
        s
      elsif s.kind_of?(String)
        s.lines
      else
        raise TypeError
      end

    target.map { |line| "  #{line.chomp}" }.join("\n")
  end
  private :indent
end
