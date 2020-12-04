module BCDice
  class Result
    class << self
      def success(text)
        new.tap do |r|
          r.text = text
          r.success = true
        end
      end

      def failure(text)
        new.tap do |r|
          r.text = text
          r.failure = true
        end
      end

      def critical(text)
        new.tap do |r|
          r.text = text
          r.critical = true
          r.success = true
        end
      end

      def fumble(text)
        new.tap do |r|
          r.text = text
          r.fumble = true
          r.failure = true
        end
      end

      def nothing
        :nothing
      end
    end

    def initialize(text = nil)
      @text = text
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
