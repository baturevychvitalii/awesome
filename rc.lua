-- If LuaRocks is installed, make sure that packages installed through it are
-- found (e.g. lgi). If LuaRocks is not installed, do nothing.
pcall(require, "luarocks.loader")

-- Standard awesome library
local gears = require("gears")
local awful = require("awful")
require("awful.autofocus")
-- Widget and layout library
local wibox = require("wibox")
-- Theme handling library
local beautiful = require("beautiful")
-- Notification library
local naughty = require("naughty")
local menubar = require("menubar")
local hotkeys_popup = require("awful.hotkeys_popup")

-- Enable hotkeys help widget for VIM and other apps
-- when client with a matching name is opened:
--require("awful.hotkeys_popup.keys")


-- {{{ Error handling
-- Check if awesome encountered an error during startup and fell back to
-- another config (This code will only ever execute for the fallback config)
if awesome.startup_errors then
    naughty.notify({ preset = naughty.config.presets.critical,
                     title = "Oops, there were errors during startup!",
                     text = awesome.startup_errors })
end

-- Handle runtime errors after startup
do
    local in_error = false
    awesome.connect_signal("debug::error", function (err)
        -- Make sure we don't go into an endless error loop
        if in_error then return end
        in_error = true

        naughty.notify({ preset = naughty.config.presets.critical,
                         title = "Oops, an error happened!",
                         text = tostring(err) })
        in_error = false
    end)
end
-- }}}

-- {{{ Variable definitions

-- This is used later as the default terminal and editor to run.
terminal = "xterm"
editor = os.getenv("EDITOR") or "vim"
editor_cmd = terminal .. " -e " .. editor

-- Default modkey.
-- Usually, Mod4 is the key with a logo between Control and Alt.
-- If you do not like this or do not have such a key,
-- I suggest you to remap Mod4 to another key using xmodmap or other tools.
-- However, you can use another modifier like Mod1, but it may interact with others.
modkey = "Mod4"

-- Table of layouts to cover with awful.layout.inc, order matters.
awful.layout.layouts = {
    awful.layout.suit.floating,
    awful.layout.suit.tile,
    awful.layout.suit.tile.bottom,
    awful.layout.suit.max,
}
-- }}}

-- Themes define colours, icons, font and wallpapers.
beautiful.init("~/.config/awesome/theme.lua")

-- Menubar configuration
menubar.utils.terminal = terminal -- Set the terminal for applications that require it
-- }}}

-- {{{ Wibar
-- Create a textclock widget
mytextclock = wibox.widget.textclock()

-- battery widget
local battery_status = {status = "N/A", percentage = 0}

local battery = wibox.widget {
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
	battery.bar.color = beautiful.battery_bar_miracle[math.random(0,#beautiful.battery_bar_miracle)]
end

battery.bar:buttons(awful.util.table.join(
    awful.button({}, 5, random_miracle ),
    awful.button({}, 4, random_miracle )
))

local battery_tooltip = awful.tooltip
{
	objects = {battery},
	timer_function = function()
		return string.format("Status: %s\n%d%%", battery_status.status, battery_status.percentage)
	end
}

local low_battery_showed = false
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
		battery.bar:set_value(battery_status.percentage)
		if battery_status.percentage <= 10 and battery_status.status == "Discharging" and (not low_battery_showed) then
			naughty.notify({
				text = "Веталя, заряди меня пожалуйста",
				title = "Села батарейка",
				timeout = 0,
				bg = beautiful.bg_urgent,
				fg = beautiful.fg_urgent
			})
			battery.bar.color = beautiful.battery_bar_low
			low_battery_showed = true
		elseif low_battery_showed and battery_status.status == "Charging" then
			battery.bar.color = beautiful.battery_bar_charged
			low_battery_showed = false
		end
	end
}

local bar_width = 77 
-- brightness widget
local brightness = {}
brightness.bar = wibox.widget {
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
	forced_width  = bar_width,
	layout = wibox.layout.stack
}

brightness.update = function()
	awful.spawn.easy_async_with_shell("Vbrightness %", function(stdout)
		brightness.bar.bar:set_value(tonumber(stdout))
	end)
end

brightness.bar:buttons(awful.util.table.join(
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

-- volume widget
local volume = {}
volume.bar = wibox.widget {
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
	forced_width  = bar_width,
	layout = wibox.layout.stack
}

volume.update = function()
	awful.spawn.easy_async_with_shell("Vvolume %", function(stdout)
		local curr_volume = string.match(stdout, "Volume: (%d+)")
		local muted = string.match(stdout, "Mute: (%S+)")
		
		-- set foreground color
		if muted == "no" then
			volume.bar.bar.color = beautiful.volume_bar_unmute
		else
			volume.bar.bar.color = beautiful.volume_bar_mute
		end
		
		volume.bar.bar:set_value(tonumber(curr_volume))
	end)
end

volume.bar:buttons(awful.util.table.join(
    awful.button({}, 2, function() -- middle click
		awful.spawn.easy_async_with_shell("Vvolume 50",function()end)
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

brightness.update()
volume.update()

-- Create a wibox for each screen and add it
local taglist_buttons = gears.table.join(
                    awful.button({ }, 1, function(t) t:view_only() end),
                    awful.button({ modkey }, 1, function(t)
                                              if client.focus then
                                                  client.focus:move_to_tag(t)
                                              end
                                          end),
                    awful.button({ }, 3, awful.tag.viewtoggle),
                    awful.button({ modkey }, 3, function(t)
                                              if client.focus then
                                                  client.focus:toggle_tag(t)
                                              end
                                          end),
                    awful.button({ }, 4, function(t) awful.tag.viewnext(t.screen) end),
                    awful.button({ }, 5, function(t) awful.tag.viewprev(t.screen) end)
                )

local tasklist_buttons = gears.table.join(
                     awful.button({ }, 1, function (c)
                                              if c == client.focus then
                                                  c.minimized = true
                                              else
                                                  c:emit_signal(
                                                      "request::activate",
                                                      "tasklist",
                                                      {raise = true}
                                                  )
                                              end
                                          end),
                     awful.button({ }, 3, function()
                                              awful.menu.client_list({ theme = { width = 250 } })
                                          end),
                     awful.button({ }, 4, function ()
                                              awful.client.focus.byidx(1)
                                          end),
                     awful.button({ }, 5, function ()
                                              awful.client.focus.byidx(-1)
                                          end))

local function set_wallpaper(s)
    -- Wallpaper
    if beautiful.wallpaper then
        local wallpaper = beautiful.wallpaper
        -- If wallpaper is a function, call it with the screen
        if type(wallpaper) == "function" then
            wallpaper = wallpaper(s)
        end
        gears.wallpaper.maximized(wallpaper, s, true)
    end
end

-- Re-set wallpaper when a screen's geometry changes (e.g. different resolution)
screen.connect_signal("property::geometry", set_wallpaper)

awful.screen.connect_for_each_screen(function(s)
    -- Wallpaper
    set_wallpaper(s)

    -- Each screen has its own tag table.
    awful.tag({ "1", "2", "3", "4" }, s, {awful.layout.suit.tile,
											awful.layout.suit.max,
											awful.layout.suit.floating,
											awful.layout.suit.floating
										 })

    -- Create a promptbox for each screen
    s.mypromptbox = awful.widget.prompt()
    -- Create an imagebox widget which will contain an icon indicating which layout we're using.
    -- We need one layoutbox per screen.
    s.mylayoutbox = awful.widget.layoutbox(s)
    s.mylayoutbox:buttons(gears.table.join(
                           awful.button({ }, 1, function () awful.layout.inc( 1) end),
                           awful.button({ }, 3, function () awful.layout.inc(-1) end),
                           awful.button({ }, 4, function () awful.layout.inc( 1) end),
                           awful.button({ }, 5, function () awful.layout.inc(-1) end)))
    -- Create a taglist widget
    s.mytaglist = awful.widget.taglist {
        screen  = s,
        filter  = awful.widget.taglist.filter.all,
        buttons = taglist_buttons
    }

    -- Create a tasklist widget
    s.mytasklist = awful.widget.tasklist {
        screen  = s,
        filter  = awful.widget.tasklist.filter.currenttags,
        buttons = tasklist_buttons
    }

    -- Create the wibox
    s.mywibox = awful.wibar({ position = "top", screen = s })

    -- Add widgets to the wibox
    s.mywibox:setup {
        layout = wibox.layout.align.horizontal,
        { -- Left widgets
            layout = wibox.layout.fixed.horizontal,
            mylauncher,
            s.mytaglist,
			wibox.widget.textbox("|"),
			volume.bar,
			wibox.widget.textbox("|"),
			brightness.bar,
			wibox.widget.textbox("|"),
            s.mypromptbox,
        },
        s.mytasklist, -- Middle widget
        { -- Right widgets
            layout = wibox.layout.fixed.horizontal,
            wibox.widget.systray(),
            mytextclock,
			battery,
            s.mylayoutbox,
        },
    }
end)
-- }}}

-- {{{ Mouse bindings
root.buttons(gears.table.join(
    awful.button({ }, 4, awful.tag.viewnext),
    awful.button({ }, 5, awful.tag.viewprev)
))
-- }}}

-- {{{ Key bindings
globalkeys = gears.table.join(
    awful.key({ modkey,           }, "s",      hotkeys_popup.show_help,
              {description="show help", group="awesome"}),
    awful.key({ modkey,           }, "Left",   awful.tag.viewprev,
              {description = "view previous", group = "tag"}),
    awful.key({ modkey,           }, "Right",  awful.tag.viewnext,
              {description = "view next", group = "tag"}),
    awful.key({ modkey,           }, "Escape", awful.tag.history.restore,
              {description = "go back", group = "tag"}),

    awful.key({ modkey,           }, "j",
        function ()
            awful.client.focus.byidx( -1)
        end,
        {description = "focus next by index", group = "client"}
    ),
    awful.key({ modkey,           }, "k",
        function ()
            awful.client.focus.byidx(1)
        end,
        {description = "focus previous by index", group = "client"}
    ),

    -- Layout manipulation
    awful.key({ modkey, "Shift"   }, "j", function () awful.client.swap.byidx(  -1)    end,
              {description = "swap with next client by index", group = "client"}),
    awful.key({ modkey, "Shift"   }, "k", function () awful.client.swap.byidx( 1)    end,
              {description = "swap with previous client by index", group = "client"}),
    awful.key({ modkey, "Control" }, "j", function () awful.screen.focus_relative( -1) end,
              {description = "focus the next screen", group = "screen"}),
    awful.key({ modkey, "Control" }, "k", function () awful.screen.focus_relative(1) end,
              {description = "focus the previous screen", group = "screen"}),
    awful.key({ modkey,           }, "u", awful.client.urgent.jumpto,
              {description = "jump to urgent client", group = "client"}),
    awful.key({ modkey,           }, "Tab",
        function ()
            awful.client.focus.history.previous()
            if client.focus then
                client.focus:raise()
            end
        end,
        {description = "go back", group = "client"}),

    -- Standard program
    awful.key({ modkey,           }, "Return", function () awful.spawn(terminal) end,
              {description = "open a terminal", group = "launcher"}),
    awful.key({ modkey, "Control" }, "r", awesome.restart,
              {description = "reload awesome", group = "awesome"}),
    awful.key({ modkey, "Shift"   }, "q", awesome.quit,
              {description = "quit awesome", group = "awesome"}),

    awful.key({ modkey,           }, "l",     function () awful.tag.incmwfact( 0.05)          end,
              {description = "increase master width factor", group = "layout"}),
    awful.key({ modkey,           }, "h",     function () awful.tag.incmwfact(-0.05)          end,
              {description = "decrease master width factor", group = "layout"}),
    awful.key({ modkey, "Shift"   }, "h",     function () awful.tag.incnmaster( -1, nil, true) end,
              {description = "decrease the number of master clients", group = "layout"}),
    awful.key({ modkey, "Shift"   }, "l",     function () awful.tag.incnmaster(1, nil, true) end,
              {description = "increase the number of master clients", group = "layout"}),
    awful.key({ modkey, "Control" }, "h",     function () awful.tag.incncol( -1, nil, true)    end,
              {description = "decrease the number of columns", group = "layout"}),
    awful.key({ modkey, "Control" }, "l",     function () awful.tag.incncol(1, nil, true)    end,
              {description = "increase the number of columns", group = "layout"}),
    awful.key({ modkey,           }, "space", function () awful.layout.inc( 1)                end,
              {description = "select next", group = "layout"}),
    awful.key({ modkey, "Shift"   }, "space", function () awful.layout.inc(-1)                end,
              {description = "select previous", group = "layout"}),

    awful.key({ modkey, "Control" }, "n",
              function ()
                  local c = awful.client.restore()
                  -- Focus restored client
                  if c then
                    c:emit_signal(
                        "request::activate", "key.unminimize", {raise = true}
                    )
                  end
              end,
              {description = "restore minimized", group = "client"}),

    -- Prompt
    awful.key({ modkey },            "r",     function () awful.screen.focused().mypromptbox:run() end,
              {description = "run prompt", group = "launcher"}
	),
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
	),
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
	),
	awful.key({}, "XF86AudioMicMute", function()awful.util.spawn_with_shell("Vbluetoothtoggle")end,
		{description = "toggle bluetooth", group = "system"}
	),
	awful.key({}, "XF86WebCam", function() awful.util.spawn_with_shell("xset s activate")end,
		{description = "lock session", group = "system"}
	),

	awful.key({}, "Print", function() awful.util.spawn_with_shell("Vscreenshot full")end,
		{description = "screen capture whole screen", group = "screenshot"}
	),
	awful.key({ modkey }, "Print", function() awful.util.spawn_with_shell("Vscreenshot focused")end,
		{description = "screen capture focused window", group = "screenshot"}
	),
	awful.key({ modkey, "Shift" }, "Print", function() awful.util.spawn_with_shell("sleep 0.2 && Vscreenshot select")end,
		{description = "screen capture selected area", group = "screenshot"}
	),
	awful.key({ modkey }, "b",
          function ()
              myscreen = awful.screen.focused()
              myscreen.mywibox.visible = not myscreen.mywibox.visible
          end,
          {description = "toggle statusbar", group = "awesome"}
	)
)

clientkeys = gears.table.join(
    awful.key({ modkey,           }, "f",
        function (c)
            c.fullscreen = not c.fullscreen
            c:raise()
        end,
        {description = "toggle fullscreen", group = "client"}),
    awful.key({ modkey,           }, "c",      function (c) c:kill()                         end,
              {description = "close", group = "client"}),
    awful.key({ modkey, "Control" }, "space",  awful.client.floating.toggle                     ,
              {description = "toggle floating", group = "client"}),
    awful.key({ modkey, "Control" }, "Return", function (c) c:swap(awful.client.getmaster()) end,
              {description = "move to master", group = "client"}),
    awful.key({ modkey,           }, "o",      function (c) c:move_to_screen()               end,
              {description = "move to screen", group = "client"}),
    awful.key({ modkey,           }, "t",      function (c) c.ontop = not c.ontop            end,
              {description = "toggle keep on top", group = "client"}),
    awful.key({ modkey,           }, "n",
        function (c)
            -- The client currently has the input focus, so it cannot be
            -- minimized, since minimized clients can't have the focus.
            c.minimized = true
        end ,
        {description = "minimize", group = "client"}),
    awful.key({ modkey,           }, "m",
        function (c)
            c.maximized = not c.maximized
            c:raise()
        end ,
        {description = "(un)maximize", group = "client"}),
    awful.key({ modkey, "Control" }, "m",
        function (c)
            c.maximized_vertical = not c.maximized_vertical
            c:raise()
        end ,
        {description = "(un)maximize vertically", group = "client"}),
    awful.key({ modkey, "Shift"   }, "m",
        function (c)
            c.maximized_horizontal = not c.maximized_horizontal
            c:raise()
        end ,
        {description = "(un)maximize horizontally", group = "client"}),
	awful.key({ modkey, "Control" }, "t", function(c) awful.titlebar.toggle(c) end,
		{description = "toggle titlebar", group = "client"}
	)
)

-- Bind all key numbers to tags.
-- Be careful: we use keycodes to make it work on any keyboard layout.
-- This should map on the top row of your keyboard, usually 1 to 9.
for i = 1, 9 do
    globalkeys = gears.table.join(globalkeys,
        -- View tag only.
        awful.key({ modkey }, "#" .. i + 9,
                  function ()
                        local screen = awful.screen.focused()
                        local tag = screen.tags[i]
                        if tag then
                           tag:view_only()
                        end
                  end,
                  {description = "view tag #"..i, group = "tag"}),
        -- Toggle tag display.
        awful.key({ modkey, "Control" }, "#" .. i + 9,
                  function ()
                      local screen = awful.screen.focused()
                      local tag = screen.tags[i]
                      if tag then
                         awful.tag.viewtoggle(tag)
                      end
                  end,
                  {description = "toggle tag #" .. i, group = "tag"}),
        -- Move client to tag.
        awful.key({ modkey, "Shift" }, "#" .. i + 9,
                  function ()
                      if client.focus then
                          local tag = client.focus.screen.tags[i]
                          if tag then
                              client.focus:move_to_tag(tag)
                          end
                     end
                  end,
                  {description = "move focused client to tag #"..i, group = "tag"}),
        -- Toggle tag on focused client.
        awful.key({ modkey, "Control", "Shift" }, "#" .. i + 9,
                  function ()
                      if client.focus then
                          local tag = client.focus.screen.tags[i]
                          if tag then
                              client.focus:toggle_tag(tag)
                          end
                      end
                  end,
                  {description = "toggle focused client on tag #" .. i, group = "tag"})
    )
end

clientbuttons = gears.table.join(
    awful.button({ }, 1, function (c)
        c:emit_signal("request::activate", "mouse_click", {raise = true})
    end),
    awful.button({ modkey }, 1, function (c)
        c:emit_signal("request::activate", "mouse_click", {raise = true})
        awful.mouse.client.move(c)
    end),
    awful.button({ modkey }, 3, function (c)
        c:emit_signal("request::activate", "mouse_click", {raise = true})
        awful.mouse.client.resize(c)
    end)
)

-- Set keys
root.keys(globalkeys)
-- }}}

local telegram_close_counter = 0

-- {{{ Rules
-- Rules to apply to new clients (through the "manage" signal).
awful.rules.rules = {
    -- All clients will match this rule.
    { rule = { },
      properties = { border_width = beautiful.border_width,
                     border_color = beautiful.border_normal,
                     focus = awful.client.focus.filter,
                     raise = true,
                     keys = clientkeys,
                     buttons = clientbuttons,
                     screen = awful.screen.preferred,
                     placement = awful.placement.no_overlap+awful.placement.no_offscreen,
					 size_hints_honor = false,
					 titlebars_enabled = false
     }
    },

    -- Floating clients.
    {
		rule_any = {
			class = {
				"Tor Browser", -- Needs a fixed window size to avoid fingerprinting by screen size.
				"Ida",
				"vlc",
				"KeePassXC",
			},

			-- Note that the name property shown in xprop might be set slightly after creation of the client
			-- and the name shown there might not match defined rules here.
			name = {
				"Event Tester",  -- xev.
			},
			type = {
				"dialog"
			},
		}, 
		properties = { floating = true, titlebars_enabled = true }
	},

    {
		rule_any = { 
			class = {
				"firefox",
				"Skype",
				"Spotify"
			},
		},
		properties = { tag = "2" } 
	},

	{
		rule_any = {
			class = {
				"Steam",
				"Wine",
				"discord"
			},
		},
		properties = { tag = "3", floating = true, titlebars_enabled = true }
	},

	{
		rule = {class = "steam_app.*" },
		properties = { tag = "3", floating = true }
	},

	{
		rule = {class =	"XTerm"},
		properties = { screen = 1, tag = "1" }
	},

	{
		rule = {name = ".* - Oracle VM VirtualBox"},
		properties = { tag = "4", fullscreen = true }
	},

	-- close telegram after boot cause it's annoying to see
	{
		rule = {name = "Telegram"},
		callback = function(c)
			if telegram_close_counter == 0 then
				telegram_close_counter = 1
				c:kill()
			end
		end
	},
}
-- }}}

-- {{{ Signals
-- Signal function to execute when a new client appears.
client.connect_signal("manage", function (c)
    -- Set the windows at the slave,
    -- i.e. put it at the end of others instead of setting it master.
    -- if not awesome.startup then awful.client.setslave(c) end

    if awesome.startup
      and not c.size_hints.user_position
      and not c.size_hints.program_position then
        -- Prevent clients from being unreachable after screen count changes.
        awful.placement.no_offscreen(c)
    end
end)

-- Add a titlebar if titlebars_enabled is set to true in the rules.
client.connect_signal("request::titlebars", function(c)
    -- buttons for the titlebar
    local buttons = gears.table.join(
        awful.button({ }, 1, function()
            c:emit_signal("request::activate", "titlebar", {raise = true})
            awful.mouse.client.move(c)
        end),
        awful.button({ }, 3, function()
            c:emit_signal("request::activate", "titlebar", {raise = true})
            awful.mouse.client.resize(c)
        end)
    )

    awful.titlebar(c) : setup {
        { -- Left
            awful.titlebar.widget.iconwidget(c),
            buttons = buttons,
            layout  = wibox.layout.fixed.horizontal
        },
        { -- Middle
            { -- Title
                align  = "center",
                widget = awful.titlebar.widget.titlewidget(c)
            },
            buttons = buttons,
            layout  = wibox.layout.flex.horizontal
        },
        { -- Right
            awful.titlebar.widget.floatingbutton (c),
            awful.titlebar.widget.closebutton    (c),
            layout = wibox.layout.fixed.horizontal()
        },
        layout = wibox.layout.align.horizontal
    }
end)

-- Enable sloppy focus, so that focus follows mouse.

client.connect_signal("mouse::enter", function(c)
    c:emit_signal("request::activate", "mouse_enter", {raise = false})
end)

client.connect_signal("focus", function(c)
	c.border_color = beautiful.border_focus 
end)

client.connect_signal("unfocus", function(c)
	c.border_color = beautiful.border_normal
end)

client.connect_signal("property::minimized", function(c) if
	c.class == "dota2" or
	c.class == "csgo_linux64"
then c.minimized = false end end)

function tablelength(T)
  local count = 0
  for k,v in pairs(T) do count = count + 1 end
  return count
end

screen.connect_signal("arrange", function (s)
    local max = s.selected_tag.layout.name == "max"
	local only_one = tablelength(s.clients) == 1
    -- but iterate over clients instead of tiled_clients as tiled_clients doesn't include maximized windows
    for _, c in pairs(s.clients) do
		if max and not c.floating or only_one or c.maximized then
            c.border_width = 0
        else
            c.border_width = beautiful.border_width
        end
    end
end)
-- }}}

awful.util.spawn_with_shell("~/.config/awesome/autorun.sh")

