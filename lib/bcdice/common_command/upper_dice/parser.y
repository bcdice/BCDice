class BCDice::CommonCommand::UpperDice::Parser
  token NUMBER R U C F S PLUS MINUS ASTERISK SLASH PARENL PARENR BRACKETL BRACKETR LESS GREATER EQUAL NOT AT CMP_OP

  rule
    expr: secret notations modifier target
        {
          result = UpperDice::Node::Command.new(
            secret: val[0],
            notations: val[1],
            modifier: val[2],
            cmp_op: val[3][:cmp_op],
            target_number: val[3][:target]
          )
        }
        | secret notations bracket modifier target
        {
          result = UpperDice::Node::Command.new(
            secret: val[0],
            notations: val[1],
            modifier: val[3],
            cmp_op: val[4][:cmp_op],
            target_number: val[4][:target],
            reroll_threshold: val[2]
          )
        }
        | secret notations modifier target at
        {
          result = UpperDice::Node::Command.new(
            secret: val[0],
            notations: val[1],
            modifier: val[2],
            cmp_op: val[3][:cmp_op],
            target_number: val[3][:target],
            reroll_threshold: val[4]
          )
        }

    secret: /* none */
          { result = false }
          | S
          { result = true }

    modifier: /* none */
            { result = Arithmetic::Node::Number.new(0) }
            | PLUS add
            { result = val[1] }
            | MINUS add
            { result = Arithmetic::Node::Negative.new(val[1]) }

    target: /* none */
          { result = {} }
          | CMP_OP add
          {
            cmp_op, target = val
            raise ParseError unless cmp_op

            result = {cmp_op: cmp_op, target: target}
          }

    bracket: BRACKETL add BRACKETR
           { result = val[1] }

    at: AT add
      { result = val[1] }

    notations: notations PLUS dice
             {
               notations = val[0]
               notations.push(val[2])
               result = notations
             }
             | dice
             { result = [val[0]] }

    dice: term U term
        {
          times = val[0]
          sides = val[2]
          result = UpperDice::Node::Notation.new(times, sides)
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

require "bcdice/common_command/lexer"
require "bcdice/common_command/upper_dice/node"
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
