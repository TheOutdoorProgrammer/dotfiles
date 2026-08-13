local hyper = {"cmd", "control", "option" , "shift"}

-- Load SpoonInstall
hs.loadSpoon("SpoonInstall")

-- App Launcher Hotkeys
spoon.SpoonInstall:andUse("AppLauncher")
spoon.AppLauncher.modifiers = hyper
spoon.AppLauncher:bindHotkeys({
  s = "Slack",
  c = "Google Chrome",
  i = "IntelliJ Idea",
  t = "iTerm",
  u = "Sublime Text",
  z = "Zoom.us"
})

-- Emojis
spoon.SpoonInstall:andUse("Emojis")
spoon.Emojis:bindHotkeys({toggle = {hyper, "e"}})

-- Window Manager
spoon.SpoonInstall:andUse("MiroWindowsManager")
hs.window.animationDuration = 0.3
spoon.MiroWindowsManager:bindHotkeys({
  up = {hyper, "up"},
  right = {hyper, "right"},
  down = {hyper, "down"},
  left = {hyper, "left"},
  fullscreen = {hyper, "f"}
})

function moveWindowToDisplay(d)
  return function()
    local displays = hs.screen.allScreens()
    local win = hs.window.focusedWindow()
    win:moveToScreen(displays[d], false, true)
  end
end

hs.hotkey.bind(hyper, "1", moveWindowToDisplay(1))
hs.hotkey.bind(hyper, "2", moveWindowToDisplay(2))
hs.hotkey.bind(hyper, "3", moveWindowToDisplay(3))

hs.notify.new({title='Hammerspoon', informativeText='Everything is 🍑'}):send()
