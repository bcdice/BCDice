#!/bin/ruby -Ku
# -*- coding: utf-8 -*-

$isDebug = false

require 'log'
require 'utils/ArithmeticEvaluator.rb'

require 'bcdice/game_system/DiceBot'
require 'bcdice/game_system/DiceBotLoader'
require 'bcdice/game_system/DiceBotLoaderList'
require 'bcdice/common_command'
require 'bcdice/preprocessor'

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
    # 空白が含まれる場合、最初の部分だけを取り出す
    messageToSet = message.split(/\s/, 2).first
    debug("setMessage messageToSet", messageToSet)

    @messageOriginal = Preprocessor.process(messageToSet, self, @diceBot)
    @message = @messageOriginal.upcase
    debug("@message", @message)
  end

  def setTest(isTest)
    @isTest = isTest
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

  DICE_MAXCNT = 200
  DICE_MAXNUM = 1000

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

    unless (dice_cnt <= DICE_MAXCNT) && (dice_max <= DICE_MAXNUM)
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
