-- Indentation for T, as `t fmt` lays code out: one level more after a line
-- that opens a bracket or ends a `match` arm's `=>`, one less on a line that
-- closes one. Set as 'indentexpr' by indent/t.lua.
local M = {}

-- Line `lnum` with any comment cut off and trailing space trimmed. T has no
-- strings, so a `//` always starts a comment.
local function code(lnum)
  local line = vim.fn.getline(lnum)
  return (line:gsub("//.*$", ""):gsub("%s+$", ""))
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
