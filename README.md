# t-lang.nvim

Neovim support for [T](https://github.com/lkurcak/t-lang): `.t` filetype
detection, comment settings, and the `t lsp` language server.

## Install

Requires Neovim 0.11+ and the `t` binary on your `$PATH`:

```sh
cargo install --git https://github.com/lkurcak/t-lang
```

Then add the plugin:

```lua
vim.pack.add({ "https://github.com/lkurcak/t-lang.nvim" })  -- Neovim 0.12+
```

or with lazy.nvim:

```lua
{ "lkurcak/t-lang.nvim" }
```

No `setup()` call is needed. Errors show up as you type, and you can jump
between them with `]d` / `[d`.
