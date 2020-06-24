local wibox = require("wibox")
local gears = require("gears")
local awful = require("awful")
local naughty = require("naughty")

local beautiful
local battery = {}

local battery_status = {status = "N/A", percentage = 0}
local low_battery_showed = false

battery.init = function(theme)
	beautiful = theme

	battery.widget = wibox.widget {
		{
			max_value     = 100,
			value         = 0,
			widget        = wibox.widget.progressbar,
			border_width  = 1,
			margins = 1,
			color = beautiful.battery_bar_charged,
			background_color = beautiful.battery_bar_discharged,
			id = "bar",
			border_color  = beautiful.border_color
		},
		direction = 'east',
		forced_height = 100,
		forced_width = 17,
		layout        = wibox.container.rotate
	}

	local random_miracle = function()
		battery.widget.bar.color = beautiful.battery_bar_miracle[math.random(0,#beautiful.battery_bar_miracle)]
	end

	battery.widget.bar:buttons(awful.util.table.join(
		awful.button({}, 5, random_miracle ),
		awful.button({}, 4, random_miracle )
	))

	gears.timer {
		timeout = 45,
		call_now = true,
		autostart = true,
		callback = function()
			-- get percentage
			local file = io.open("/sys/class/power_supply/BAT0/capacity")
			battery_status.percentage = tonumber(file:read())
			file:close()
			-- get status
			file = io.open("/sys/class/power_supply/BAT0/status")
			battery_status.status = file:read()
			file:close()
			battery.widget.bar:set_value(battery_status.percentage)
			if battery_status.percentage <= 10 and battery_status.status == "Discharging" and (not low_battery_showed) then
				naughty.notify({
					text = "Веталя, заряди меня пожалуйста",
					title = "Села батарейка",
					timeout = 0,
					bg = beautiful.bg_urgent,
					fg = beautiful.fg_urgent
				})
				battery.widget.bar.color = beautiful.battery_bar_low
				low_battery_showed = true
			elseif low_battery_showed and battery_status.status == "Charging" then
				battery.widget.bar.color = beautiful.battery_bar_charged
				low_battery_showed = false
			end
		end
	}

	awful.tooltip
	{
		objects = {battery.widget},
		timer_function = function()
			return string.format("Status: %s\n%d%%", battery_status.status, battery_status.percentage)
		end
	}
end

return battery
