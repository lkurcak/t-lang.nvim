# t-lang.nvim

Neovim support for [T](https://github.com/lkurcak/t-lang): `.t` filetype
detection, comment settings, the `t lsp` language server, and tree-sitter
syntax highlighting.

## Install

Requires Neovim 0.11+ and the `t` binary on your `$PATH`:

```sh
cargo install t-lang
```

Then add the plugin:

```lua
vim.pack.add({ "https://github.com/lkurcak/t-lang.nvim" })  -- Neovim 0.12+
```

or with lazy.nvim:

```lua
{ "lkurcak/t-lang.nvim" }
```

No `setup()` call is needed. Errors and warnings show up as you type, and you
can jump between them with `]d` / `[d`. Many come with a fix: press `gra` (code
action) to apply it, like removing a `match` arm that can never run. Code that
can never run is also shown faded.

`K` shows the type of what's under the cursor, and `<C-]>` jumps to where it's
defined.

The language server can also show the types it inferred, and the type
arguments of generic functions, as inlay hints. Neovim leaves those off
unless you turn them on:

```lua
vim.lsp.inlay_hint.enable()
```

## Syntax highlighting

Run `:TInstallParser` once, and again whenever T's grammar changes. It
fetches the grammar from GitHub, builds it with your C compiler (`$CC`, or
`cc`), and installs it with its highlight queries into Neovim's `site`
directory. To build it from a t-lang checkout instead, pass its path:
`:TInstallParser ~/src/t-lang`.
