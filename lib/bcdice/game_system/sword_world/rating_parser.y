class RatingParser
  token NUMBER K R H G F PLUS MINUS ASTERISK SLASH PARENL PARENR BRACKETL BRACKETR AT SHARP DOLLAR

  expect 4

  rule
    expr: rate option
        {
          rate, option = val
          modifier = option[:modifier].nil? ? Arithmetic::Node::Number.new(0) : option[:modifier]
          result = parsed(rate, modifier, option)
        }
        | H rate option
        {
          _, rate, option = val
          option[:modifier_after_half] = Arithmetic::Node::Number.new(0) if option[:modifier_after_half].nil?
          modifier = option[:modifier].nil? ? Arithmetic::Node::Number.new(0) : option[:modifier]
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
            if option.key?(:modifier)  # 分散したmodifierは足し込む
                option[:modifier] = Arithmetic::Node::BinaryOp.new(option[:modifier], :+, term)
            else
                option[:modifier] = term
            end
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
            raise ParseError unless [:v2_5, :v2_0].include?(@version) && option[:greatest_fortune].nil?

            option[:greatest_fortune] = true
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
         divied_class = val[3]
         result = divied_class.new(val[0], val[2])
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
require "bcdice/game_system/sword_world/rating_lexer"
require "bcdice/game_system/sword_world/rating_parsed"

# SwordWorldの威力表コマンドをパースするクラス
module BCDice
  module GameSystem
    class SwordWorld < Base

---- inner

def initialize()
  super()
  @version = :v1_0
end

# バージョンを指定する
# @return [BCDice::GameSystem::SwordWorld::RatingParser]
def set_version(version)
  @version = version
  self
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
    p.critical = option[:critical]&.eval(Arithmetic::Node::DivideWithGameSystemDefault)
    p.kept_modify = option[:kept_modify]&.eval(Arithmetic::Node::DivideWithGameSystemDefault)
    p.first_to = option[:first_to]
    p.first_modify = option[:first_modify]
    p.rateup = option[:rateup]&.eval(Arithmetic::Node::DivideWithGameSystemDefault)
    p.greatest_fortune = option.fetch(:greatest_fortune, false)
    p.modifier = modifier.eval(Arithmetic::Node::DivideWithGameSystemDefault)
    p.modifier_after_half = option[:modifier_after_half]&.eval(Arithmetic::Node::DivideWithGameSystemDefault)
  end
end

def next_token
  @lexer.next_token
end

---- footer
    end
  end
end
