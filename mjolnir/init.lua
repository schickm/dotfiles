local application = require "mjolnir.application"
local hotkey = require "mjolnir.hotkey"
local window = require "mjolnir.window"
local fnutils = require "mjolnir.fnutils"

local mods = {"cmd", "alt", "ctrl"} 

hotkey.bind(mods, "right", function()
    local win = window.focusedwindow()
    local f = win:screen():frame()
    f.x = f.w / 2
    f.w = f.x
    win:setframe(f)
end)

hotkey.bind(mods, "left", function()
    local win = window.focusedwindow()
    local f = win:screen():frame()
    f.w = f.w / 2
    win:setframe(f)
end)

hotkey.bind(mods, "up", function()
    local win = window.focusedwindow()
    win:setframe(win:screen():frame())
end)

local appkeys = {
   f1="Google Chrome Canary",
   f2="Emacs",
   f3="Terminal"
}

for key,app in pairs(appkeys) do
   hotkey.bind({}, key, function()
                  application.launchorfocus(app)
                           end)
end



