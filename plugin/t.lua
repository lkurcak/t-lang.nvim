-- Neovim detects `.t` as TADS by default; claim it. This lives in plugin/
-- rather than ftdetect/ because ftdetect/ is only read when filetype detection
-- is first enabled, which may happen before this directory joins 'runtimepath'.
vim.filetype.add({ extension = { t = "t" } })

vim.lsp.enable("t")
