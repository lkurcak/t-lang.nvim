-- T's tree-sitter parser and highlight queries, installed into Neovim's
-- `site` directory: by `t tree-sitter`, which carries those of its own
-- build and leaves them alone if they're already there, so it runs on the
-- first T file of every session; or, for a `t` older than that, built from
-- the grammar on GitHub or in a t-lang checkout. Then `parser-info/t.version`
-- records the `t` they were built for, so they're built again after
-- upgrading it.

local M = {}

local site = vim.fn.stdpath("data") .. "/site"
local so = site .. "/parser/t.so"
local stamp = site .. "/parser-info/t.version"

local function notify(msg, level)
  vim.notify("T: " .. msg, level)
end

-- The version of the `t` on $PATH, or nil if there's none.
local function t_version()
  if vim.fn.executable("t") == 0 then
    return nil
  end
  local ok, r = pcall(function()
    return vim.system({ "t", "--version" }, { text = true }):wait()
  end)
  return ok and r.code == 0 and r.stdout:match("^t (%S+)") or nil
end

-- Runs `cmd` from inside a coroutine, which waits for it without blocking
-- the editor, and resumes on the main loop so it can call any API.
local function run(cmd)
  local co = coroutine.running()
  vim.system(cmd, { text = true }, function(r)
    vim.schedule(function()
      coroutine.resume(co, r)
    end)
  end)
  return coroutine.yield()
end

local function check(r, cmd)
  if r.code ~= 0 then
    error(table.concat(cmd, " ") .. "\n" .. (r.stderr or ""), 0)
  end
end

-- Builds the grammar in `repo` (a t-lang checkout) into `site`.
local function build(repo)
  local grammar = repo .. "/editors/tree-sitter-t"
  if vim.fn.filereadable(grammar .. "/src/parser.c") == 0 then
    error("no grammar in " .. grammar, 0)
  end
  vim.fn.mkdir(site .. "/parser", "p")
  vim.fn.mkdir(site .. "/queries/t", "p")
  -- Build beside the parser and rename it over, rather than overwrite it:
  -- changing a parser this Neovim has loaded under it can crash it.
  local cmd = {
    vim.env.CC or "cc", "-shared", "-fPIC", "-O2",
    "-I", grammar .. "/src", grammar .. "/src/parser.c",
    "-o", so .. ".tmp",
  }
  check(run(cmd), cmd)
  assert(vim.uv.fs_rename(so .. ".tmp", so))
  if not vim.uv.fs_copyfile(grammar .. "/queries/highlights.scm", site .. "/queries/t/highlights.scm") then
    error("could not copy the highlight queries", 0)
  end
end

-- Fetches the grammar of t `version` from GitHub (or the newest, if that
-- version isn't tagged, or is nil), and builds it.
local function build_from_github(version)
  local url = "https://github.com/lkurcak/t-lang"
  local tmp = vim.fn.tempname()
  local ok, err = pcall(function()
    local cloned = false
    if version then
      notify("fetching the grammar of t " .. version .. " from GitHub...")
      cloned = run({ "git", "clone", "--depth", "1", "--branch", "v" .. version, url, tmp }).code == 0
    end
    if not cloned then
      local why = version and ("no tag v" .. version .. ", so ") or ""
      notify(why .. "fetching the newest grammar from GitHub...")
      vim.fn.delete(tmp, "rf")
      local cmd = { "git", "clone", "--depth", "1", url, tmp }
      check(run(cmd), cmd)
    end
    build(tmp)
  end)
  vim.fn.delete(tmp, "rf")
  if not ok then
    error(err, 0)
  end
end

local installing = false

-- Whether this Neovim has loaded a parser for T.
local function loaded()
  return vim._ts_has_language ~= nil and vim._ts_has_language("t")
end

-- Neovim caches what's on 'runtimepath', and leaves out `site` if it didn't
-- exist at startup: setting the option again refreshes both, so newly
-- installed queries are found.
local function refresh_runtimepath()
  if not vim.tbl_contains(vim.opt.runtimepath:get(), site) then
    vim.opt.runtimepath:append(site)
  else
    vim.o.runtimepath = vim.o.runtimepath
  end
end

-- Highlights the T buffers already open with the parser just installed,
-- unless this Neovim had already loaded an older one: a loaded parser can't
-- be swapped for another, so that takes a restart.
local function start(was_loaded)
  refresh_runtimepath()
  if was_loaded then
    return
  end
  vim.treesitter.language.add("t", { path = site .. "/parser/t.so" })
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.bo[buf].filetype == "t" then
      pcall(vim.treesitter.start, buf)
    end
  end
end

--- Installs the parser and queries, in the background: those of the `t` on
--- $PATH, or, given `repo`, built from that t-lang checkout. Says when it's
--- done unless `quiet`, and always if it fails.
---@param repo string?
---@param quiet boolean?
function M.install(repo, quiet)
  if installing then
    return
  end
  installing = true
  local was_loaded = loaded()
  coroutine.wrap(function()
    local version = t_version()
    local ok, err = pcall(function()
      if repo then
        return build(repo)
      end
      if version then
        local r = run({ "t", "tree-sitter", site })
        -- A `t` older than `t tree-sitter` prints its usage and exits 2.
        if r.code == 0 then
          return
        elseif r.code ~= 2 then
          check(r, { "t", "tree-sitter", site })
        end
      end
      build_from_github(version)
    end)
    installing = false
    if not ok then
      notify("installing the tree-sitter parser failed: " .. err, vim.log.levels.ERROR)
      -- Highlight with the one installed before, if there is one.
      if vim.fn.filereadable(so) == 1 then
        start(was_loaded)
      end
      return
    end
    if version then
      vim.fn.mkdir(vim.fs.dirname(stamp), "p")
      vim.fn.writefile({ version }, stamp)
    end
    start(was_loaded)
    if not quiet or was_loaded then
      local of = repo and (" from " .. repo) or version and (" of t " .. version) or ""
      local restart = was_loaded and "; restart Neovim to use it" or ""
      notify("installed the tree-sitter parser" .. of .. restart)
    end
  end)()
end

local checked = false

--- Whether the parser is ready to start. The first time, installs it, unless
--- `vim.g.t_lang_auto_install` is false: with `t tree-sitter`, right away,
--- as that only writes what's changed; with a `t` older than that, in the
--- background if it's missing or was built for another version of `t`, and
--- then it's not ready until that's done.
---@return boolean
function M.ensure()
  if checked then
    return not installing
  end
  checked = true
  if vim.g.t_lang_auto_install == false or vim.fn.executable("t") == 0 then
    return true
  end
  local before = vim.uv.fs_stat(so)
  local ok, r = pcall(function()
    return vim.system({ "t", "tree-sitter", site }, { text = true }):wait()
  end)
  if ok and r.code == 0 then
    -- It renames a new parser over the old one, so a new inode means it
    -- changed.
    local after = vim.uv.fs_stat(so)
    if not before or not after or before.ino ~= after.ino then
      refresh_runtimepath()
      if before and loaded() then
        notify("installed a new tree-sitter parser; restart Neovim to use it")
      end
    end
    return true
  elseif not ok or r.code ~= 2 then
    -- A `t` older than `t tree-sitter` prints its usage and exits 2;
    -- anything else is a real failure.
    notify("installing the tree-sitter parser failed: " .. (ok and r.stderr or r), vim.log.levels.ERROR)
    return true
  end
  local version = t_version()
  local installed = vim.fn.filereadable(stamp) == 1 and vim.fn.readfile(stamp)[1]
  if version and installed ~= version then
    M.install(nil, installed ~= false)
  end
  return not installing
end

return M
