-- Neovim detects `.t` as TADS by default; claim it. This lives in plugin/
-- rather than ftdetect/ because ftdetect/ is only read when filetype detection
-- is first enabled, which may happen before this directory joins 'runtimepath'.
vim.filetype.add({ extension = { t = "t" } })

vim.lsp.enable("t")

-- `:TInstallParser [path]` builds T's tree-sitter parser and installs it, with
-- its highlight queries, where Neovim looks for them. It takes the grammar
-- from GitHub, that of the release of the `t` on $PATH if it can, so that
-- what's highlighted matches what `t` accepts, or from a t-lang checkout at
-- `path`. Needs a C compiler ($CC, or `cc`), and git unless given a path.
vim.api.nvim_create_user_command("TInstallParser", function(opts)
  local function fail(msg)
    vim.notify("TInstallParser: " .. msg, vim.log.levels.ERROR)
  end
  local function run(cmd)
    local r = vim.system(cmd, { text = true }):wait()
    if r.code ~= 0 then
      fail(table.concat(cmd, " ") .. "\n" .. (r.stderr or ""))
      return false
    end
    return true
  end

  local repo = opts.args ~= "" and vim.fs.normalize(opts.args) or nil
  local tmp
  if not repo then
    tmp = vim.fn.tempname()
    local url = "https://github.com/lkurcak/t-lang"
    local ok, version = pcall(function()
      local r = vim.system({ "t", "--version" }, { text = true }):wait()
      return r.code == 0 and r.stdout:match("^t (%S+)") or nil
    end)
    local tag = ok and version and ("v" .. version) or nil
    local cloned = false
    if tag then
      vim.notify("TInstallParser: fetching the grammar of t " .. version .. " from GitHub...")
      local r = vim.system({ "git", "clone", "--depth", "1", "--branch", tag, url, tmp }):wait()
      cloned = r.code == 0
    end
    if not cloned then
      local why = tag and ("no tag " .. tag .. ", so ") or ""
      vim.notify("TInstallParser: " .. why .. "fetching the newest grammar from GitHub...")
      vim.fn.delete(tmp, "rf")
      if not run({ "git", "clone", "--depth", "1", url, tmp }) then
        return
      end
    end
    repo = tmp
  end
  local grammar = repo .. "/editors/tree-sitter-t"
  if vim.fn.filereadable(grammar .. "/src/parser.c") == 0 then
    return fail("no grammar in " .. grammar)
  end

  local site = vim.fn.stdpath("data") .. "/site"
  vim.fn.mkdir(site .. "/parser", "p")
  vim.fn.mkdir(site .. "/queries/t", "p")
  local ok = run({
    vim.env.CC or "cc", "-shared", "-fPIC", "-O2",
    "-I", grammar .. "/src", grammar .. "/src/parser.c",
    "-o", site .. "/parser/t.so",
  })
  if ok then
    ok = vim.uv.fs_copyfile(grammar .. "/queries/highlights.scm", site .. "/queries/t/highlights.scm")
    if not ok then
      fail("could not copy the highlight queries")
    end
  end
  if tmp then
    vim.fn.delete(tmp, "rf")
  end
  if not ok then
    return
  end

  -- Neovim caches what's on 'runtimepath', and leaves out `site` if it
  -- didn't exist at startup: setting the option again refreshes both, so
  -- the new queries are found. Then highlight the T files already open.
  if not vim.tbl_contains(vim.opt.runtimepath:get(), site) then
    vim.opt.runtimepath:append(site)
  else
    vim.o.runtimepath = vim.o.runtimepath
  end
  vim.treesitter.language.add("t", { path = site .. "/parser/t.so" })
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.bo[buf].filetype == "t" then
      pcall(vim.treesitter.start, buf)
    end
  end
  vim.notify("TInstallParser: installed")
end, { nargs = "?", complete = "dir", desc = "Build and install the tree-sitter parser for T" })
