# frozen_string_literal: true

require "bcdice/randomizer"
require "bcdice/dice_table"
require "bcdice/enum"

module BCDice
  class Base
    class << self
      # 接頭辞（反応するコマンド）の配列を返す
      # @return [Array<String>]
      attr_reader :prefixes

      # 応答するコマンドのprefixを登録する
      # @param prefixes [Array<String>]
      def register_prefix(*prefixes)
        @prefixes ||= []
        @prefixes.concat(prefixes.flatten)
      end

      # ゲームシステム固有のコマンドにマッチする正規表現を返す
      # 正規表現を一度生成したら、以後コマンドの登録はできないようにする
      #
      # @return [Regexp]
      def prefixes_pattern
        @prefixes_pattern ||= nil
        return @prefixes_pattern if @prefixes_pattern

        @prefixes ||= []
        @prefixes.freeze
        @prefixes_pattern =
          if @prefixes.empty?
            /(?!)/ # 何にもマッチしない正規表現
          else
            /^(S)?(#{@prefixes.join('|')})/i
          end.freeze
      end

      # 応答するコマンド全てにマッチする正規表現を返す
      # 正規表現を一度生成したら、以後コマンドの登録はできないようにする
      #
      # @return [Regexp]
      def command_pattern
        @command_pattern ||= nil
        return @command_pattern if @command_pattern

        @prefixes ||= []
        @prefixes.freeze
        pattarns = CommonCommand::COMMANDS.map { |c| c::PREFIX_PATTERN.source } + @prefixes

        @command_pattern = /^S?(#{pattarns.join("|")})/i.freeze
      end
    end

    def initialize()
      @sort_add_dice = false # 加算ダイスでダイス目をソートするかどうか
      @sort_barabara_dice = false # バラバラダイスでダイス目をソートするかどうか

      @enabled_d66 = true # D66ダイスを利用するかどうか
      @d66_sort_type = D66SortType::NO_SORT # 入れ替えの種類 詳しくはBCDice::D66SortTypeを参照すること

      @enabled_d9 = false # D9ダイスを有効にするか（ガンドッグ）で使用

      @round_type = RoundType::FLOOR # 割り算をした時の端数の扱い (FLOOR: 切り捨て, CEIL: 切り上げ, ROUND: 四捨五入)

      @upper_dice_reroll_threshold = nil # UpperDiceで振り足しをする出目の閾値 nilの場合デフォルト設定なし
      @reroll_dice_reroll_threshold = nil # RerollDiceで振り足しをする出目の閾値 nilの場合デフォルト設定なし

      @default_cmp_op = nil # 目標値が空欄の場合の比較演算子をシンボルで指定する (:>, :>= :<, :<=, :==, :!=)
      @default_target_number = nil # 目標値が空欄の場合の目標値 こちらだけnilにするのは想定していないので注意

      @enabled_upcase_input = true # 入力を String#upcase するかどうか

      @is_secret = false

      @randomizer = BCDice::Randomizer.new
      @debug = false
    end

    attr_accessor :randomizer

    # D66のダイス入れ替えの種類
    #
    # @return [Symbol]
    attr_reader :d66_sort_type

    # 端数処理の種類
    #
    # @return [Symbol]
    attr_reader :round_type

    # UpperDiceで振り足しをする出目の閾値
    #
    # @return [Integer, nil]
    attr_reader :upper_dice_reroll_threshold

    # RerollDiceで振り足しをする出目の閾値
    #
    # @return [Integer, nil]
    attr_reader :reroll_dice_reroll_threshold

    # デフォルトの比較演算子
    #
    # @return [Symbol, nil]
    attr_reader :default_cmp_op

    # デフォルトの目標値
    #
    # @return [Integer, nil]
    attr_reader :default_target_number

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
    def enabled_d66?
      @enabled_d66
    end

    # D9ダイスが有効か
    #
    # @return [Boolean]
    def enabled_d9?
      @enabled_d9
    end

    # シークレットコマンドか
    #
    # @return [Boolean]
    def secret?
      @is_secret
    end

    # デバッグを有用にする
    def enable_debug
      @debug = true
    end

    # @param command [String]
    # @return [String, nil] コマンド実行結果。コマンドが実行できなかった場合はnilを返す
    def eval(command)
      command = BCDice::Preprocessor.process(command, @randomizer, self)
      upcased_command = command.upcase

      result = dice_command(command)
      result ||= eval_common_command(upcased_command)

      return result
    end

    def eval_common_command(command)
      CommonCommand::COMMANDS.each do |klass|
        cmd = klass.new(command, @randomizer, self)
        out = cmd.eval()

        @is_secret = cmd.secret?
        return out if out
      end

      return nil
    end

    def change_text(string)
      string
    end

    def dice_command(command)
      command = command.upcase if @enabled_upcase_input

      m = self.class.prefixes_pattern.match(command)
      unless m
        return nil
      end

      secret = !m[1].nil?
      command = command[1..-1] if secret # 先頭の 'S' をとる

      output = eval_game_system_specific_command(command)
      @is_secret ||= secret
      if output.nil? || output.empty? || output == "1"
        return nil
      else
        return output.to_s
      end
    end

    # @param command [String]
    # @return [String, nil]
    def eval_game_system_specific_command(command); end

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

      if total.send(cmp_op, target)
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
      num = @randomizer.roll_sum(count, diceType)

      text = get_table_value(table[num - count])

      return "1", 0 if text.nil?

      return text, num
    end

    def get_table_by_1d3(table)
      debug("get_table_by_1d3")

      count = 1
      num = @randomizer.roll_sum(count, 6)
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
      dice1 = @randomizer.roll_once(6)
      dice2 = @randomizer.roll_once(6)

      num = (dice1 - 1) * 6 + (dice2 - 1)

      text = table[num]

      indexText = "#{dice1}#{dice2}"

      return "1", indexText if text.nil?

      return text, indexText
    end

    # シャドウラン4版用グリッチ判定
    def grich_text(_numberSpot1, _dice_cnt_total, _suc); end

    # ** 汎用表サブルーチン
    def get_table_by_number(index, table, default = "1")
      table.each do |item|
        number = item[0]
        if number >= index
          return get_table_value(item[1])
        end
      end

      return get_table_value(default)
    end

    def get_table_value(data)
      if data.is_a?(Proc)
        return data.call()
      end

      return data
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
