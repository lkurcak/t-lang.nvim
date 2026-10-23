-- Neovim detects `.t` as TADS by default; claim it. This lives in plugin/
-- rather than ftdetect/ because ftdetect/ is only read when filetype detection
-- is first enabled, which may happen before this directory joins 'runtimepath'.
vim.filetype.add({ extension = { t = "t" } })

vim.lsp.enable("t")

-- `:TInstallParser [path]` installs T's tree-sitter parser and highlight
-- queries, those of the `t` on $PATH, or builds them from a t-lang checkout
-- at `path` (with $CC, or `cc`). Opening a T file does it for you, the first
-- time and after upgrading `t`; see lua/t_lang/parser.lua.
vim.api.nvim_create_user_command("TInstallParser", function(opts)
  require("t_lang.parser").install(opts.args ~= "" and vim.fs.normalize(opts.args) or nil)
end, { nargs = "?", complete = "dir", desc = "Install the tree-sitter parser for T" })
