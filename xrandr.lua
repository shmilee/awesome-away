---------------------------------------------------------------------------
--
--  xrandr module for away, call xrandr and show screen info
--
--  Copyright (c) 2022 shmilee
--  Licensed under GNU General Public License v2:
--  https://opensource.org/licenses/GPL-2.0
--
---------------------------------------------------------------------------

local pairs, pcall, tonumber, tostring, type = pairs, pcall, tonumber, tostring, type
local string = { byte=string.byte, gsub = string.gsub, char=string.char,
    gmatch=string.gmatch, match = string.match, format=string.format }
local math = { abs=math.abs, ceil=math.ceil, max=math.max, floor=math.floor, min=math.min }
local table = { insert=table.insert, concat=table.concat,
    sort=table.sort, unpack=table.unpack, remove=table.remove }
local os = { remove = os.remove }
local io = { open = io.open, popen=io.popen }

local utilloaded, util
for _,c in pairs({ "away.util", "util", "awesome-away.util" }) do
    utilloaded, util = pcall(require, c)
    if utilloaded then
        break
    end
end
if not utilloaded then
    print("ERROR: lost module 'util'!")
    return nil
end
local naughtyloaded, naughty = pcall(require, "naughty")
if not naughtyloaded then
    naughty = { notify = function(args)
        local args = args or {}
        print(args.text or '')
    end }
end

-- (width_mm)x(height_mm)-(max_width_preferred)x(max_height_preferred)
-- key_style:  -- full --                               -- short --
--    eDP1-310x170-1366x768-0dae9-f11-7e-e          eDP1-310x170-1366x768
--  Mi-TV-HDMI1-1220x690-3840x2160-61a44-a45-db-d  Mi-TV-1220x690-3840x2160
local xrandr = {
    key_style = 'short'  -- 'full' or 'short'
}

-- get some info from edid
-- ref: https://gitlab.com/k3rni/foggy/-/blob/master/edid.lua
-- ref: https://en.wikipedia.org/wiki/Extended_Display_Identification_Data
function xrandr.parse_edid(edid)
    local ord = string.byte
    local bytes = string.gsub(edid, "([a-f0-9][a-f0-9])", function(m)
        return string.char(tonumber(m, 16))
    end)
    local esub = (edid:sub(17,21) .. '-' .. edid:sub(44,46) .. '-'
        .. edid:sub(255,256) .. '-' .. edid:sub(-1))
    --local mfr0, mfr1 = ord(bytes, 11, 12)
    --local manufacturer_code = mfr0 + mfr1 * 2^8
    --local sn0, sn1, sn2, sn3 = ord(bytes, 13, 16)
    --local serial_number = (sn0 + sn1 * 2^8 + sn2 * 2^16 + sn3 * 2^24)
    --local week_of_manufacture = ord(bytes, 17)
    --local year_of_manufacture = ord(bytes, 18) + 1990
    local width_mm = ord(bytes, 22) * 10
    local height_mm = ord(bytes, 23) * 10

    -- Descriptor blocks store things such as monitor name. Zero-based, corrected later.
    local descriptor_block_offsets = { { 54, 71 }, { 72, 89 }, { 90, 107 }, { 108, 125 } }
    local monitor_name
    for _, offset in pairs(descriptor_block_offsets) do
        local low = offset[1] + 1
        local high = offset[2] + 1
        local desc_type = string.byte(bytes:sub(low + 3))
        if desc_type == 0xFC then -- monitor name, space-padded with a LF
            monitor_name = bytes:sub(low + 5, high):gsub("[\r\n ]+$", "")
        end
    end
    --return manufacturer_code, serial_number, week_of_manufacture, year_of_manufacture
    return esub, width_mm, height_mm, monitor_name
end

local function get_monitor_info(self, key)
    return self['Search'][key] or nil
end

local function show_monitors_info(self)
    local noti = ''
    local info = ("Monitor %d: %s\nKey: %s\nDPI: %.2f\nGeometry: %dx%d\n"
        .. "Size: %dmmx%dmm\nPreferred: %dx%d")
    for i, key in pairs(self['Searchkey']) do
        local Mi = self['Search'][key]
        if Mi then
            if i>1 then
                noti = noti .. '\n\n'
            end
            --local query_str = {}
            --for i,v in pairs(Mi) do
            --    table.insert(query_str, i .. '=' .. tostring(v))
            --end
            --naughty.notify({ text = table.concat(query_str, '&') })
            local name = Mi.monitor_name or ''
            noti = noti .. string.format(info, i, name, key, Mi.DPI,
                Mi.width, Mi.height, Mi.Hsize, Mi.Vsize,
                Mi.preferred[1][1], Mi.preferred[1][2])
        end
    end
    naughty.notify({ text=noti, timeout=0 })
end

xrandr.cmd_prop = "xrandr -q --prop"

-- parse `xrandr -q --prop` output, like this:
-- return monitors info table:
--      'Count', 'Primary', 'Search', 'Searchkey',
--      'key'={out,width,height,Hsize,Vsize,DPI,connected,active,properties},
--      :get(key), :show()
-- Search key, style defined by xrandr.key_style
local output_example = [[
Screen 0: minimum 8 x 8, current 1366 x 768, maximum 32767 x 32767
eDP1 connected primary 1366x768+0+0 (normal left inverted right x axis y axis) 310mm x 170mm
	EDID: 
		00ffffffffffff000dae901400000000
	non-desktop: 0 
		range: (0, 1)
   1366x768      60.00*+
   1280x720      59.86    60.00    59.74  
   1024x768      60.00  
DP1 disconnected (normal left inverted right x axis y axis)
	Colorspace: Default 
HDMI1 connected (normal left inverted right x axis y axis)
	EDID: 
		00ffffffffffff0061a44a0001000000
]]
local re = {}
re.connected_info = '([%a]-)%s*(%d+)x(%d+).*%([%a%s]+%) (%d+)mm x (%d+)mm.*$'
re.mode_info = '^%s%s%s(%d+)x(%d+)%s+[%d.]+.(.).*$'
re.prop_info = '^\t([%a%s]+):%s*([^%s]*)%s*$'
function xrandr.parse_prop_output(output)
    local OUTS = {}
    local this_out, this_prop
    for s in string.gmatch(output, "[^\r\n]+") do
        local out, conn, other = string.match(s, '^([%w-]+) (%a+) (.*)$')
        if out then
            -- 1. '^eDP1 '
            this_out = { out = out, connected = (conn == 'connected') }
            if conn == 'connected' then
                local p, W, H, w, h = string.match(other, re.connected_info)
                if W then
                    this_out['active'] = true
                end
                this_out['primary'] = (p == 'primary')
                this_out['width'] = tonumber(W)
                this_out['height'] = tonumber(H)
                this_out['Hsize'] = tonumber(w)
                this_out['Vsize'] = tonumber(h)
            end
            this_out['preferred'] = {}
            this_out['properties'] = {}
            table.insert(OUTS, this_out)
        else
            -- 2. modeline: '   1366x768*+'
            local W, H, plus = string.match(s, re.mode_info)
            if W then
                if plus == '+' then
                    -- only save preferred mode
                    table.insert(this_out['preferred'],
                        { tonumber(W), tonumber(H) })
                end
            else
                -- 3. '\tEDID: ', '\tColorspace: Default ', etc.
                local prop, value = string.match(s, re.prop_info)
                if prop then
                    this_prop = prop
                    this_out['properties'][prop] = value
                else
                    -- 4. prop data, '\t\t00ff', only for EDID
                    if this_prop == 'EDID' then
                        local data = string.match(s, '\t\t([0-9a-f]+)$')
                        if data and data:len() == 32 then
                            this_out['properties']['EDID'] = (
                                this_out['properties']['EDID'] .. data)
                        end
                    end
                end
            end
        end
    end
    -- slim OUTS info
    local res = { Count=0, Primary=nil, Search={}, Searchkey={},
                  get=get_monitor_info, show=show_monitors_info }
    local sortfun = function (a, b)
        return a[1] > b[1]
    end
    for _, out in pairs(OUTS) do
        if out['connected'] then
            local edid = out['properties']['EDID']
            local esub, w_mm, h_mm, name = xrandr.parse_edid(edid)
            out['Hsize'] = out['Hsize'] or w_mm
            out['Vsize'] = out['Vsize'] or h_mm
            if name then
                out['monitor_name'] = name
                name = name:gsub('%s', '-')
            end
            table.sort(out['preferred'], sortfun)
            out['width'] = out['width'] or out['preferred'][1][1]
            out['height'] = out['height'] or out['preferred'][1][2]
            local W, H = out['width'], out['height']
            local w, h = out['Hsize'], out['Vsize']
            out['DPI'] = math.ceil((W^2+H^2)^0.5/((w^2+h^2)^0.5/10/2.54)*100)/100
            local key = string.format('%sx%s-%sx%s',
                w, h, out['preferred'][1][1], out['preferred'][1][2])
            if xrandr.key_style == 'full' then
                if name then
                    key = string.format('%s-%s-%s-%s', name, out['out'], key, esub)
                else
                    key = string.format('%s-%s-%s', out['out'], key, esub)
                end
            else -- short
                key = string.format('%s-%s', name or out['out'], key)
            end
            res['Search'][key] = out
            table.insert(res['Searchkey'], key)
            res['Count'] = res['Count'] + 1
            if out['primary'] then
                res['Primary'] = key
            end
        end
    end
    return res
end

-- show `parse_prop_output` results
function xrandr.debug_monitors_data()
    local out = io.popen(xrandr.cmd_prop)
    local stdout = out:read("*all")
    local success, reason, code = out:close()
    return success and xrandr.parse_prop_output(stdout)
end

-- show info about all connected outputs
function xrandr.show_connected()
    util.async_with_shell(xrandr.cmd_prop, function(stdout, err, rsn, ecode)
        if ecode == 0 then
            local data = xrandr.parse_prop_output(stdout)
            data:show()
        end
    end)
end

-- Extract physical size (first occurrence of "digitsxdigits") from a key string
local function extract_size_from_key(key)
    local w, h = string.match(key, '(%d+)x(%d+)')
    if w and h then
        return tonumber(w), tonumber(h)
    end
    return nil, nil
end

-- Extract the identifier prefix (part before first '-') from a key
local function get_key_prefix(key)
    return string.match(key, '^([^-]+)')
end

-- Match a target key against a list of candidate keys with tolerance on width/height (in mm)
-- @param target_key string: the key to look for
-- @param candidate_keys table: list of candidate keys (e.g., data.Searchkey)
-- @param w_tol number: width tolerance (mm), default 10
-- @param h_tol number: height tolerance (mm), default 10
-- @return matched_key string or nil
local function match_key_with_tolerance(target_key, candidate_keys, w_tol, h_tol)
    w_tol = w_tol or 10
    h_tol = h_tol or 10
    local tw, th = extract_size_from_key(target_key)
    local tprefix = get_key_prefix(target_key)
    if not tw or not th or not tprefix then
        return nil
    end
    for _, k in ipairs(candidate_keys) do
        local kw, kh = extract_size_from_key(k)
        local kprefix = get_key_prefix(k)
        if kprefix == tprefix and kw and kh then
            local dw = math.abs(kw - tw)
            local dh = math.abs(kh - th)
            if dw <= w_tol and dh <= h_tol then
                util.print_info(string.format(
                    "Tolerance match: '%s' -> '%s' (deviation: %dmm horizontal, %dmm vertical)",
                    target_key, k, dw, dh))
                return k
            end
        end
    end
    return nil
end

-- Compare two monitor data.Searchkey
-- data1: original data before running xrandr
-- data2: new data after running xrandr
-- Returns a human-readable diff string if Searchkey lists differ, otherwise nil.
function xrandr.compare_data_Searchkey(data1, data2)
    local keys1 = { table.unpack(data1.Searchkey or {}) }
    local keys2 = { table.unpack(data2.Searchkey or {}) }
    table.sort(keys1)
    table.sort(keys2)
    local diff = {}
    for i = 1, #keys1 do
        if keys1[i] ~= keys2[i] then
            diff[#diff+1] = string.format("%s -> %s", keys1[i], keys2[i])
        end
    end
    if #diff > 0 then
        return "Monitor keys changed:\n" .. table.concat(diff, "; ")
    end
    return nil  -- no change
end

-- filter needed monitors, scale preferred mode, add '--output' '--scale' options
--   data:connected monitors   |   | 2 | 3 |
--   input:needed monitors     | 1 | 2 |   |
-- @param data table current screen info get from xrandr:
--      'Count', 'Primary', 'Search', 'Searchkey', key1, key2, ...
-- @param monitors = {
--      { key='Search key1', scale=1.0 },  -- monitor 1
--      'Search key2',  -- monitor 2, default scale 1.0
--      ...
--  }
-- @param w_tol number: width tolerance (mm), default 10
-- @param h_tol number: height tolerance (mm), default 10
-- @param complete true if require all needed monitors connected
-- @return nil or needed and connected monitors with corresponding options: {
--      { Mi, '--output %s --primary --mode %dx%d --scale %s', sW, sH },
--      { ... }, ... }
-- @return nil or '--output --off' options: '--output Mi3.out --off ...'
function xrandr.filter_scale_monitors(data, monitors, w_tol, h_tol, complete)
    local res, off, options = {}, {}, nil
    local connected = { table.unpack(data.Searchkey) }
    for _, v in pairs(monitors) do
        if type(v) == 'string' then
            v = { key=v }
        end
        local Mi = data:get(v.key)
        local m_key = nil  -- matched key
        if Mi == nil then
            -- Try tolerance‑based matching
            m_key = match_key_with_tolerance(v.key, data.Searchkey, h_tol, v_tol)
            if m_key then
                Mi = data:get(m_key)
            end
        end
        util.print_info("Search: " .. v.key .. ", get '"
            .. tostring(Mi and (Mi.monitor_name or Mi.out)) .. "'")
        if Mi then
            options = string.format('--output %s', Mi.out)
            if Mi.primary then
                options = options .. ' --primary'
            end
            local scale = v.scale or 1.0
            local W, H = table.unpack(Mi['preferred'][1])
            local sW, sH = math.ceil(W*scale)//2*2, math.ceil(H*scale)//2*2
            options = options .. string.format(
                ' --mode %dx%d --scale %s',  W, H, scale)
            table.insert(res, { Mi, options, sW, sH})
            -- remove handled needed key
            local idx = util.table_hasitem(connected, m_key or v.key)
            if idx then
                table.remove(connected, idx)
            else
                util.print_error("Lost monitor to remove: "
                    .. tostring(m_key or v.key))
            end
        else
            if complete then
                naughty.notify({ text = "Monitor " .. v.key .. " not connected!" })
                res = {}
                break
            end
        end
    end
    for _, v in pairs(connected) do -- connected & not needed
        local Mi = data:get(v)
        table.insert(off, string.format('--output %s --off', Mi.out))
    end
    if #res == 0 then
        res = nil
    end
    if #off == 0 then
        off = nil
    end
    return res, off and table.concat(off, ' ')
end

-- stack needed monitors horizontally with scale support
-- @param data table, monitors info
-- @param args.monitors table, default all connected
-- @param args.w_tol number: width tolerance (mm), default 10
-- @param args.h_tol number: height tolerance (mm), default 10
-- @param args.complete boolean, default false
-- @param args.dpi number, default 96
-- @return cmd string:
--      xrandr --dpi %d --fb %dx%d [monitor1 args] ...
-- @return nil:
--      no connected monitors
--      or if complete is true and find one monitor not connected
function xrandr.template_horiz_scale(data, args)
    util.print_info("Using template: 'template_horiz_scale'...")
    args = args or {}
    monitors = args.monitors or data.Searchkey
    local Mis, off = xrandr.filter_scale_monitors(
        data, monitors, args.w_tol, args.h_tol, args.complete)
    if Mis == nil then
        return nil
    end
    local res, fbw, fbh, posx = {}, 0, 0, 0
    for _, v in pairs(Mis) do
        local Mi, options, sW, sH = v[1], v[2], v[3], v[4]
        -- right-of
        options = options .. string.format(' --panning %dx%d+%d+%d', sW, sH, posx, 0)
        fbw, fbh = fbw + sW, math.max(fbh, sH)
        posx = posx + sW
        table.insert(res, options)
    end
    if off ~= nil then
        table.insert(res, off)
    end
    table.insert(res, 1,
        string.format('xrandr --dpi %d --fb %dx%d', args.dpi or 96, fbw, fbh))
    return table.concat(res, ' ')
end

-- stack all connected outputs horizontally, auto-using preferred mode
-- @param data table
-- @param args table, not used
function xrandr.template_horiz_auto(data, args)
    util.print_info("Using template: 'template_horiz_auto'...")
    local cmd = 'xrandr'
    local left_Mi, Mi
    for i, key in pairs(data.Searchkey) do
        Mi = data:get(key)
        util.print_info("Search: " .. key .. ", get '"
            .. tostring(Mi and (Mi.monitor_name or Mi.out)) .. "'")
        if Mi then
            cmd = cmd .. ' --output ' .. Mi.out .. ' --auto'
            if Mi.primary then
                cmd = cmd .. ' --primary'
            end
            if left_Mi then
                cmd = cmd .. ' --right-of ' .. left_Mi.out
            end
            left_Mi = Mi
        end
    end
    return cmd
end

xrandr.Xresources = util.get_xdg_cache_home() .. 'away.Xresources'

-- save dpi Xcursor.size to away.Xresources (~/.cache/away.Xresources),
-- and xrdb -merge it, then call callback
-- @param dpi number default 96
-- @param callback function fired without arguments
function xrandr.save_dpi_and_merge(dpi, callback)
    dpi = dpi or 96
    local csize = math.min(math.floor(dpi/96+0.5)*16, 64)
    os.remove(xrandr.Xresources)
    util.async_with_shell(
        string.format("echo 'Xft.dpi: %d\nXcursor.size: %d' > %s",
                      dpi, csize, xrandr.Xresources),
        function()
            util.async("xrdb -merge " .. xrandr.Xresources, callback, false)
        end,
        false)
end

-- read dpi from away.Xresources, then call callback to set dpi
-- @param callback function fired with dpi as argument
function xrandr.read_and_set_dpi(callback)
    if type(callback) == 'function' then
        local dpi = 96 -- default
        -- util.async deprecated, get dpi immediately
        local file = io.open(xrandr.Xresources, 'r')
        if file then
            local m = string.match(file:read(), 'Xft.dpi:%s*(%d+)%s*')
            file:close()
            if m then
                dpi = tonumber(m)
            end
        end
        callback(dpi)
    end
end

-- call args.template function, like xrandr.template_horiz_scale
--     args.template(data, args)
-- then call xrandr.save_dpi_and_merge, with custom callback
-- @param args.template string or function, default xrandr.template_horiz_scale
-- @param args.monitors: default all connected monitors
-- @param args.w_tol number: width tolerance (mm), default 10
-- @param args.h_tol number: height tolerance (mm), default 10
-- @param args.complete: default false
-- @param args.dpi: default 96
-- @param callback function: fired without arguments
function xrandr.call_template(args, callback)
    args = args or {}
    local template = args.template or xrandr.template_horiz_scale
    if type(template) == 'string' then
        template = xrandr[template] -- get by function name
    end
    if type(template) ~= 'function' then
        util.print_error(string.format("Lost template function '%s'!",
            tostring(args.template)))
        return
    end
    util.async(xrandr.cmd_prop, function(stdout, stderr, reason, exit_code)
        if exit_code == 0 then
            local data = xrandr.parse_prop_output(stdout)
            local cmd = template(data, args)
            if cmd then
                util.async_with_shell(cmd, function()
                    xrandr.save_dpi_and_merge(args.dpi, callback)
                    -- check data after cmd (xrandr --output xxx)
                    util.async(xrandr.cmd_prop, function(new_stdout, _, _, new_exit)
                        if new_exit == 0 then
                            local data2 = xrandr.parse_prop_output(new_stdout)
                            local diff = xrandr.compare_data_Searchkey(data, data2)
                            if diff then
                                naughty.notify({
                                    preset = naughty.config.presets.warn,
                                    title = "Monitor configuration changed, consider running xrandr setup again.",
                                    text = diff,
                                })
                            end
                        end
                    end)
                end, false)
            end
        end
    end)
end

-- call xrandr.template_horiz_auto
function xrandr.example_call_horiz_auto()
    xrandr.call_template({ template=xrandr.template_horiz_auto })
end

-- call xrandr.template_horiz_scale
function xrandr.example_call_horiz_scale()
    xrandr.call_template({ template='template_horiz_scale' })
end

return xrandr
