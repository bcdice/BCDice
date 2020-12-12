class BCDice::CommonCommand::Calc::Parser
  token NUMBER R U C F S PLUS MINUS ASTERISK SLASH PARENL PARENR

  rule
    expr: secret C add
        {
          result = Node::Command.new(
            secret: val[0],
            expr: val[2]
          )
        }

    secret: /* none */
          { result = false }
          | S
          { result = true }

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

require "bcdice/common_command/lexer"
require "bcdice/common_command/calc/node"
require "bcdice/arithmetic/node"

---- inner

def self.parse(source)
  new.parse(source)
end

def parse(source)
  @lexer = Lexer.new(source)
  do_parse()
rescue ParseError
  nil
end

private

def next_token
  @lexer.next_token
end
