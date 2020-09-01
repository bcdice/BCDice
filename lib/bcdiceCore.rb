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
