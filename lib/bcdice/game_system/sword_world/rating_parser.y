class RatingParser
  token NUMBER K R H G F S T PLUS MINUS ASTERISK SLASH PARENL PARENR BRACKETL BRACKETR AT SHARP DOLLAR

  expect 4

  rule
    expr: rate option
        {
          rate, option = val
          modifier = option[:modifier] || Arithmetic::Node::Number.new(0)
          result = parsed(rate, modifier, option)
        }
        | H rate option
        {
          _, rate, option = val
          option[:modifier_after_half] ||= Arithmetic::Node::Number.new(0)
          modifier = option[:modifier] || Arithmetic::Node::Number.new(0)
          result = parsed(rate, modifier, option)
        }


    rate: K NUMBER
        { result = val[1].to_i }

    option: /* none */
          {
            result = {}
          }
          | option modifier
          {
            option, term = val
            raise ParseError unless option[:modifier].nil?

            option[:modifier] = term
            result = option
          }
          | option BRACKETL unary BRACKETR
          {
            option, _, term, _ = val
            raise ParseError unless option[:critical].nil?

            option[:critical] = term
            result = option
          }
          | option AT unary
          {
            option, _, term = val
            raise ParseError unless option[:critical].nil?

            option[:critical] = term
            result = option
          }
          | option DOLLAR NUMBER
          {
            option, _, term = val
            raise ParseError unless option[:first_to].nil? && option[:first_modify].nil?

            option[:first_to] = term.to_i
            result = option
          }
          | option DOLLAR PLUS NUMBER
          {
            option, _, _, term = val
            raise ParseError unless option[:first_to].nil? && option[:first_modify].nil?

            option[:first_modify] = term.to_i
            result = option
          }
          | option DOLLAR MINUS NUMBER
          {
            option, _, _, term = val
            raise ParseError unless option[:first_to].nil? && option[:first_modify].nil?

            option[:first_modify] = -(term.to_i)
            result = option
          }
          | option H
          {
            option, _ = val
            raise ParseError unless option[:modifier_after_half].nil?

            option[:modifier_after_half] = Arithmetic::Node::Number.new(0)
            result = option
          }
          | option H unary
          {
            option, _, term = val
            raise ParseError unless option[:modifier_after_half].nil?

            option[:modifier_after_half] = term
            result = option
          }
          | option R unary
          {
            option, _, term = val
            raise ParseError unless [:v2_5, :v2_0].include?(@version) && option[:rateup].nil?

            option[:rateup] = term
            result = option
          }
          | option G F
          {
            option, _, _ = val
            raise ParseError unless [:v2_5, :v2_0].include?(@version)
            raise ParseError unless option[:greatest_fortune].nil?
            raise ParseError unless option[:semi_fixed_val].nil?
            raise ParseError unless option[:tmp_fixed_val].nil?

            option[:greatest_fortune] = true
            result = option
          }
          | option S F unary
          {
            option, _, _, term = val
            raise ParseError unless [:v2_5, :v2_0].include?(@version)
            raise ParseError unless option[:greatest_fortune].nil?
            raise ParseError unless option[:semi_fixed_val].nil?
            raise ParseError unless option[:tmp_fixed_val].nil?

            option[:semi_fixed_val] = term
            result = option
          }
          | option T F unary
          {
            option, _, _, term = val
            raise ParseError unless [:v2_5, :v2_0].include?(@version)
            raise ParseError unless option[:greatest_fortune].nil?
            raise ParseError unless option[:semi_fixed_val].nil?
            raise ParseError unless option[:tmp_fixed_val].nil?

            option[:tmp_fixed_val] = term
            result = option
          }
          | option SHARP unary
          {
            option, _, term = val
            raise ParseError unless @version == :v2_5 && option[:kept_modify].nil?

            option[:kept_modify] = term
            result = option
          }

    modifier: PLUS mul
            { result = val[1] }
            | MINUS mul
            { result = Arithmetic::Node::Negative.new(val[1]) }
            | modifier PLUS mul
            { result = Arithmetic::Node::BinaryOp.new(val[0], :+, val[2]) }
            | modifier MINUS mul
            { result = Arithmetic::Node::BinaryOp.new(val[0], :-, val[2]) }

    add: add PLUS mul
       { result = Arithmetic::Node::BinaryOp.new(val[0], :+, val[2]) }
       | add MINUS mul
       { result = Arithmetic::Node::BinaryOp.new(val[0], :-, val[2]) }
       | mul

    mul: mul ASTERISK unary
       { result = Arithmetic::Node::BinaryOp.new(val[0], :*, val[2]) }
       | mul SLASH unary
       {
         result = Arithmetic::Node::DivideWithGameSystemDefault.new(val[0], val[2])
       }
       | unary

    unary: PLUS unary
         { result = val[1] }
         | MINUS unary
         { result = Arithmetic::Node::Negative.new(val[1]) }
         | term

    term: PARENL add PARENR
        { result = val[1] }
        | NUMBER
        { result = Arithmetic::Node::Number.new(val[0]) }
end

---- header

require "bcdice/arithmetic/node"
require "bcdice/enum"
require "bcdice/game_system/sword_world/rating_lexer"
require "bcdice/game_system/sword_world/rating_parsed"

module BCDice
  module GameSystem
    class SwordWorld < Base
    # SwordWorldの威力表コマンドをパースするクラス

---- inner

# デフォルトの丸めを切り上げとしているが、SwordWorldには切り捨てもあるので決め切れない（四捨五入は現状ない）
def initialize(version: :v1_0, round_type: RoundType::CEIL)
  super()
  @version = version
  @round_type = round_type
end

def set_debug
  @yydebug = true
  return self
end

# @param source [String]
# @return [BCDice::GameSystem::SwordWorld::RatingParsed, nil]
def parse(source)
  @lexer = RatingLexer.new(source)
  do_parse()
rescue ParseError, ZeroDivisionError
  nil
end

private

def parsed(rate, modifier, option)
  RatingParsed.new.tap do |p|
    p.rate = rate
    p.critical = option[:critical]&.eval(@round_type)
    p.kept_modify = option[:kept_modify]&.eval(@round_type)
    p.first_to = option[:first_to]
    p.first_modify = option[:first_modify]
    p.rateup = option[:rateup]&.eval(@round_type)
    p.greatest_fortune = option.fetch(:greatest_fortune, false)
    p.semi_fixed_val = option[:semi_fixed_val]&.eval(@round_type)
    p.tmp_fixed_val = option[:tmp_fixed_val]&.eval(@round_type)
    p.modifier = modifier.eval(@round_type)
    p.modifier_after_half = option[:modifier_after_half]&.eval(@round_type)
  end
end

def next_token
  @lexer.next_token
end

---- footer
    end
  end
end
