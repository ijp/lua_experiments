-- A simple boolean expression parser, written to test out top-down
-- operator precedence parsing

function name(str)
   return { type="name", value=str }
end

function punctuation(p)
   return { type="punctuation", value=p }
end

-- dumb handwritten lexer
function make_lexer(str)
   local i = 1
   local l = string.len(str)
   local function next()
      if i > l then
         return nil
      end
      
      local start,finish = string.find(str, "^[%l%u]+", i) -- use match?
      if start then
         i = finish + 1
         return name(string.sub(str,start,finish))
      end

      start,finish = string.find(str,"=>", i)
      if start then
         i = finish + 1
         return punctuation("=>")
      end
      
      start,finish = string.find(str,"^<=>", i)
      if start then
         i = finish + 1
         return punctuation("^<=>")
      end

      start,finish = string.find(str,"^&", i)
      if start then
         i = finish + 1
         return punctuation("^&")
      end

      start,finish = string.find(str,"^|", i)
      if start then
         i = finish + 1
         return punctuation("|")
      end

      start,finish = string.find(str,"^~", i)
      if start then
         i = finish + 1
         return punctuation("~")
      end

      start,finish = string.find(str,"^%(", i)
      if start then
         i = finish + 1
         return punctuation("(")
      end

      start,finish = string.find(str,"^%)", i)
      if start then
         i = finish + 1
         return punctuation(")")
      end
      
      -- whitespace is tested last so I can just tailcall next.
      start,finish = string.find(str,"^%s+", i)
      if start then
         i = finish + 1
         return next()
      else
         error("can't lex:"..string.sub(str,i,l))
      end
   end
   return next
end


function lex_string(str)
   local result = {}
   local i = 1
   for token in make_lexer(str) do
      result[i] = token
      i = i+1
   end
   return result
end

function run_tests(table)
   local function different(array1, array2)
      for i,v in ipairs(array2) do
         if array1[1].value ~= v then
            return false
         end
      end
      return true
   end
   for string, expected in pairs(table) do
      if different(lex_string(string), expected) then
         error("failed to lex:"..str)
      end
   end
   print("yep, all fine")
   return true
end

tests = {}
tests["just a bunch of words"] = {"just","a","bunch","of","words"}
tests["just a bunch of words & the occasional &"] ={"just","a","bunch","of","words",
                                                    "&", "the", "occasional", "&"}
tests["lots    of\t\t\n whitespace   \n\n\n\n "] ={"lots","of","whitespace"}
tests["(&~|))&&~|=>(<=>|&|~=>"]={"(","&","~","|",")",")","&","&","~","|","=>","(",
                                 "<=>","|","&","|","~","=>"}

run_tests(tests)
