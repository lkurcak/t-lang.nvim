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

No `setup()` call is needed. Code is indented with four spaces as you type,
the way `t fmt` lays it out, and pressing Enter in a comment continues it,
`///` doc comments included. Errors and warnings show up as you type, and you
can jump between them with `]d` / `[d`. Many come with a fix: press `gra` (code
action) to apply it, like removing a `match` arm that can never run. Code that
can never run is also shown faded.

`K` shows the type of what's under the cursor, and `<C-]>` jumps to where it's
defined. With Neovim's default keys:

- `grr` lists every use of it,
- `grn` renames it everywhere, unless the new name would change what some
  name refers to, in which case it says which,
- `grt` (Neovim 0.12+) jumps to the struct or enum of its type,
- `gO` shows an outline of the file.

To turn a warning off, put `#[allow(..)]` with its lint's name before the
`fn`, `struct`, `enum`, field or variant it's in. Each warning's lint is
shown as its code.

The language server can also highlight the other uses of what's under the
cursor. Neovim leaves that to you; this does it when the cursor rests:

```lua
vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(ev)
    local client = vim.lsp.get_client_by_id(ev.data.client_id)
    if not client or not client:supports_method("textDocument/documentHighlight") then
      return
    end
    vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
      buffer = ev.buf,
      callback = vim.lsp.buf.document_highlight,
    })
    vim.api.nvim_create_autocmd("CursorMoved", {
      buffer = ev.buf,
      callback = vim.lsp.buf.clear_references,
    })
  end,
})
```

The language server can also show the types it inferred, and the type
arguments of generic functions, as inlay hints. Neovim leaves those off
unless you turn them on:

```lua
vim.lsp.inlay_hint.enable()
```

## Syntax highlighting

Run `:TInstallParser` once, and again whenever you upgrade `t` and T's
grammar has changed, as it did in t-lang 0.5.0 for references and lifetimes.
It fetches the grammar of the `t` you have from GitHub (or the newest, if
that version isn't tagged), builds it with your C compiler (`$CC`, or
`cc`), and installs it with its highlight queries into Neovim's `site`
directory. To build it from a t-lang checkout instead, pass its path:
`:TInstallParser ~/src/t-lang`.
