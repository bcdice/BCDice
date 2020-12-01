class BCDice::CommonCommand::RerollDice::Parser
  token NUMBER R U C F S PLUS MINUS ASTERISK SLASH PARENL PARENR BRACKETL BRACKETR LESS GREATER EQUAL NOT AT CMP_OP

  rule
    expr: secret notations target
        {
          result = Node::Command.new(
            secret: val[0],
            notations: val[1],
            cmp_op: val[2][:cmp_op],
            target_number: val[2][:target],
            source: @lexer.source
          )
        }
        | secret notations bracket target
        {
          target = val[3]
          threshold = val[2]
          result = Node::Command.new(
            secret: val[0],
            notations: val[1],
            cmp_op: target[:cmp_op],
            target_number: target[:target],
            reroll_cmp_op: threshold[:cmp_op],
            reroll_threshold: threshold[:threshold],
            source: @lexer.source
          )
        }
        | secret notations target at
        {
          target = val[2]
          threshold = val[3]
          result = Node::Command.new(
            secret: val[0],
            notations: val[1],
            cmp_op: target[:cmp_op],
            target_number: target[:target],
            reroll_cmp_op: threshold[:cmp_op],
            reroll_threshold: threshold[:threshold],
            source: @lexer.source
          )
        }

    secret: /* none */
          { result = false }
          | S
          { result = true }

    target: /* none */
          { result = {} }
          | CMP_OP term
          {
            cmp_op, target = val
            raise ParseError unless cmp_op

            result = {cmp_op: cmp_op, target: target}
          }

    bracket: BRACKETL add BRACKETR
           { result = {threshold: val[1]}  }
           | BRACKETL CMP_OP add BRACKETR
           {
             cmp_op = val[1]
             threshold = val[2]
             raise ParseError unless cmp_op

             result = {cmp_op: cmp_op, threshold: threshold}
           }

    at: AT add
      { result = {threshold: val[1]} }
      | AT CMP_OP add
      {
        cmp_op = val[1]
        threshold = val[2]
        raise ParseError unless cmp_op

        result = {cmp_op: cmp_op, threshold: threshold}
      }

    notations: notations PLUS dice
             {
               notations = val[0]
               notations.push(val[2])
               result = notations
             }
             | dice
             { result = [val[0]] }

    dice: term R term
        {
          times = val[0]
          sides = val[2]
          result = Node::Notation.new(times, sides)
        }

    add: add PLUS mul
       { result = Arithmetic::Node::BinaryOp(val[0], :+, val[2]) }
       | add MINUS mul
       { result = Arithmetic::Node::BinaryOp(val[0], :-, val[2]) }
       | mul

    mul: mul ASTERISK unary
       { result = Arithmetic::Node::BinaryOp(val[0], :*, val[2]) }
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
require "bcdice/common_command/reroll_dice/node"
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
