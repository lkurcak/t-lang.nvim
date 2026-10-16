if vim.b.did_indent then
  return
end
vim.b.did_indent = true

vim.bo.indentexpr = "v:lua.require't_lang.indent'.get()"
-- Indent new lines, and a line again when it starts with a closing bracket.
vim.bo.indentkeys = "0},0),0],!^F,o,O"
vim.b.undo_indent = "setlocal indentexpr< indentkeys<"
