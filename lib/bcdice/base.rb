# frozen_string_literal: true

require "bcdice/randomizer"
require "bcdice/enum"

module BCDice
  class Base
    # 空の接頭辞（反応するコマンド）
    EMPTY_PREFIXES_PATTERN = /(^|\s)(S)?()(\s|$)/i.freeze

    class << self
      # 接頭辞（反応するコマンド）の配列を返す
      # @return [Array<String>]
      attr_reader :prefixes

      # 接頭辞（反応するコマンド）の正規表現を返す
      # @return [Regexp]
      attr_reader :prefixesPattern

      # 接頭辞（反応するコマンド）を設定する
      # @param [Array<String>] prefixes 接頭辞のパターンの配列
      # @return [self]
      def setPrefixes(prefixes)
        @prefixes = prefixes.
                    # 最適化が効くように内容の文字列を変更不可にする
                    map(&:freeze).
                    # 配列全体を変更不可にする
                    freeze
        @prefixesPattern = /(^|\s)(S)?(#{prefixes.join('|')})(\s|$)/i.freeze

        self
      end

      # 接頭辞（反応するコマンド）をクリアする
      # @return [self]
      def clearPrefixes
        @prefixes = [].freeze
        @prefixesPattern = EMPTY_PREFIXES_PATTERN

        self
      end

      private

      # 継承された際にダイスボットの接頭辞リストをクリアする
      # @param [DiceBot] subclass DiceBotを継承したクラス
      # @return [void]
      def inherited(subclass)
        subclass.clearPrefixes
      end
    end

    clearPrefixes

    def initialize(debug: false)
      @sort_add_dice = false # 加算ダイスでダイス目をソートするかどうか
      @sort_barabara_dice = false # バラバラダイスでダイス目をソートするかどうか

      @enable_d66 = true # D66ダイスを利用するかどうか
      @d66_sort_type = D66SortType::NO_SORT # 入れ替えの種類 詳しくはBCDice::D66SortTypeを参照すること

      @round_type = RoundType::FLOOR # 割り算をした時の端数の扱い (FLOOR: 切り捨て, CEIL: 切り上げ, ROUND: 四捨五入)

      @sameDiceRerollCount = 0 # ゾロ目で振り足し(0=無し, 1=全部同じ目, 2=ダイスのうち2個以上同じ目)
      @sameDiceRerollType = 0 # ゾロ目で振り足しのロール種別(0=判定のみ, 1=ダメージのみ, 2=両方)
      @isPrintMaxDice = false # 最大値表示
      @upperRollThreshold = 0 # 上方無限
      @rerollNumber = 0 # 振り足しする条件
      @defaultSuccessTarget = "" # 目標値が空欄の時の目標値
      @rerollLimitCount = 10000 # 振り足し回数上限
      @randomizer = BCDice::Randomizer.new
      @debug = debug

      if !prefixs.empty? && self.class.prefixes.empty?
        # 従来の方法（#prefixs）で接頭辞を設定していた場合でも
        # クラス側に接頭辞が設定されるようにする
        warn("#{id}: #prefixs is deprecated. Please use .setPrefixes.")
        self.class.setPrefixes(prefixs)
      end
    end

    attr_reader :randomizer

    # D66のダイス入れ替えの種類
    #
    # @return [Symbol]
    attr_reader :d66_sort_type

    # 端数処理の種類
    #
    # @return [Symbol]
    attr_reader :round_type

    # 加算ダイスでダイス目をソートするかどうか
    #
    # @return [Boolean]
    def sort_add_dice?
      @sort_add_dice
    end

    # バラバラダイスでダイス目をソートするかどうか
    #
    # @return [Boolean]
    def sort_barabara_dice?
      @sort_barabara_dice
    end

    # D66ダイスが有効か
    #
    # @return [Boolean]
    def enable_d66?
      @enable_d66
    end

    def eval(command)
      command = BCDice::Preprocessor.process(command, @randomizer, self)
      upcased_command = command.upcase

      result, secret = dice_command(command, "")
      result, secret = BCDice::CommonCommand.eval(upcased_command, @randomizer, self) if result == "1" || result.nil?

      if result.nil?
        return ""
      end

      if secret
        result += "###secret dice###"
      end

      display_id = id.sub(/:.+$/, "") # 多言語対応用

      if result == "1"
        return ""
      else
        return [display_id, result].join(" ")
      end
    end

    attr_accessor :rerollLimitCount

    attr_reader :sameDiceRerollCount, :sameDiceRerollType, :d66Type
    attr_reader :isPrintMaxDice, :upperRollThreshold
    attr_reader :defaultSuccessTarget, :rerollNumber

    # ダイスボット設定後に行う処理
    # @return [void]
    #
    # 既定では何もしない。
    def postSet
      # 何もしない
    end

    # ダイスボットについての情報を返す
    # @return [Hash]
    def info
      {
        "gameType" => id,
        "name" => name,
        "sortKey" => sort_key,
        "prefixs" => self.class.prefixes,
        "info" => help_message,
      }
    end

    # ゲームシステムの識別子を返す
    # @return [String]
    def id
      self.class::ID
    end

    # ゲームシステムの識別子を返す
    # @return [String]
    # @deprecated 代わりに {#id} を使ってください
    def gameType
      warn("#{id}: #gameType is deprecated. Please use #id.")
      return id
    end

    # ゲームシステム名を返す
    # @return [String]
    def name
      self.class::NAME
    end

    # ゲームシステム名を返す
    # @return [String]
    # @deprecated 代わりに {#name} を使ってください
    def gameName
      warn("#{id}: #gameName is deprecated. Please use #name.")
      return name
    end

    # ゲームシステム名の読みがなを返す
    # @return [String]
    def sort_key
      self.class::SORT_KEY
    end

    # ダイスボットの使い方を返す
    # @return [String]
    def help_message
      self.class::HELP_MESSAGE
    end

    # ダイスボットの使い方を返す
    # @return [String]
    # @deprecated 代わりに {#help_message} を使ってください
    def getHelpMessage
      warn("#{id}: #getHelpMessage is deprecated. Please use #help_message.")
      return help_message
    end

    # 接頭辞（反応するコマンド）の配列を返す
    # @return [Array<String>]
    def prefixes
      self.class.prefixes
    end

    # @deprecated 代わりに {#prefixes} を使ってください
    alias prefixs prefixes

    attr_writer :upperRollThreshold

    attr_reader :bcdice

    def rand(max)
      @randomizer.rand(max)
    end

    def roll(*args)
      @randomizer.roll(*args)
    end

    def roll_d66(sort_type)
      @randomizer.roll_d66(sort_type)
    end

    def changeText(string)
      string
    end

    def dice_command(string, nick_e)
      string = string.upcase unless isGetOriginalMessage

      debug("dice_command Begin string", string)
      secret_flg = false

      unless self.class.prefixesPattern =~ string
        debug("not match in prefixes")
        return "1", secret_flg
      end

      secretMarker = Regexp.last_match(2)
      command = Regexp.last_match(3)

      command = removeDiceCommandMessage(command)
      debug("dicebot after command", command)

      debug("match")

      output_msg, secret_flg = rollDiceCommand(command)
      output_msg = "1" if output_msg.nil? || output_msg.empty?
      secret_flg ||= false

      output_msg = "#{nick_e}: #{output_msg}" if output_msg != "1"

      if secretMarker # 隠しロール
        secret_flg = true if output_msg != "1"
      end

      return output_msg, secret_flg
    end

    # 通常ダイスボットのコマンド文字列は全て大文字に強制されるが、
    # これを嫌う場合にはこのメソッドを true を返すようにオーバーライドすること。
    def isGetOriginalMessage
      false
    end

    def removeDiceCommandMessage(command)
      # "2d6 Attack" のAttackのようなメッセージ部分をここで除去
      command.sub(/[\s　].+/, "")
    end

    def rollDiceCommand(_command)
      nil
    end

    # @param total [Integer] コマンド合計値
    # @param dice_total [Integer] ダイス目の合計値
    # @param dice_list [Array<Integer>] ダイスの一覧
    # @param sides [Integer] 振ったダイスの面数
    # @param cmp_op [Symbol] 比較演算子
    # @param target [Integer, String] 目標値の整数か'?'
    # @return [String]
    def check_result(total, dice_total, dice_list, sides, cmp_op, target)
      ret =
        case [dice_list.size, sides]
        when [1, 100]
          check_1D100(total, dice_total, cmp_op, target)
        when [1, 20]
          check_1D20(total, dice_total, cmp_op, target)
        when [2, 6]
          check_2D6(total, dice_total, dice_list, cmp_op, target)
        end

      return ret unless ret.nil? || ret.empty?

      ret =
        case sides
        when 10
          check_nD10(total, dice_total, dice_list, cmp_op, target)
        when 6
          check_nD6(total, dice_total, dice_list, cmp_op, target)
        end

      return ret unless ret.nil? || ret.empty?

      check_nDx(total, cmp_op, target)
    end

    # 成功か失敗かを文字列で返す
    #
    # @param (see #check_result)
    # @return [String]
    def check_nDx(total, cmp_op, target)
      return " ＞ 失敗" if target.is_a?(String)

      # Due to Ruby 1.8
      success = cmp_op == :"!=" ? total != target : total.send(cmp_op, target)
      if success
        " ＞ 成功"
      else
        " ＞ 失敗"
      end
    end

    # @abstruct
    # @param (see #check_result)
    # @return [nil]
    def check_1D100(total, dice_total, cmp_op, target); end

    # @abstruct
    # @param (see #check_result)
    # @return [nil]
    def check_1D20(total, dice_total, cmp_op, target); end

    # @abstruct
    # @param (see #check_result)
    # @return [nil]
    def check_nD10(total, dice_total, dice_list, cmp_op, target); end

    # @abstruct
    # @param (see #check_result)
    # @return [nil]
    def check_2D6(total, dice_total, dice_list, cmp_op, target); end

    # @abstruct
    # @param (see #check_result)
    # @return [nil]
    def check_nD6(total, dice_total, dice_list, cmp_op, target); end

    def get_table_by_2d6(table)
      get_table_by_nD6(table, 2)
    end

    def get_table_by_1d6(table)
      get_table_by_nD6(table, 1)
    end

    def get_table_by_nD6(table, count)
      get_table_by_nDx(table, count, 6)
    end

    def get_table_by_nDx(table, count, diceType)
      num, = roll(count, diceType)

      text = getTableValue(table[num - count])

      return "1", 0 if text.nil?

      return text, num
    end

    def get_table_by_1d3(table)
      debug("get_table_by_1d3")

      count = 1
      num, = roll(count, 6)
      debug("num", num)

      index = ((num - 1) / 2)
      debug("index", index)

      text = table[index]

      return "1", 0 if text.nil?

      return text, num
    end

    # D66 ロール用（スワップ、たとえば出目が【６，４】なら「６４」ではなく「４６」とする
    def get_table_by_d66_swap(table)
      number = @randomizer.roll_d66(D66SortType::ASC)
      return get_table_by_number(number, table), number
    end

    # D66 ロール用
    def get_table_by_d66(table)
      dice1, = roll(1, 6)
      dice2, = roll(1, 6)

      num = (dice1 - 1) * 6 + (dice2 - 1)

      text = table[num]

      indexText = "#{dice1}#{dice2}"

      return "1", indexText if text.nil?

      return text, indexText
    end

    # ダイスロールによるポイント等の取得処理用（T&T悪意、ナイトメアハンター・ディープ宿命、特命転校生エクストラパワーポイントなど）
    def getDiceRolledAdditionalText(_n1, _n_max, _dice_max)
      ""
    end

    # ダイス目による補正処理（現状ナイトメアハンターディープ専用）
    def getDiceRevision(_n_max, _dice_max, _total_n)
      return "", 0
    end

    # ガンドッグのnD9専用
    def isD9
      false
    end

    # シャドウラン4版用グリッチ判定
    def grich_text(_numberSpot1, _dice_cnt_total, _suc); end

    # 振り足しを行うべきかを返す
    # @param [Integer] loop_count ループ数
    # @return [Boolean]
    def should_reroll?(loop_count)
      loop_count < @rerollLimitCount || @rerollLimitCount == 0
    end

    # ** 汎用表サブルーチン
    def get_table_by_number(index, table, default = "1")
      table.each do |item|
        number = item[0]
        if number >= index
          return getTableValue(item[1])
        end
      end

      return getTableValue(default)
    end

    def getTableValue(data)
      if data.is_a?(Proc)
        return data.call()
      end

      return data
    end

    def analyzeDiceCommandResultMethod(command)
      # get～DiceCommandResultという名前のメソッドを集めて実行、
      # 結果がnil以外の場合それを返して終了。
      methodList = public_methods(false).select do |method|
        method.to_s =~ /^get.+DiceCommandResult$/
      end

      methodList.each do |method|
        result = send(method, command)
        return result unless result.nil?
      end

      return nil
    end

    def get_table_by_nDx_extratable(table, count, diceType)
      number, diceText = roll(count, diceType)
      text = getTableValue(table[number - count])
      return text, number, diceText
    end

    def getTableCommandResult(command, tables, isPrintDiceText = true)
      info = tables[command]
      return nil if info.nil?

      name = info[:name]
      type = info[:type].upcase
      table = info[:table]

      if (type == "D66") && (@d66_sort_type == D66SortType::ASC)
        type = "D66S"
      end

      text, number, diceText =
        case type
        when /(\d+)D(\d+)/
          count = Regexp.last_match(1).to_i
          diceType = Regexp.last_match(2).to_i
          limit = diceType * count - (count - 1)
          table = getTableInfoFromExtraTableText(table, limit)
          get_table_by_nDx_extratable(table, count, diceType)
        when "D66", "D66N"
          table = getTableInfoFromExtraTableText(table, 36)
          item, value = get_table_by_d66(table)
          value = value.to_i
          output = item[1]
          diceText = (value / 10).to_s + "," + (value % 10).to_s
          [output, value, diceText]
        when "D66S"
          table = getTableInfoFromExtraTableText(table, 21)
          output, value = get_table_by_d66_swap(table)
          value = value.to_i
          diceText = (value / 10).to_s + "," + (value % 10).to_s
          [output, value, diceText]
        else
          raise "invalid dice Type #{command}"
        end

      text = text.gsub("\\n", "\n")
      text = rollTableMessageDiceText(text)

      return nil if text.nil?

      return "#{name}(#{number}[#{diceText}]) ＞ #{text}" if isPrintDiceText && !diceText.nil?

      return "#{name}(#{number}) ＞ #{text}"
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

    def getTableInfoFromExtraTableText(text, count = nil)
      if text.is_a?(String)
        text = text.split(/\n/)
      end

      newTable = text.map do |item|
        if item.is_a?(String) && (item =~ /^(\d+):(.*)/)
          [Regexp.last_match(1).to_i, Regexp.last_match(2)]
        else
          item
        end
      end

      unless count.nil?
        if newTable.size != count
          raise "invalid table size (actual #{newTable.size}, expected #{count})\n#{newTable.inspect}"
        end
      end

      return newTable
    end

    def roll_tables(command, tables)
      table = tables[command]
      unless table
        return nil
      end

      return table.roll(@randomizer).to_s
    end

    # デバッグ出力を行う
    # @param [Object] target 対象項目
    # @param [Object] values 値
    def debug(target, *values)
      return unless @debug

      targetStr = target.is_a?(String) ? target : target.inspect

      if values.empty?
        warn targetStr
      else
        valueStrs = values.map do |value|
          value.is_a?(String) ? %("#{value}") : value.inspect
        end

        warn "#{targetStr}: #{valueStrs.join(', ')}"
      end
    end
  end
end
