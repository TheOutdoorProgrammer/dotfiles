-- Keep Rex navigation consistent with the surrounding macOS apps.
rex.bind("cmd+g", "pane.send_key", { key = "ctrl+g" })
rex.bind("cmd+w", "pane.send_key", { key = "f12" })
rex.bind("cmd+t", "client.tab.new")
rex.unbind("shift+cmd+p", "client.palette.toggle")
rex.bind("cmd+p", "client.palette.toggle")

rex.bind("cmd+\\", "pane.split", { direction = "right" })
rex.bind("shift+cmd+\\", "pane.split", { direction = "right" })
rex.bind("cmd+-", "pane.split", { direction = "down" })

rex.bind("shift+cmd+left", "pane.focus", {
  direction = "left",
  wrap = false,
})
rex.bind("shift+cmd+down", "pane.focus", {
  direction = "down",
  wrap = false,
})
rex.bind("shift+cmd+up", "pane.focus", {
  direction = "up",
  wrap = false,
})
rex.bind("shift+cmd+right", "pane.focus", {
  direction = "right",
  wrap = false,
})

rex.bind("cmd+left", "pane.send_key", { key = "alt+b" })
rex.bind("cmd+right", "pane.send_key", { key = "alt+f" })

rex.action{
  name = "open_file_in_vim",
  title = "Open File in Neovim",
  description = "Open a copied path[:line[:column]] with the project explorer.",
  keywords = "file clipboard editor vim nvim neovim",
  args = { reference = "string?" },
  run = function(ctx, args)
    if not ctx.block_id then
      error("Run Open File in Neovim from a terminal pane.", 0)
    end

    local reference = args.reference
    if reference == nil then
      local clipboard, err = rex.exec({ "/usr/bin/pbpaste" }, { timeout = 5 })
      if not clipboard then
        error(err, 0)
      end
      if not clipboard.ok then
        error("Could not read the Mac clipboard.", 0)
      end
      reference = clipboard.stdout
    end
    reference = reference:match("^%s*(.-)%s*$")
    local first, last = reference:sub(1, 1), reference:sub(-1)
    if (first == "`" or first == '"' or first == "'") and first == last then
      reference = reference:sub(2, -2)
    end
    if reference == "" or reference:find("%c") then
      error("Copy one file path, optionally followed by :line or :line:column.", 0)
    end

    local path, line, column = reference:match("^(.-):(%d+):(%d+)$")
    if not path then
      path, line = reference:match("^(.-):(%d+)$")
    end
    path, line, column = path or reference, tonumber(line) or 1, tonumber(column) or 1
    if path == "" or line < 1 or column < 1 or line > 2147483647 or column > 2147483647 then
      error("The file path and positive line/column numbers are invalid.", 0)
    end

    local process, err = rex.block.call("com.superlogical.terminal", "process", {
      block_id = ctx.block_id,
    })
    if not process then
      error(err, 0)
    end
    local cwd = (process.child and process.child.cwd)
      or (process.foreground and process.foreground.cwd)
    if not cwd or cwd:sub(1, 1) ~= "/" then
      error("Cannot determine the source terminal's working directory.", 0)
    end
    local root = rex.exec({ "git", "-C", cwd, "rev-parse", "--show-toplevel" }, { timeout = 5 })
    if root and root.ok then
      cwd = root.stdout:gsub("[\r\n]+$", "")
    end
    if path:sub(1, 2) == "~/" then
      if not process.home then
        error("Cannot determine the terminal user's home directory.", 0)
      end
      path = process.home .. path:sub(2)
    elseif path:sub(1, 1) ~= "/" then
      path = cwd .. "/" .. path
    end

    local exists, check_err = rex.exec({ "/bin/test", "-f", path }, { timeout = 5 })
    if not exists then
      error(check_err, 0)
    end
    if not exists.ok then
      error("File does not exist: " .. path, 0)
    end

    -- Run after startup so LazyVim finishes restoring the buffer first.
    local startup = string.format(
      "+lua vim.api.nvim_create_autocmd('VimEnter', {once=true, callback=function() "
        .. "vim.schedule(function() local win=vim.api.nvim_get_current_win(); "
        .. "Snacks.explorer({cwd=vim.fn.getcwd(), focus=false, on_show=function() "
        .. "vim.schedule(function() vim.api.nvim_win_call(win, function() "
        .. "vim.fn.cursor(%d,%d) end) end) end}) end) end})",
      line, column
    )

    -- Copied filenames must stay arguments, never commands or Vim options.
    local window, window_err = rex.session.new_window{
      window_label = "Neovim",
      focus = true,
      layout = rex.layout.block{
        flavor = "com.superlogical.terminal.shell",
        label = "Neovim",
        options = {
          cwd = cwd,
          command = { "nvim", startup, "--", path },
        },
      },
    }
    if not window then
      error(window_err, 0)
    end
    if ctx.client_id then
      rex.client.queue("session.select", {
        session_id = ctx.session_id,
        window_id = window.window_id,
      })
    end
    return window
  end,
}
