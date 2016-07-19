--[[

Display Off Applet based on BlankScreen screensaver

--]]

local tostring, tonumber = tostring, tonumber

local io               = require("io")
local oo               = require("loop.simple")
local Framework        = require("jive.ui.Framework")
local Window           = require("jive.ui.Window")
local Surface          = require("jive.ui.Surface")
local Icon             = require("jive.ui.Icon")
local Applet           = require("jive.Applet")
local Timer            = require("jive.ui.Timer")

local appletManager    = appletManager

module(..., Framework.constants)
oo.class(_M, Applet)

function openScreensaver(self, menuItem)
	self.sw, self.sh = Framework:getScreenSize()

	-- create window and icon
	self.window = Window("text_list")
	self.bg  = Surface:newRGBA(self.sw, self.sh)
	self.bg:filledRectangle(0, 0, self.sw, self.sh, 0x000000FF)

	self.bgicon = Icon("icon", self.bg)
	self.window:addWidget(self.bgicon)

	self.window:setShowFrameworkWidgets(false)

	-- listeners to allow us to cancel from events, added after window is shown
	self.window:addListener(EVENT_WINDOW_ACTIVE | EVENT_HIDE,
		function(event)
			local type = event:getType()
			if type == EVENT_WINDOW_ACTIVE then
				self:_screen("off")
			else
				self:_screen("on")
			end
			return EVENT_UNUSED
		end,
		true
	)

	self.window:addListener(EVENT_MOTION,
		function()
			self.window:hide()
			return EVENT_CONSUME
		end)

	-- register window as a screensaver
	local manager = appletManager:getAppletInstance("ScreenSavers")
	manager:screensaverWindow(self.window, _, _, _, 'DisplayOff')

	self.window:show(Window.transitionNone)
end

function closeScreensaver(self)
	--nothing to do!
end

-- disable updates on a timer so the screen is filled with a black rectange
-- before the screen updates are turned off with setUpdateScreen(false)
local timer = Timer(2000, function() Framework:setUpdateScreen(false) end, true)

function _screen(self, state)
	if state == "on" then
		timer:stop()
		Framework:setUpdateScreen(true)
		_write("/sys/class/backlight/rpi_backlight/bl_power", "0")
	else
		_write("/sys/class/backlight/rpi_backlight/bl_power", "1")
		timer:start()
	end
end

function _write(file, val)
	local fh, err = io.open(file, "w")
	if err then
		return
	end
	fh:write(val)
	fh:close()
end
