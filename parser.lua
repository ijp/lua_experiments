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

function dump_ast(tree)
   function dump(tree,level)
      if tree.type == "name" then
         io.write(string.rep(" ",level),"name: ",tree.value,"\n")
      elseif tree.type == "prefix" then
         io.write(string.rep(" ",level),"prefix: ", tree.operator, "\n")
         dump(tree.argument, level+2)
      elseif tree.type == "infix" then
         io.write(string.rep(" ",level),"infix: ", tree.operator, "\n")
         dump(tree.left, level+2)
         dump(tree.right, level+2)
      else
         error("not an ast value")
      end
   end
   dump(tree,0)
end

-- precedences
precedence = {}
prec_min = 0

-- prefix parsing
prefix_parsers = {}

function prefix(name,prec)      -- useful for "simple" parsers
   local function make_prefix_expr (name_token)
      local next = parse_expression(prec)
      return prefix_expr(name, next)
   end
   prefix_parsers[name] = make_prefix_expr
   precedence[name] = prec
end

prefix_parsers["name"] = name_expr
precedence["name"] = 0 -- what is the correct precedence for these?

prefix_parsers["("] =
   function (tok)
      local expr = parse_expression(prec_min)
      expect(")")
      return expr
   end
precedence["("] = 70
precedence[")"] = 70

prefix("~",60)

-- infix parsing
infix_parsers = {}

function binop(name, prec)      -- useful for simple parsers
   local function parser (left, operator)
      -- associates to the left
      local right = parse_expression(prec)
      return infix_expr(name, left, right)
   end
   infix_parsers[name] = parser
   precedence[name] = prec
end

binop("&", 50)
binop("|", 40)
binop("=>", 30)
binop("<=>", 20)

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
-- advance = make_lexer("a & b & c")
-- advance = make_lexer("a & b <=> b")
-- advance = make_lexer("(a)")
-- advance = make_lexer("a & b | c & d")
-- advance = make_lexer("a & (b | c) & d")
-- advance = make_lexer("(~c => ~~d)")
-- advance = make_lexer("a & b <=> c | d | e")
-- advance = make_lexer("a & b <=> b | (~c => ~~d) | e")

function retreat(val)
   local old = advance
   local function next ()
      advance = old
      return val
   end
   advance = next
end

function parse_expression(prec)
   local token = advance()
   local prefix = prefix_parsers[token.type]

   if not prefix then
      error("not a valid prefix: "..token.value)
   end

   local left = prefix(token)
   local next = advance()

   while (next and prec < precedence[next.type]) do
      local infix = infix_parsers[next.type]

      if not infix then         -- necessary?
         retreat(next)
         return left
      end
      
      left = infix(left,next)
      next = advance()
   end

   if next then         -- necessary?
      retreat(next)
   end
   return left
end

function parse()
   return parse_expression(prec_min)
end
