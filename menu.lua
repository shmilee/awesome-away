---------------------------------------------------------------------------
--
--  menu module for away, tools to build awful.menu
--
--  Copyright (c) 2022 shmilee
--  Licensed under GNU General Public License v2:
--  https://opensource.org/licenses/GPL-2.0
--
---------------------------------------------------------------------------

local awful = require("awful")
local menubar = require("menubar")
local icon_theme = require("menubar.icon_theme")
local utilloaded, util = pcall(require, "away.util")

-- @attr osi_wm_name: Name of the WM for the OnlyShowIn entry
-- @attr items: table items for awful.menu
-- @attr menupopups: awful.menu array, index is its count
local awaymenu = { osi_wm_name="", items=nil, count=0, menupopups={} }

function awaymenu.find_icon(i, theme)
    return menubar.utils.lookup_icon(i) or icon_theme(theme):find_icon_path(i)
end

-- parse all visible menu entries (see menu_gen.generate result)
-- @return table items
-- ref: https://github.com/lcpz/awesome-freedesktop/blob/master/menu.lua
function awaymenu._parse_entries(entries)
    local _items = {}
    if utilloaded then
        util.print_debug('Parse all visible menu entries.')
    end
    -- Set category and icon
    for k, v in pairs(menubar.menu_gen.all_categories) do
        _items[k] = { k, {}, awaymenu.find_icon(v.icon_name) }
    end
    -- Get items table
    for _, v in pairs(entries) do
        if _items[v.category] ~= nil then
            table.insert(_items[v.category][2], { v.name, v.cmdline, v.icon })
        end
    end
    local items = {}
    local sortfun = function (a, b)
        return string.byte(a[1]) < string.byte(b[1])
    end
    for _, v in pairs(_items) do
        if #v[2] > 0 then
            --Sort entries alphabetically (by name)
            table.sort(v[2], sortfun)
            -- Replace category name with nice name
            v[1] = menubar.menu_gen.all_categories[v[1]].name
            -- get used categories
            table.insert(items, v)
        end
    end
    -- Sort categories alphabetically
    table.sort(items, sortfun)
    return items
end

-- use menubar.menu_gen to generate items for awful.menu
-- use awful.menu to generate menupopup
-- @param theme for awful.menu args.theme, like:
--     theme.height and theme.width, theme.font, etc.
--     see: https://awesomewm.org/doc/api/libraries/awful.menu.html#new
-- @param before entries before awaymenu.items
-- @param after entries after awaymenu.items
-- results cached in awaymenu.items and items.menupopups
-- @return awful.menu popup
function awaymenu:generate(args)
    local args   = args or {}
    local theme  = args.theme or {}
    local before = args.before or {}
    local after  = args.after or {}
    local regen  = args.regen or false

    self.count = self.count + 1
    local c = self.count
    self.menupopups[c] = awful.menu({ items = before, theme=theme })

    local awesome_wm_name = menubar.utils.wm_name -- save old
    menubar.utils.wm_name = self.osi_wm_name
    menubar.menu_gen.generate(function(entries) -- callback for async
        menubar.utils.wm_name = awesome_wm_name -- restore old
        if regen or self.items == nil then
            self.items = self._parse_entries(entries)
        end
        for _, v in pairs(self.items) do
            self.menupopups[c]:add(v)
        end
        for _, v in pairs(after) do
            self.menupopups[c]:add(v)
        end
    end)

    return self.menupopups[c]
end

-- Menubar configuration for zh_CN categories name
function awaymenu.use_zh_CN()
    menubar.menu_gen.all_categories.multimedia.name = "影音"
    menubar.menu_gen.all_categories.development.name = "开发"
    menubar.menu_gen.all_categories.education.name = "教育"
    menubar.menu_gen.all_categories.games.name = "游戏"
    menubar.menu_gen.all_categories.graphics.name = "图像"
    menubar.menu_gen.all_categories.office.name = "办公"
    menubar.menu_gen.all_categories.internet.name = "互联网"
    menubar.menu_gen.all_categories.settings.name = "设置"
    menubar.menu_gen.all_categories.tools.name = "系统"
    menubar.menu_gen.all_categories.utility.name = "工具"
end

return awaymenu
