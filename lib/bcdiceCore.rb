#!/bin/ruby -Ku
# -*- coding: utf-8 -*-

require 'log'
require 'configBcDice.rb'
require 'utils/ArithmeticEvaluator.rb'

require 'bcdice/game_system/DiceBot'
require 'bcdice/game_system/DiceBotLoader'
require 'bcdice/game_system/DiceBotLoaderList'
require 'bcdice/common_command'

class BCDiceMaker
  def initialize
    @diceBot = DiceBot.new
  end

  # @todo 未使用のため削除する
  attr_accessor :diceBotPath

  def newBcDice
    bcdice = BCDice.new(@diceBot)

    return bcdice
  end
end

class BCDice
  # BCDiceのバージョン番号
  VERSION = "3.0.0-alpha".freeze

  # @return [DiceBot] 使用するダイスボット
  attr_reader :diceBot

  # @return [Array<(Integer, Integer)>] 出目の配列
  attr_reader :rand_results

  alias getRandResults rand_results

  # @return [Array<DetailedRandResult>] 出目の詳細の配列
  attr_reader :detailed_rand_results

  # @return [String] メッセージ送信者のニックネーム
  attr_reader :nick_e

  def initialize(diceBot)
    setDiceBot(diceBot)

    @nick_e = ""
    @tnick = ""
    @rands = nil
    @isKeepSecretDice = true

    @collect_rand_results = false
    @rand_results = []
    @detailed_rand_results = []
  end

  # @deprecated {#diceBot} からゲームシステムIDを得るようにする。
  def getGameType
    @diceBot.id
  end

  def setDiceBot(diceBot)
    return if  diceBot.nil?

    @diceBot = diceBot
  end

  def setMessage(message)
    # 設定で変化し得るためopen系はここで正規表現を作る
    openPattern = /\A\s*(?:#{$OPEN_DICE}|#{$OPEN_PLOT})\s*\z/i

    messageToSet =
      case message
      when openPattern
        message
      else
        # 空白が含まれる場合、最初の部分だけを取り出す
        message.split(/\s/, 2).first
      end
    debug("setMessage messageToSet", messageToSet)

    @messageOriginal = parren_killer(messageToSet)
    @message = @messageOriginal.upcase
    debug("@message", @message)
  end

  def getOriginalMessage
    @messageOriginal
  end

  # 直接TALKでは大文字小文字を考慮したいのでここでオリジナルの文字列に変更
  def changeMessageOriginal
    @message = @messageOriginal
  end

  def setTest(isTest)
    @isTest = isTest
  end

  ###########################################################################
  # **                         各種コマンド処理
  ###########################################################################

  #=========================================================================
  # **                           コマンド分岐
  #=========================================================================
  def dice_command # ダイスコマンドの分岐処理
    arg = @message.upcase

    debug('dice_command arg', arg)

    output, secret = @diceBot.dice_command(@message, @nick_e)
    return output, secret if output != '1'

    output, secret = CommonCommand.eval(arg, self, @diceBot)
    return output, secret unless output.nil?

    output = '1'
    secret = false
    return output, secret
  end

  def getTableIndexDiceValueAndDiceText(dice)
    if /(\d+)D(\d+)/i === dice
      diceCount = Regexp.last_match(1)
      diceType = Regexp.last_match(2)
      value, diceText = roll(diceCount, diceType)
      return value, diceText
    end

    string, _secret, _count, swapMarker = getD66Infos(dice)
    unless  string.nil?
      value = getD66ValueByMarker(swapMarker)
      diceText = (value / 10).to_s + "," + (value % 10).to_s
      return value, diceText
    end

    return nil
  end

  def rollTableMessageDiceText(text)
    message = text.gsub(/(\d+)D(\d+)/) do
      m = $~
      diceCount = m[1]
      diceMax = m[2]
      value, = roll(diceCount, diceMax)
      "#{diceCount}D#{diceMax}(=>#{value})"
    end

    return message
  end

  #=========================================================================
  # **                           ランダマイザ
  #=========================================================================
  # ダイスロール
  def roll(dice_cnt, dice_max, dice_sort = 0)
    dice_cnt = dice_cnt.to_i
    dice_max = dice_max.to_i

    total = 0
    dice_str = ""
    numberSpot1 = 0
    cnt_max = 0
    n_max = 0
    cnt_suc = 0
    d9_on = false
    rerollCount = 0

    unless (dice_cnt <= $DICE_MAXCNT) && (dice_max <= $DICE_MAXNUM)
      return total, dice_str, numberSpot1, cnt_max, n_max, cnt_suc, rerollCount
    end

    dice_list = Array.new(dice_cnt) { rand(dice_max) + 1 }
    if dice_sort != 0
      dice_list.sort!
    end

    total = dice_list.sum()
    dice_str = dice_list.join(",")
    numberSpot1 = dice_list.count(1)
    cnt_max = dice_list.count(dice_max)
    n_max = dice_list.max()

    return total, dice_str, numberSpot1, cnt_max, n_max, 0, 0
  end

  def setRandomValues(rands)
    @rands = rands
  end

  # @params [Integer] max
  # @return [Integer] 0以上max未満の整数
  def rand_inner(max)
    debug('rand called @rands', @rands)

    value = 0
    if @rands.nil?
      value = randNomal(max)
    else
      value = randFromRands(max)
    end

    if @collect_rand_results
      @rand_results << [(value + 1), max]
    end

    return value
  end

  DetailedRandResult = Struct.new(:kind, :sides, :value)

  # @params [Integer] max
  # @return [Integer] 0以上max未満の整数
  def rand(max)
    ret = rand_inner(max)

    push_to_detail(:normal, max, ret + 1)
    return ret
  end

  # 十の位をd10を使って決定するためのダイスロール
  # @return [Integer] 0以上90以下で10の倍数となる整数
  def roll_tens_d10()
    # rand_innerの戻り値を10倍すればすむ話なのだが、既存のテストとの互換性の為に処理をする
    r = rand_inner(10) + 1
    if r == 10
      r = 0
    end

    ret = r * 10

    push_to_detail(:tens_d10, 10, ret)
    return ret
  end

  # d10を0~9として扱うダイスロール
  # @return [Integer] 0以上9以下の整数
  def roll_d9()
    ret = rand_inner(10)

    push_to_detail(:d9, 10, ret)
    return ret
  end

  # @param b [Boolean]
  def setCollectRandResult(b)
    @collect_rand_results = b
    @rand_results = []
    @detailed_rand_results = []
  end

  # @params [Symbol] kind
  # @params [Integer] sides
  # @params [Integer] value
  def push_to_detail(kind, sides, value)
    if @collect_rand_results
      detail = DetailedRandResult.new(kind, sides, value)
      @detailed_rand_results.push(detail)
    end
  end

  def randNomal(max)
    Kernel.rand(max)
  end

  def randFromRands(targetMax)
    nextRand = @rands.shift

    if nextRand.nil?
      # return randNomal(targetMax)
      raise "nextRand is nil, so @rands is empty!! @rands:#{@rands.inspect}"
    end

    value, max = nextRand
    value = value.to_i
    max = max.to_i

    if  max != targetMax
      # return randNomal(targetMax)
      raise "invalid max value! [ #{value} / #{max} ] but NEED [ #{targetMax} ] dice"
    end

    return (value - 1)
  end

  def dice_num(dice_str)
    dice_str = dice_str.to_s
    return dice_str.sub(/\[[\d,]+\]/, '').to_i
  end

  #==========================================================================
  # **                            ダイスコマンド処理
  #==========================================================================

  ####################         バラバラダイス       ########################
  def bdice(command)
    dice = BCDice::CommonCommand::BarabaraDice.new(command, self, @diceBot)
    return dice.eval()
  end

  ####################             D66ダイス        ########################
  def getD66Value(mode = nil)
    mode ||= @diceBot.d66Type

    isSwap = (mode > 1)
    getD66(isSwap)
  end

  def getD66(isSwap)
    output = 0

    dice_a = rand(6) + 1
    dice_b = rand(6) + 1
    debug("dice_a", dice_a)
    debug("dice_b", dice_b)

    if isSwap && (dice_a > dice_b)
      # 大小でスワップするタイプ
      output = dice_a + dice_b * 10
    else
      # 出目そのまま
      output = dice_a * 10 + dice_b
    end

    debug("output", output)

    return output
  end

  def getNick(nick = nil)
    nick ||= @nick_e
    nick = nick.upcase

    if /[_\d]*(.+)[_\d]*/ =~ nick
      nick = Regexp.last_match(1) # Nick端の数字はカウンター変わりに使われることが多いので除去
    end

    return nick
  end

  #==========================================================================
  # **                            結果判定関連
  #==========================================================================

  def check_hit(dice_now, signOfInequality, diff) # 成功数判定用
    suc = 0

    if  diff.is_a?(String)
      unless /\d/ =~ diff
        return suc
      end

      diff = diff.to_i
    end

    case signOfInequality
    when /(<=|=<)/
      if dice_now <= diff
        suc += 1
      end
    when /(>=|=>)/
      if dice_now >= diff
        suc += 1
      end
    when /(<>)/
      if dice_now != diff
        suc += 1
      end
    when /[<]+/
      if dice_now < diff
        suc += 1
      end
    when /[>]+/
      if dice_now > diff
        suc += 1
      end
    when /[=]+/
      if dice_now == diff
        suc += 1
      end
    end

    return suc
  end

  ####################         テキスト前処理        ########################
  def parren_killer(string)
    debug("parren_killer input", string)

    string = string.gsub(/\[\d+D\d+\]/i) do |matched|
      # Remove '[' and ']'
      command = matched[1..-2].upcase
      times, sides = command.split("D").map(&:to_i)
      rolled, = roll(times, sides)

      rolled
    end

    string = changeRangeTextToNumberText(string)

    round_type = @diceBot.fractionType.to_sym
    string = string.gsub(%r{\([\d/\+\*\-\(\)]+\)}) do |expr|
      ArithmeticEvaluator.new.eval(expr, round_type)
    end

    debug("diceBot.changeText(string) begin", string)
    string = @diceBot.changeText(string)
    debug("diceBot.changeText(string) end", string)

    string = string.gsub(/([\d]+[dD])([^\w]|$)/) { "#{Regexp.last_match(1)}6#{Regexp.last_match(2)}" }

    debug("parren_killer output", string)

    return string
  end

  # [1...4]D[2...7] -> 2D7 のように[n...m]をランダムな数値へ変換
  def changeRangeTextToNumberText(string)
    debug('[st...ed] before string', string)

    while /^(.*?)\[(\d+)[.]{3}(\d+)\](.*)/ =~ string
      beforeText = Regexp.last_match(1)
      beforeText ||= ""

      rangeBegin = Regexp.last_match(2).to_i
      rangeEnd = Regexp.last_match(3).to_i

      afterText = Regexp.last_match(4)
      afterText ||= ""

      next unless rangeBegin < rangeEnd

      range = (rangeEnd - rangeBegin + 1)
      debug('range', range)

      rolledNumber, = roll(1, range)
      resultNumber = rangeBegin - 1 + rolledNumber
      string = "#{beforeText}#{resultNumber}#{afterText}"
    end

    debug('[st...ed] after string', string)

    return string
  end

  # 指定したタイトルのゲームを設定する
  # @param [String] gameTitle ゲームタイトル
  # @return [String] ゲームを設定したことを示すメッセージ
  def setGameByTitle(gameTitle)
    debug('setGameByTitle gameTitle', gameTitle)

    loader = DiceBotLoaderList.find(gameTitle)
    diceBot =
      if loader
        loader.loadDiceBot
      else
        DiceBotLoader.loadUnknownGame(gameTitle) || DiceBot.new
      end

    setDiceBot(diceBot)
    diceBot.postSet

    message = "Game設定を#{diceBot.name}に設定しました"
    debug('setGameByTitle message', message)

    return message
  end
end
