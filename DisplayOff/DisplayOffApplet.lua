--[[

Display Off Applet based on BlankScreen screensaver

--]]

local oo               = require("loop.simple")
local io               = require("io")
local Framework        = require("jive.ui.Framework")
local Window           = require("jive.ui.Window")
local Surface          = require("jive.ui.Surface")
local Icon             = require("jive.ui.Icon")
local Timer            = require("jive.ui.Timer")
local Applet           = require("jive.Applet")

local jnt              = jnt
local appletManager    = appletManager

module(..., Framework.constants)
oo.class(_M, Applet)


function openScreensaver(self, menuItem)
	log:info("open screensaver")
	self.window = Window("text_list")

	-- blank screen
	self.sw, self.sh = Framework:getScreenSize()
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
			self:_screen("on")
			self.window:hide()
			return EVENT_CONSUME
		end)

	local manager = appletManager:getAppletInstance("ScreenSavers")
	manager:screensaverWindow(self.window, _, _, _, "DisplayOff")

	self.window:show(Window.transitionFadeIn)
end


function closeScreensaver(self)
	log:info("close screensaver")
	self:_screen("on")
end


function onOverlayWindowShown(self)
	self:_screen("on")
end


function onOverlayWindowHidden(self)
	self:_screen("off")
end


local onTimer = Timer(200, function() _write("/sys/class/backlight/rpi_backlight/bl_power", "0") end, true)

function _screen(self, state)
	log:info("screen: ", state)
	if state == "on" then
		Framework:setUpdateScreen(true)
		_write("/sys/class/backlight/rpi_backlight/bl_power", "1")
		-- _write("/sys/devices/platform/fab4_gpio.0/LCD_DISP", "1")
		-- turn on backlight on timer to avoid white flash
		onTimer:restart()
	else
		Framework:setUpdateScreen(false)
		_write("/sys/class/backlight/rpi_backlight/bl_power", "1")
		-- _write("/sys/devices/platform/fab4_gpio.0/LCD_DISP", "0")
		onTimer:stop()
	end
end


function _write(file, val)
	local fh, err = io.open(file, "w")
	if err then
		log:warn("Can't write to ", file)
		return
	end
	fh:write(val)
	fh:close()
end

