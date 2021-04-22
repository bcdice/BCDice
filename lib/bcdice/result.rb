# frozen_string_literal: true

module BCDice
  # ダイスロールの結果を表すクラス
  #
  # コマンドの結果の文字列や、成功／失敗／クリティカル／ファンブルの情報を保持する。
  # 成功／失敗は同時に発生しないこととする。
  # 成功／失敗のペアとクリティカル、ファンブルの三者は独立した要素とし、
  # 「クリティカルだが失敗」や「ファンブルだが成功でも失敗でもない」を許容する。
  class Result
    class << self
      # +success+ が設定された +Result+ を作成する
      #
      # @param text [String]
      # @return [Result]
      def success(text)
        new.tap do |r|
          r.text = text
          r.success = true
        end
      end

      # +failure+ が設定された +Result+ を作成する
      #
      # @param text [String]
      # @return [Result]
      def failure(text)
        new.tap do |r|
          r.text = text
          r.failure = true
        end
      end

      # +success+ と +critical+ が設定された +Result+ を作成する
      #
      # @param text [String]
      # @return [Result]
      def critical(text)
        new.tap do |r|
          r.text = text
          r.critical = true
          r.success = true
        end
      end

      # +failure+ と +fumble+ が設定された +Result+ を作成する
      #
      # @param text [String]
      # @return [Result]
      def fumble(text)
        new.tap do |r|
          r.text = text
          r.fumble = true
          r.failure = true
        end
      end

      # その後の判定で何もすることがないことを示すために利用する
      #
      # @return [:nothing]
      def nothing
        :nothing
      end
    end

    # @param text [String | nil]
    def initialize(text = nil)
      @text = text
      @rands = nil
      @detailed_rands = nil
      @secret = false
      @success = false
      @failure = false
      @critical = false
      @fumble = false
    end

    attr_accessor :text, :rands, :detailed_rands
    attr_writer :secret, :success, :failure, :critical, :fumble

    # @return [Boolean]
    def secret?
      @secret
    end

    # @return [Boolean]
    def success?
      @success
    end

    # @return [Boolean]
    def failure?
      @failure
    end

    # @return [Boolean]
    def critical?
      @critical
    end

    # @return [Boolean]
    def fumble?
      @fumble
    end

    # @param condition [Boolean]
    # @return [void]
    def condition=(condition)
      @success = condition
      @failure = !condition
    end
  end
end
