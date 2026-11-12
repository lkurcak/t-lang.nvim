-- Indentation for T, as `t fmt` lays code out: one level more after a line
-- that opens a bracket or ends a `match` arm's `=>`, one less on a line that
-- closes one. Set as 'indentexpr' by indent/t.lua.
local M = {}

-- Line `lnum` with any comment cut off and trailing space trimmed. A `//`
-- in a string, `"http://x"`, isn't a comment, nor is a `"` in a character,
-- `'"'`, a string's start.
local function code(lnum)
  local line = vim.fn.getline(lnum)
  local i, in_string = 1, false
  while i <= #line do
    local c = line:sub(i, i)
    if in_string then
      if c == "\\" then
        i = i + 1
      elseif c == '"' then
        in_string = false
      end
    elseif c == '"' then
      in_string = true
    elseif line:find("^'\\.'", i) then
      i = i + 3
    elseif line:find("^'.'", i) then
      i = i + 2
    elseif line:sub(i, i + 1) == "//" then
      line = line:sub(1, i - 1)
      break
    end
    i = i + 1
  end
  return (line:gsub("%s+$", ""))
end

local function opens(line)
  return line:match("[{(%[]$") ~= nil
end

function M.get()
  local lnum = vim.v.lnum
  local prev = vim.fn.prevnonblank(lnum - 1)
  if prev == 0 then
    return 0
  end
  local sw = vim.fn.shiftwidth()
  local ind = vim.fn.indent(prev)
  local before = code(prev)
  if opens(before) or before:match("=>$") then
    ind = ind + sw
  else
    -- After a `match` arm's body on a line of its own, back to the arm.
    local arm = vim.fn.prevnonblank(prev - 1)
    if arm > 0 and code(arm):match("=>$") then
      ind = ind - sw
    end
  end
  if vim.fn.getline(lnum):match("^%s*[}%)%]]") then
    ind = ind - sw
  end
  return math.max(ind, 0)
end

return M
