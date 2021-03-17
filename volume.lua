local wibox = require("wibox")
local awful = require("awful")
local gears = require("gears")

local beautiful
local volume = {}

volume.init = function(theme)
	beautiful = theme

	volume.widget = wibox.widget {
		{
			max_value	  = 100,
			value         = 0,
			border_width  = 1,
			margins = 1,
			id = "bar",
			background_color = beautiful.bg_normal,
			border_color  = beautiful.border_color,
			widget        = wibox.widget.progressbar,
		},
		{
			text = "♫",
			align = "center",
			valign = "bottom",
			font = "sans 11",
			widget = wibox.widget.textbox
		},
		forced_width  = beautiful.bars_width,
		layout = wibox.layout.stack
	}

	volume.update = function()
		awful.spawn.easy_async_with_shell("Vvolume %", function(stdout)
			local curr_volume = string.match(stdout, "Volume: (%d+)")
			local muted = string.match(stdout, "Mute: (%S+)")
			
			-- set foreground color
			if muted == "no" then
				volume.widget.bar.color = beautiful.volume_bar_unmute
			else
				volume.widget.bar.color = beautiful.volume_bar_mute
			end
			
			volume.widget.bar:set_value(tonumber(curr_volume))
		end)
	end

	volume.update()

	volume.widget:buttons(gears.table.join(
		awful.button({}, 2, function() -- middle click
			awful.spawn.easy_async_with_shell("Vvolume 100",function()end)
			volume.update()
		end),
		awful.button({}, 3, function() -- right click
			os.execute("Vvolume 0")
			volume.update()
		end),
		awful.button({}, 5, function() -- scroll up
			awful.spawn.easy_async_with_shell("Vvolume +",function()end)
			volume.update()
		end),
		awful.button({}, 4, function() -- scroll down
			awful.spawn.easy_async_with_shell("Vvolume -",function()end)
			volume.update()
		end)
	))

	volume.keys = gears.table.join(
		awful.key({}, "XF86AudioMute", function()
				os.execute("Vvolume 0")
				volume.update()
			end,
			{description = "mute", group = "system"}
		),
		awful.key({}, "XF86AudioLowerVolume", function()
				awful.spawn.easy_async_with_shell("Vvolume -",function()end)
				volume.update() end,
			{description = "lower volume", group = "system"}
		),
		awful.key({}, "XF86AudioRaiseVolume", function()
				awful.spawn.easy_async_with_shell("Vvolume +",function()end)
				volume.update()
				end,
			{description = "raise volume", group = "system"}
		)
	)
end


return volume
