class BCDice::Command::Parser
  token NUMBER R U C F PLUS MINUS ASTERISK SLASH PARENL PARENR AT SHARP DOLLAR AMPERSAND CMP_OP QUESTION NOTATION

  expect 2

  rule
    expr: notation option modifier target
        {
          raise ParseError unless @modifier
          notation, option, modifier, target = val
          result = parsed(notation, option, modifier, target)
        }
        | notation modifier option target
        {
          raise ParseError unless @modifier
          notation, modifier, option, target = val
          result = parsed(notation, option, modifier, target)
        }
        | notation option target
        {
          notation, option, target = val
          result = parsed(notation, option,  Arithmetic::Node::Number.new(0), target)
        }

    notation: term NOTATION term
            {
              raise ParseError unless @prefix_number && @suffix_number
              result = { command: val[1], prefix: val[0], suffix: val[2] }
            }
            | term NOTATION
            {
              raise ParseError unless @prefix_number
              raise ParseError if @need_suffix_number
              result = { command: val[1], prefix: val[0] }
            }
            | NOTATION term
            {
              raise ParseError unless @suffix_number
              raise ParseError if @need_prefix_number
              result = { command: val[0], suffix: val[1] }
            }
            | NOTATION {
              raise ParseError if @need_prefix_number || @need_suffix_number
              result = { command: val[0] }
            }

    option: /* none */
          {
            result = {}
          }
          | option AT unary
          {
            option, _, term = val
            raise ParseError unless @critical && option[:critical].nil?

            option[:critical] = term
            result = option
          }
          | option SHARP unary
          {
            option, _, term = val
            raise ParseError unless @fumble && option[:fumble].nil?

            option[:fumble] = term
            result = option
          }
          | option DOLLAR unary
          {
            option, _, term = val
            raise ParseError unless @dollar && option[:dollar].nil?

            option[:dollar] = term
            result = option
          }
          | option AMPERSAND unary
          {
            option, _, term = val
            raise ParseError unless @ampersand && option[:ampersand].nil?

            option[:ampersand] = term
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

    target: /* none */
          {
            raise ParseError unless @allowed_cmp_op.include?(nil)
            result = {}
          }
          | CMP_OP add
          {
            cmp_op, target = val
            raise ParseError unless @allowed_cmp_op.include?(cmp_op)

            result = {cmp_op: cmp_op, target: target}
          }
          | CMP_OP QUESTION
          {
            cmp_op = val[0]
            raise ParseError unless @question_target
            raise ParseError unless @allowed_cmp_op.include?(cmp_op)

            result = {cmp_op: cmp_op, target: "?"}
          }

    add: add PLUS mul
       { result = Arithmetic::Node::BinaryOp.new(val[0], :+, val[2]) }
       | add MINUS mul
       { result = Arithmetic::Node::BinaryOp.new(val[0], :-, val[2]) }
       | mul

    mul: mul ASTERISK unary
       { result = Arithmetic::Node::BinaryOp.new(val[0], :*, val[2]) }
       | mul SLASH unary round_type
       {
         divied_class = val[3]
         result = divied_class.new(val[0], val[2])
       }
       | unary

    round_type: /* none */
              { result = Arithmetic::Node::DivideWithGameSystemDefault }
              | U
              { result = Arithmetic::Node::DivideWithCeil }
              | C
              { result = Arithmetic::Node::DivideWithCeil }
              | R
              { result = Arithmetic::Node::DivideWithRound }
              | F
              { result = Arithmetic::Node::DivideWithFloor }

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
require "bcdice/command/lexer"
require "bcdice/command/parsed"

# よくある形式のコマンドのパースを補助するクラス
#
# @example Literal by String
#   parser = Command::Parser.new("MC", round_type: BCDice::RoundType::FLOOR)
#                           .enable_critical
#   parsed = parser.parse("MC+2*3@30<=10/2-3") #=> <Command::Parsed>
#
#   parsed.command #=> "MC"
#   parsed.modify_number #=> 6
#   parsed.critical #=> 30
#   parsed.cmp_op #=> #>=
#   parsed.target_number #=> 2
#
# @example Literal by Regexp
#   parser = Command::Parser.new(/RE\d+/)
#   parsed = parser.parse("RE44+20") #=> <Command::Parsed>
#
#   parsed.command #=> "RE44"
#   parsed.modify_number #=> 20
class BCDice::Command::Parser < Racc::Parser; end

---- inner

# @param notations [Array<String, Regexp>] 反応するコマンドの表記
# @param round_type [Symbol] 除算での端数の扱い
def initialize(*notations, round_type:)
  super()
  @notations = notations
  @round_type = round_type
  @prefix_number = false
  @suffix_number = false
  @need_prefix_number = false
  @need_suffix_number = false
  @modifier = true
  @critical = false
  @fumble = false
  @dollar = false
  @ampersand = false
  @allowed_cmp_op = [nil, :>=, :>, :<=, :<, :==, :!=]
  @question_target = false
end

# 修正値は受け付けないようにする
# @return [BCDice::Command::Parser]
def disable_modifier
  @modifier = false
  self
end

# リテラルの前に数値を許可する
# @return [BCDice::Command::Parser]
def enable_prefix_number
  @prefix_number = true
  self
end

# リテラルの後ろに数値を許可する
# @return [BCDice::Command::Parser]
def enable_suffix_number
  @suffix_number = true
  self
end

# リテラルの前に数値が必要であると設定する
# @return [BCDice::Command::Parser]
def has_prefix_number
  @prefix_number = true
  @need_prefix_number = true
  self
end

# リテラルの後ろに数値が必要であると設定する
# @return [BCDice::Command::Parser]
def has_suffix_number
  @suffix_number = true
  @need_suffix_number = true
  self
end

# +@+によるクリティカル値の指定を許可する
# @return [BCDice::Command::Parser]
def enable_critical
  @critical = true
  self
end

# +#+によるファンブル値の指定を許可する
# @return [BCDice::Command::Parser]
def enable_fumble
  @fumble = true
  self
end

# +$+による値の指定を許可する
# @return [BCDice::Command::Parser]
def enable_dollar
  @dollar = true
  self
end

# +&+による値の指定を許可する
# @return [BCDice::Command::Parser]
def enable_ampersand
  @ampersand = true
  self
end

# 使用できる比較演算子を制限する。
# 目標値未入力を許可する場合には+nil+を指定する。
# @param ops [Array<nil, Symbol>] 許可する比較演算子の一覧
# @return [BCDice::Command::Parser]
def restrict_cmp_op_to(*ops)
  @allowed_cmp_op = ops
  self
end

# 目標値"?"の指定を許可する
# @return [BCDice::Command::Parser]
def enable_question_target
  @question_target = true
  self
end

# @param source [String]
# @return [BCDice::Command::Parsed, nil]
def parse(source)
  @lexer = Lexer.new(source, @notations)
  do_parse()
rescue ParseError, ZeroDivisionError
  nil
end

private

def parsed(notation, option, modifier, target)
  Parsed.new.tap do |p|
    p.command = notation[:command]
    p.prefix_number = notation[:prefix]&.eval(@round_type)
    p.suffix_number = notation[:suffix]&.eval(@round_type)
    p.critical = option[:critical]&.eval(@round_type)
    p.fumble = option[:fumble]&.eval(@round_type)
    p.dollar = option[:dollar]&.eval(@round_type)
    p.ampersand = option[:ampersand]&.eval(@round_type)
    p.modify_number = modifier.eval(@round_type)
    p.cmp_op = target[:cmp_op]
    if target[:target] == "?"
      p.question_target = true
      p.target_number = 0
    else
      p.question_target = false
      p.target_number = target[:target]&.eval(@round_type)
    end
  end
end

def next_token
  @lexer.next_token
end
