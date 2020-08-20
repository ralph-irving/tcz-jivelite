local io                    = require("io")
local oo                    = require("loop.simple")
local AppletMeta            = require("jive.AppletMeta")
local appletManager         = appletManager
local jiveMain              = jiveMain

module(...)
oo.class(_M, AppletMeta)

local lcdscript = "/home/tc/lcd-brightness.sh"

function jiveVersion(self)
   return 1, 1
end

function registerApplet(self)
    self:registerService('getBacklightBrightnessWhenOn')
    self:registerService('getBacklightBrightnessWhenOff')
    self:registerService('getEnablePowerOnButtonWhenOff')
end

function defaultSettings(self)
    return {
        pcp_enable_power_on_button_when_off = true,
        -- pcp_pi_network_interface_name = nil,
        -- pcp_LMS_MAC_address = nil,
    }
end

function configureApplet(self)
    local icon
    local skin = jiveMain:getDefaultSkin()

    if skin == 'JogglerSkin' or skin == 'PiGridSkin' then
        icon = jiveMain:getSkinParamOrNil('piCorePlayerStyle')
    else
        icon = 'hm_settings'
    end

	-- we only register the menu her, as registerApplet is being called before the skin is initialized
    jiveMain:addItem(
    	self:menuItem(
    		'piCorePlayerApplet',
    		'settings',
    		'piCorePlayer',
    		function(applet, ...) 
    			applet:menu(...)
    		end,
    		100,
    		nil,
		icon
    	)
    )

--CJH: Modification to allow use of a generic lcdscript script file if official 7" display is not present
--    if self:getSettings()['pcp_rpi_display_brightness'] then
--        _write("/sys/class/backlight/rpi_backlight/brightness", self:getSettings()['pcp_rpi_display_brightness'])
--    end

    if self:getSettings()['pcp_rpi_display_brightness'] then
    	local stored_brightness = self:getSettings()['pcp_rpi_display_brightness']
    	log:debug("Stored Brightness = " .. stored_brightness)
		if _file_exists("/sys/class/backlight/rpi_backlight/brightness") then
    	    _write("/sys/class/backlight/rpi_backlight/brightness", stored_brightness)
    	elseif _file_exists(lcdscript) then
-- set brightness range
    		local cmd = lcdscript .. " R"
    		log:debug(cmd)
    		local retval = _read_capture(cmd)
    		log:debug("Result of setting brightness range: " .. retval)
-- set brightness to stored value.  This is required not only to ensure correct brightness on reboot
-- but also to put GPIO 13 into PWM mode, so that 'pigs GDC g' will work
			cmd = lcdscript .. " " .. stored_brightness
			log:debug(cmd)
			retval = _read_capture(cmd)
    		log:debug("Result of setting brightness value: " .. retval)
    	end
    else
    	log:debug("Brightness setting doesn't exist")
-- set brightness range
    	cmd = lcdscript .. " R"
    	log:debug(cmd)
    	retval = _read_capture(cmd)
    	log:debug("Result of setting brightness range: " .. retval)
-- set to full brightness.  This is required to put GPIO 13 into PWM mode, so that 'pigs GDC g' will work
    	cmd = lcdscript .. " F"
		log:debug(cmd)
		retval = _read_capture(cmd)
		log:debug("Result of setting brightness value: " .. retval)
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

function _file_exists(name)
   local f=io.open(name,"r")
   if f~=nil then io.close(f) return true else return false end
end

