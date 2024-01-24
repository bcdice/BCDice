# frozen_string_literal: true

require "i18n"
require "i18n/backend/fallbacks"
require "bcdice/randomizer"
require "bcdice/dice_table"
require "bcdice/enum"
require "bcdice/translate"
require "bcdice/result"
require "bcdice/command/parser"
require "bcdice/deprecated/checker"

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

      def register_prefix_from_super_class
        register_prefix(superclass.prefixes)
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

        @command_pattern = /^S?(#{pattarns.join('|')})/i.freeze
      end

      # @param command [String]
      # @return [Result]
      def eval(command)
        new(command).eval
      end
    end

    include Translate
    include Deprecated::Checker

    def initialize(command)
      @raw_input = command

      @sort_add_dice = false # 加算ダイスでダイス目をソートするかどうか
      @sort_barabara_dice = false # バラバラダイスでダイス目をソートするかどうか

      @d66_sort_type = D66SortType::NO_SORT # 入れ替えの種類 詳しくはBCDice::D66SortTypeを参照すること

      @enabled_d9 = false # D9ダイスを有効にするか（ガンドッグ）で使用

      @round_type = RoundType::FLOOR # 割り算をした時の端数の扱い (FLOOR: 切り捨て, CEIL: 切り上げ, ROUND: 四捨五入)

      @sides_implicit_d = 6 # 1D のようにダイスの面数が指定されていない場合に何面ダイスにするか

      @upper_dice_reroll_threshold = nil # UpperDiceで振り足しをする出目の閾値 nilの場合デフォルト設定なし
      @reroll_dice_reroll_threshold = nil # RerollDiceで振り足しをする出目の閾値 nilの場合デフォルト設定なし

      @default_cmp_op = nil # 目標値が空欄の場合の比較演算子をシンボルで指定する (:>, :>= :<, :<=, :==, :!=)
      @default_target_number = nil # 目標値が空欄の場合の目標値 こちらだけnilにするのは想定していないので注意

      @enabled_upcase_input = true # 入力を String#upcase するかどうか

      @locale = :ja_jp # i18n用の言語設定

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

    # ダイスの面数が指定されていない場合に何面ダイスにするか
    #
    # @return [Integer]
    attr_reader :sides_implicit_d

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

    # D9ダイスが有効か
    #
    # @return [Boolean]
    def enabled_d9?
      @enabled_d9
    end

    # デバッグを有用にする
    def enable_debug
      @debug = true
    end

    # コマンドを評価する
    # @return [Result, nil] コマンド実行結果。コマンドが実行できなかった場合はnilを返す
    def eval
      command = BCDice::Preprocessor.process(@raw_input, self)

      result = dice_command(command) || eval_common_command(@raw_input)
      return nil unless result

      result.rands = @randomizer.rand_results
      result.detailed_rands = @randomizer.detailed_rand_results

      return result
    end

    # ゲームシステムごとの入力コマンドの前処理
    # @deprecated これを使わずに +eval_common_command+ 内でパースすることを推奨する
    # @param string [String]
    # @return [String]
    def change_text(string)
      string
    end

    # @param total [Integer] コマンド合計値
    # @param rand_results [Array<CommonCommand::AddDice::Randomizer::RandResult>] ダイスの一覧
    # @param cmp_op [Symbol] 比較演算子
    # @param target [Integer, String] 目標値の整数か'?'
    # @return [Result, nil]
    def check_result(total, rand_results, cmp_op, target)
      ret = check_result_legacy(total, rand_results, cmp_op, target)
      return ret if ret

      sides_list = rand_results.map(&:sides)
      value_list = rand_results.map(&:value)
      dice_total = value_list.sum()

      ret =
        case sides_list
        when [100]
          result_1d100(total, dice_total, cmp_op, target)
        when [20]
          result_1d20(total, dice_total, cmp_op, target)
        when [6, 6]
          result_2d6(total, dice_total, value_list, cmp_op, target)
        end

      return nil if ret == Result.nothing
      return ret if ret

      ret =
        case sides_list.uniq
        when [10]
          result_nd10(total, dice_total, value_list, cmp_op, target)
        when [6]
          result_nd6(total, dice_total, value_list, cmp_op, target)
        end

      return nil if ret == Result.nothing
      return ret if ret

      return result_ndx(total, cmp_op, target)
    end

    # シャドウラン用グリッチ判定
    # @param count_one [Integer] 出目1の数
    # @param dice_total_count [Integer] ダイスロールしたダイスの数
    # @param count_success [Integer] 成功数
    # @return [String, nil]
    def grich_text(count_one, dice_total_count, count_success); end

    private

    def eval_common_command(command)
      command = change_text(command)
      CommonCommand::COMMANDS.each do |klass|
        result = klass.eval(command, self, @randomizer)
        return result if result
      end

      return nil
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

      if output.is_a?(Result)
        output.secret = output.secret? || secret
        return output
      elsif output.nil? || output.empty? || output == "1"
        return nil
      else
        return Result.new.tap do |r|
          r.text = output.to_s
          r.secret = secret
        end
      end
    end

    # @param command [String]
    # @return [String, nil]
    def eval_game_system_specific_command(command); end

    # 成功か失敗か返す
    #
    # @param total [Integer]
    # @param cmp_op [Symbol]
    # @param target [Number]
    # @return [Result]
    def result_ndx(total, cmp_op, target)
      if target.is_a?(String)
        nil
      elsif total.send(cmp_op, target)
        Result.success(translate("success"))
      else
        Result.failure(translate("failure"))
      end
    end

    def result_1d100(total, dice_total, cmp_op, target); end

    def result_1d20(total, dice_total, cmp_op, target); end

    def result_nd10(total, dice_total, value_list, cmp_op, target); end

    def result_2d6(total, dice_total, value_list, cmp_op, target); end

    def result_nd6(total, dice_total, value_list, cmp_op, target); end

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

I18n::Backend::Simple.include(I18n::Backend::Fallbacks)
I18n.load_path << Dir[File.join(__dir__, "../../i18n/**/*.yml")]
I18n.default_locale = :ja_jp
I18n.fallbacks.defaults = [:ja_jp]
