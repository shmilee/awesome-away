local gears = require('gears')
local naughty = require("naughty")

-- adjust the time if you are on a slow cpu to give more time for the client
local micky = { wait_time = 0.05 }

-- relocate mouse to the client, default focus client
function micky.move_to_client(c)
    c = c or client.focus
    if c then
        local g = c:geometry()
        mouse.coords({ 
            x = g.x + g.width // 2,
            y = g.y + g.height // 2,
        }, true)
    end
end

-- class names defined here would insist micky stays where he is at.
micky.stay_classes = { 
    awesome
    -- taskbar
}

-- check if client c in stay_classes
function micky.check_stay(c)
    return micky.stay_classes[c and c.class] ~= nil
end

-- check if client c is under mouse
function micky.check_under(c)
    return c == mouse.current_client
end

-- check if client c1, c2 have same coords
function micky.check_coords(c1, c2)
    if not c1 or not c2 then
        return false
    end
    local g1, g2 = c1:geometry(), c2:geometry()
    return g1.x == g2.x and g1.y == g2.y
end

-- default rule for signal focus
function micky.rule_focus(c)
    -- c is focused client, wait_time waiting for focus to complete.
    gears.timer.weak_start_new(micky.wait_time, function()
        if micky.check_stay(c) then
            return false
        end
        if micky.check_under(c) then
            return false
        end
        if micky.check_coords(c, mouse.current_client) then
            return false
        end
        micky.move_to_client(c)
        return false -- call only once then stop
    end)
end

-- default rule for signal swapped
function micky.rule_swapped(c)
    if c == client.focus then
        -- callback for only one client
        micky.rule_focus(c)
        -- naughty.notify({text=c.name})
    end
end

-- default rule for signal unmanage
function micky.rule_unmanage(c)
    -- naughty.notify({text=c.name})
    gears.timer.weak_start_new(micky.wait_time, function()
        micky.rule_focus(client.focus)
        return false
    end)
end

-- default rule for signal tag layout
function micky.rule_layout(t)
    -- naughty.notify({text=t.name})
    gears.timer.weak_start_new(micky.wait_time, function()
        micky.rule_focus(client.focus)
        return false
    end)
end

-- flag for signal call enabled or not
micky.enabled = false

-- enable all signal call rules
function micky.enable()
    client.connect_signal("swapped", micky.rule_swapped)
    client.connect_signal("focus", micky.rule_focus)
    client.connect_signal("unmanage", micky.rule_unmanage)
    tag.connect_signal("property::layout", micky.rule_layout)
    micky.enabled = true
end

-- disable all signal call rules
function micky.disable()
    client.disconnect_signal("swapped", micky.rule_swapped)
    client.disconnect_signal("focus", micky.rule_focus)
    client.disconnect_signal("unmanage", micky.rule_unmanage)
    tag.disconnect_signal("property::layout", micky.rule_layout)
    micky.enabled = false
end

-- toggle enable/disable
function micky.toggle()
    if micky.enabled then
        micky.disable()
    else
        micky.enable()
    end
end

return micky

-- naughty.notify({text=current_client.name})
-- naughty.notify({text=focused_client.name})
-- local inspect = require('inspect')
-- naughty.notify({text=inspect(c:geometry())})
-- naughty.notify({text=inspect(mouse.current_widget_geometry)})
