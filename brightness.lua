local wibox = require("wibox")
local gears = require("gears")
local awful = require("awful")

local beautiful
local brightness = {}
brightness.init = function(theme)
	beautiful = theme

	brightness.widget = wibox.widget {
		{
			max_value     = 100,
			value         = 0,
			border_width  = 1,
			margins = 1,
			color = beautiful.brightness_bar,
			id = "bar",
			background_color = beautiful.bg_normal,
			border_color  = beautiful.border_color,
			widget        = wibox.widget.progressbar,
		},
		{
			text = "☀",
			font = "sans 17",
			align = "center",
			widget = wibox.widget.textbox
		},
		forced_width  = beautiful.bars_width,
		layout = wibox.layout.stack
	}

	brightness.update = function()
		awful.spawn.easy_async_with_shell("Vbrightness %", function(stdout)
			brightness.widget.bar:set_value(tonumber(stdout))
		end)
	end

	brightness.update()

	brightness.widget:buttons(gears.table.join(
		awful.button({}, 2, function() -- middle click
			os.execute("Vbrightness 0")
			brightness.update()
		end),
		awful.button({}, 5, function() -- scroll up
			awful.spawn.easy_async_with_shell("Vbrightness +",function()end)
			brightness.update()
		end),
		awful.button({}, 4, function() -- scroll down
			awful.spawn.easy_async_with_shell("Vbrightness -",function()end)
			brightness.update()
		end)
	))

	brightness.keys = gears.table.join(
		awful.key({}, "XF86MonBrightnessDown", function()
			awful.spawn.easy_async_with_shell("Vbrightness -",function()end)
			brightness.update()
			end,
			{description = "lower brightness", group = "system"}
		),
		awful.key({}, "XF86MonBrightnessUp", function()
			awful.spawn.easy_async_with_shell("Vbrightness +",function()end)
			brightness.update()
			end,
			{description = "raise brightness", group = "system"}
		)
	)
end

return brightness
