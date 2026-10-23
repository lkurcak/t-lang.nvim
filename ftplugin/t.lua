vim.bo.commentstring = "// %s"

-- Four spaces, as `t fmt` indents.
vim.bo.expandtab = true
vim.bo.shiftwidth = 4
vim.bo.softtabstop = 4

-- Pressing Enter (or `o`) in a comment continues it, `///` doc comments
-- included, and joining comment lines drops the `//` in between.
vim.bo.comments = ":///,://"
vim.opt_local.formatoptions:append("croqj")

-- Syntax highlighting. The first T file installs the parser, if it's missing
-- or was installed for another version of `t`, and highlights the T files
-- open once that's done.
if require("t_lang.parser").ensure() then
  pcall(vim.treesitter.start)
end
