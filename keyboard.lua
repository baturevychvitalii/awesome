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

local function shift_layout(client, shift)
	client.keyboard_layout = ((client.keyboard_layout + shift - 1) % #layouts) + 1	
end

local function alter_current_client(shift)
	if (client.focus ~= nil) then
		shift_layout(client.focus, shift)
		keyboard.update(client.focus)
	end
end

keyboard.init = function(theme)
	beautiful = theme

	keyboard.widget = wibox.widget.imagebox() 
	keyboard.widget:set_image(beautiful.awesome_icon)

	keyboard.update = function (client)
		layout = client.keyboard_layout
		-- change layout
		awful.spawn.easy_async_with_shell("xkb-switch -s \"" .. layouts[layout][1] .. "\"" ,function()end)
		-- set image for widget
		keyboard.widget:set_image(beautiful.keyboard_icons .. layouts[layout][2])
	end

	keyboard.widget:buttons(gears.table.join(
		awful.button({}, 5, function() -- scroll up
			alter_current_client(1)
		end),
		awful.button({}, 4, function() -- scroll down
			alter_current_client(-1)
		end)
	))

	keyboard.keys = gears.table.join(
		awful.key({ modkey }, "q" , function() alter_current_client(-1) end,
			{description = "previous keyboard layout", group = "system"}
		),
		awful.key({ modkey }, "w" , function() alter_current_client(1) end,
			{description = "next keyboard layout", group = "system"}
		)
	)
end

client.connect_signal("focus", function(c)
	if c.keyboard_layout ~= nil then
		keyboard.update(c)
	end
end)

client.connect_signal("unfocus", function(c)
	keyboard.widget:set_image(beautiful.keyboard_icons .. "none_color.png")
end)

return keyboard
