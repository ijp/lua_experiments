-- A simple boolean expression parser, written to test out top-down
-- operator precedence parsing

local function pair(a,d)
   return {pattern=a, func=d}
end

local function name(str)
   return { type="name", value=str }
end

local function punctuation(p)
   return { type=p, value=p }
end

local function build_lexer(rules, eof, skip_unhandled)
   local function make_lexer(str)
      local i = 1
      local l = string.len(str)
      local function next()
         if i > l then
            return eof
         end

         for _, pair in ipairs(rules) do
            local start,finish = string.find(str,pair.pattern, i)
            if start then
               i = finish + 1
               return pair.func(string.sub(str,start,finish))
            end
         end

         -- it would be nicer if I added rules for skipping, so that I
         -- could handle e.g. a chunk of whitespace at once
         if skip_unhandled then
            i = i+1
            return next()
         else       
            error("can't lex:"..string.sub(str,i,l))
         end
      end
      return next
   end

   return make_lexer
end


local function new ()
   local builder = {
      eofval = nil,
      skip = true,
      rules = {}
   }
   
   builder.rule = function (_, pattern, func)
                     table.insert(builder.rules, pair(pattern, func))
                  end
   
   builder.eof = function (_, val)
                    builder.eofval = val
                 end

   builder.build = function (this)
                      return build_lexer(builder.rules, builder.eofval, builder.skip)
                   end

   return builder
end

local lb = new()
lb:rule("^[%l%u]+", name)
lb:rule("^=>", punctuation)
lb:rule("^<=>", punctuation)
lb:rule("^&", punctuation)
lb:rule("^|", punctuation)
lb:rule("^~", punctuation)
lb:rule("^%(", punctuation)
lb:rule("^%)", punctuation)
lb:rule("^=>", punctuation)

local make_lexer = lb:build()

local function lex_string(str)
   local result = {}
   local i = 1
   for token in make_lexer(str) do
      result[i] = token
      i = i+1
   end
   return result
end

local function run_tests()
   local function different(array1, array2)
      for i,v in ipairs(array2) do
         if array1[1].value ~= v then
            return false
         end
      end
      return true
   end
   for string, expected in pairs(tests) do
      if different(lex_string(string), expected) then
         error("failed to lex:"..str)
      end
   end
   print("yep, all fine")
   return true
end

local tests = {}
tests["just a bunch of words"] = {"just","a","bunch","of","words"}
tests["just a bunch of words & the occasional &"] ={"just","a","bunch","of","words",
                                                    "&", "the", "occasional", "&"}
tests["lots    of\t\t\n whitespace   \n\n\n\n "] ={"lots","of","whitespace"}
tests["(&~|))&&~|=>(<=>|&|~=>"]={"(","&","~","|",")",")","&","&","~","|","=>","(",
                                 "<=>","|","&","|","~","=>"}

return {new=new, make_lexer=make_lexer, run_tests=run_tests}
