class BCDice::CommonCommand::AddDice::Parser
token NUMBER CMP_OP S D K H L U R PLUS MINUS ASTERISK SLASH PARENL PARENR QUESTION

rule
  command: secret add
         {
           secret, lhs = val
           raise ParseError unless lhs.include_dice?

           result = Node::Command.new(secret, lhs)
         }
         | secret add CMP_OP target
         {
           secret, lhs, cmp_op, rhs = val
           raise ParseError if !lhs.include_dice? || rhs.include_dice? || cmp_op.nil?

           result = Node::Command.new(secret, lhs, cmp_op, rhs)
         }

  secret: /* none */
        { result = false }
        | S
        { result = true }

  target: add
        | QUESTION
        { result = Node::UndecidedTarget.instance }

  add: add PLUS mul
     {
      lhs = val[0]
      op, rhs = expand_negate(:+, val[2])
      result = Node::BinaryOp.new(lhs, op, rhs)
     }
     | add MINUS mul
     {
      lhs = val[0]
      op, rhs = expand_negate(:-, val[2])
      result = Node::BinaryOp.new(lhs, op, rhs)
     }
     | mul

  mul: mul ASTERISK unary
     {
      lhs = val[0]
      rhs = val[2]
      result = Node::BinaryOp.new(lhs, :*, rhs)
     }
     | mul SLASH unary round_type
     {
       lhs = val[0]
       rhs = val[2]
       divied_class = val[3]
       result = divied_class.new(lhs, rhs)
     }
     | unary

  round_type: /* none */
            { result = Node::DivideWithRoundingDown }
            | U
            { result = Node::DivideWithRoundingUp }
            | R
            { result = Node::DivideWithRoundingOff }

  unary: PLUS unary
       { result = val[1] }
       | MINUS unary
       {
         body = val[1]
         result = body.is_a?(Node::Negate) ? body.body : Node::Negate.new(body)
       }
       | dice

  dice: term D term
      {
        times = val[0]
        sides = val[2]
        raise ParseError if times.include_dice? || sides.include_dice?

        result = Node::DiceRoll.new(times, sides)
      }
      | term D term filter_type term
      {
        times = val[0]
        sides = val[2]
        filter = val[3]
        n_filtering = val[4]
        raise ParseError if times.include_dice? || sides.include_dice? || n_filtering.include_dice?

        result = Node::DiceRollWithFilter.new(times, sides, n_filtering, filter)
      }
      | term

  filter_type: K H
             { result = Node::DiceRollWithFilter::KEEP_HIGHEST }
             | K L
             { result = Node::DiceRollWithFilter::KEEP_LOWEST }
             | D H
             { result = Node::DiceRollWithFilter::DROP_HIGHEST }
             | D L
             { result = Node::DiceRollWithFilter::DROP_LOWEST }

  term: PARENL add PARENR
      { result = Node::Parenthesis.new(val[1]) }
      | NUMBER
      { result = Node::Number.new(val[0]) }
end

---- header

require "bcdice/common_command/lexer"
require "bcdice/common_command/add_dice/node"

---- inner

include CommonCommand::Lexer

def self.parse(source)
  new.parse(source)
end

def parse(source)
  init_lexer(source)
  do_parse()
rescue ParseError
  nil
end

private

# 加減算の右辺が負数である場合に加減算を逆転させる
def expand_negate(op, rhs)
  if rhs.is_a?(Node::Negate)
    if op == :+
      return [:-, rhs.body]
    elsif op == :-
      return [:+, rhs.body]
    end
  end

  [op, rhs]
end

