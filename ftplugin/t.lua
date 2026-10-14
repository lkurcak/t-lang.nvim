vim.bo.commentstring = "// %s"

-- Syntax highlighting, once the parser is installed (`:TInstallParser`).
pcall(vim.treesitter.start)
