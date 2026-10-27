-- Keep Rex navigation consistent with the surrounding macOS apps.
rex.bind("cmd+g", "pane.send_key", { key = "ctrl+g" })
rex.bind("cmd+w", "pane.send_key", { key = "f12" })
rex.bind("cmd+t", "client.tab.new")

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
