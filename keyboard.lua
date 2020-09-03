-- this file emulates actions of following command + xxkb package
-- localectl --no-convert set-x11-keymap us,ru,ua,cz pc104 euro,legacy,legacy,qwerty grp:alt_shift_toggle

local wibox = require("wibox")
local gears = require("gears")
local awful = require("awful")
local naughty = require("naughty")

local beautiful
local keyboard = {}

local layouts = {
	{"us(euro)", "en.xpm"},
	{"ru(legacy)", "ru.xpm"},
	{"ua(legacy)", "ua.xpm"},
	{"cz(qwerty)", "cz.xpm"}
}

local connections = {}



local function shift_layout(client, shift)
	connections[client.window] = ((connections[client.window] + shift - 1) % #layouts) + 1	
end


keyboard.init = function(theme)
	beautiful = theme

	keyboard.widget = wibox.widget.imagebox() 
	keyboard.widget:set_image(beautiful.awesome_icon)

	keyboard.update = function (client)
		layout = connections[client.window]
		-- change layout
		awful.spawn.easy_async_with_shell("xkb-switch -s \"" .. layouts[layout][1] .. "\"" ,function()end)
		-- set image for widget
		keyboard.widget:set_image(beautiful.keyboard_icons .. layouts[layout][2])
	end

	keyboard.widget:buttons(gears.table.join(
		awful.button({}, 2, function() -- middle click
			connections[client.focus.window] = 1
			keyboard.update(client.focus)
		end),
		awful.button({}, 5, function() -- scroll up
			c = client.focus
			shift_layout(c, 1)
			keyboard.update(c)
		end),
		awful.button({}, 4, function() -- scroll down
			c = client.focus
			shift_layout(c, -1)
			keyboard.update(c)
		end)
	))

	keyboard.keys = gears.table.join(
		awful.key({ modkey }, "q" , function()
			c = client.focus
			shift_layout(c, -1)
			keyboard.update(c)
			end,
			{description = "previous keyboard layout", group = "system"}
		),
		awful.key({ modkey }, "w" , function()
			c = client.focus
			shift_layout(c, 1)
			keyboard.update(c)
			end,
			{description = "next keyboard layout", group = "system"}
		)
	)
end

client.connect_signal("unmanage", function(c)
	connections[c.window] = nil
end)

client.connect_signal("focus", function(c)
	if connections[c.window] == nil then
		
		connections[c.window] = 1
	end
	keyboard.update(c)
end)

return keyboard
