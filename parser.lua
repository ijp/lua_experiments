-- A simple experiment in "Top Down Operator Precedence" Parsing

-- AST constructors
function name_expr (token)
   return {type="name", value=token.value}
end

function prefix_expr (op, expr)
   return {type="prefix", operator=op, argument=expr}
end

function infix_expr (op, left, right)
   return {type="infix", operator=op, left=left, right=right}
end

-- prefix parsing
prefix_parsers = {}

function prefix(name)           -- useful for "simple" parsers
   local function make_prefix_expr (name_token)
      -- doesn't currently parse "right", since we don't have precedence yet
      local next = parse_expression()
      return prefix_expr(name, next)
   end
   prefix_parsers[name] = make_prefix_expr
end

prefix_parsers["name"] = name_expr

prefix_parsers["("] =
   function (tok)
      local expr = parse_expression()
      expect(")")
      return expr
   end

prefix("~")

-- infix parsing
infix_parsers = {}

function binop(name)            -- useful for simple parsers
   local function parser (left, operator)
      local right = parse_expression()
      return infix_expr(name, left, right)
   end
   infix_parsers[name] = parser
end

binop("&")
binop("|")
binop("=>")
binop("<=>")
-- the parser itself
function expect(type)
   local token = advance()
   if not token then
      error("expected type: "..type.." got: EOF")
   elseif token.type == type then
      return token
   else
      error("expected type: "..type.." got: "..token.type)
   end
end

-- advance = make_lexer("a & b")
-- advance = make_lexer("a & b <=> b")
-- advance = make_lexer("(a)")
-- advance = make_lexer("(~c => ~~d)")
-- advance = make_lexer("a & b <=> c | d | e")
advance = make_lexer("a & b <=> b | (~c => ~~d) | e")

function retreat(val)
   local old = advance
   local function next ()
      advance = old
      return val
   end
   advance = next
end

function parse_expression()
   local token = advance()
   local prefix = prefix_parsers[token.type]

   if not prefix then
      error("not a valid prefix: "..token.value)
   end

   local left = prefix(token)
   local next = advance()

   if not next then
      return left
   end

   local infix = infix_parsers[next.type]

   if not infix then
      retreat(next)
      return left
   end
   
   return infix(left,next)

end
