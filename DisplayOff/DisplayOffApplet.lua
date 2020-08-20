--[[

Display Off Time Peek Applet based on BlankScreen screensaver

--]]

local tonumber         = tonumber

local io               = require("io")
local os               = require("os")
local oo               = require("loop.simple")
local Framework        = require("jive.ui.Framework")
local Window           = require("jive.ui.Window")
local Surface          = require("jive.ui.Surface")
local Icon             = require("jive.ui.Icon")
local Group            = require("jive.ui.Group")
local Label            = require("jive.ui.Label")
local datetime         = require("jive.utils.datetime")
local Applet           = require("jive.Applet")
local Timer            = require("jive.ui.Timer")

local appletManager    = appletManager

module(..., Framework.constants)
oo.class(_M, Applet)

local current_brightness

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

function onOverlayWindowShown(self)
    self:_screen("on")

    local clockSet = datetime:isClockSet()

    if clockSet then
        local time = datetime:getCurrentTime()
        self.timeLabel = Group("text_block_black", {
            text = Label("text", time)
        })
        self.window:addWidget(self.timeLabel)
    else
        if self.timeLabel then
            self.window:removeWidget(self.timeLabel)
        end
        self.timeLabel = nil
    end
end

function onOverlayWindowHidden(self)
    self:_screen("off")

    if self.timeLabel then
        self.window:removeWidget(self.timeLabel)
        self.timeLabel = nil
    end
end

local on = "0"
local off = "1"
local lcdscript = "/home/tc/lcd-brightness.sh"

-- enable backlight on on a timer because the first revision of the official Pi display
-- isn't fast enough to handle backlight on directly/has a hardware bug/something else?
local timerOn = Timer(600,
    function()
        Framework:setUpdateScreen(true)
--CJH: Modification to allow use of a generic lcdscript script file if official 7" display is not present
--        if tonumber(_read("/sys/class/backlight/rpi_backlight/bl_power")) == tonumber(off) then
        if _file_exists("/sys/class/backlight/rpi_backlight/bl_power") then
        	if tonumber(_read("/sys/class/backlight/rpi_backlight/bl_power")) == tonumber(off) then
           		_write("/sys/class/backlight/rpi_backlight/bl_power", on)
        	end
        elseif _file_exists(lcdscript) then
-- turning display on: restore previous brightness
			log:debug("brightness to restore: " .. current_brightness)
			os.execute(lcdscript .. " " .. current_brightness)
        end
    end,
    true)

-- disable updates on a timer so the screen is filled with a black rectange
-- before the screen updates are turned off with setUpdateScreen(false)
local timerOff = Timer(1000,
    function()
        Framework:setUpdateScreen(false)
    end,
    true)
    
function _screen(self, state)
    if state == "on" then
        timerOff:stop()
        timerOn:start()
    elseif state == "off" then
        timerOn:stop()
--CJH: Modification to allow use of a generic lcdscript script file if official 7" display is not present
--        if tonumber(_read("/sys/class/backlight/rpi_backlight/bl_power")) == tonumber(on) then
        if _file_exists("/sys/class/backlight/rpi_backlight/bl_power") then
        	if tonumber(_read("/sys/class/backlight/rpi_backlight/bl_power")) == tonumber(on) then
            	_write("/sys/class/backlight/rpi_backlight/bl_power", off)
            end
        elseif _file_exists(lcdscript) then
-- turning display off: store current brightness so that it can be restored when the screensaver is deactivated
			current_brightness = _read_capture(lcdscript .. " C")
			log:debug("Brightness = " .. current_brightness)
			os.execute(lcdscript .. " 0") 
		end
        timerOff:start()
    end
end

function _read(file)
    local fh, err = io.open(file, "r")
    if err then
        return nil
    end
    local fc = fh:read("*all")
    fh:close()
    return fc
end

function _write(file, val)
    local fh, err = io.open(file, "w")
    if err then
        return
    end
    fh:write(val)
    fh:close()
end

function _file_exists(name)
   local f=io.open(name,"r")
   if f~=nil then io.close(f) return true else return false end
end

-- allows output of shell scripts to be captured.
function _read_capture(cmd)
    local fh, err = io.popen(cmd, "r")
    if err then
        return nil
    end
    local fc = fh:read("*a")
    fh:close()
    return fc
end


