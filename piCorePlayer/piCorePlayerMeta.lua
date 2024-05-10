local io                    = require("io")
local oo                    = require("loop.simple")
local AppletMeta            = require("jive.AppletMeta")
local appletManager         = appletManager
local jiveMain              = jiveMain
local rpi                   = require("jive.utils.rpi_bl")

module(...)
oo.class(_M, AppletMeta)

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

	if self:getSettings()['pcp_rpi_display_brightness'] then
		local stored_brightness = self:getSettings()['pcp_rpi_display_brightness']
		log:debug("Stored Brightness = " .. stored_brightness)

		if rpi.PiDisplay() == "pitouch" then
			rpi.set_pCP_display_current_brightness(stored_brightness)
		elseif rpi.PiDisplay == "lcd" then
			-- set brightness range
			local retval = rpi.run_lcd_script_command("R")
			log:debug("Result of setting brightness range: " .. retval)
			-- set brightness to stored value.  This is required not only to ensure correct brightness on reboot
			-- but also to put GPIO 13 into PWM mode, so that 'pigs GDC g' will work
			retval = rpi.run_lcd_script_command(stored_brightness)
			log:debug("Result of setting brightness value: " .. retval)
		end
	else
		log:debug("Brightness setting doesn't exist")
		-- set brightness range
		local retval = rpi.run_lcd_script_command("R")
		log:debug("Result of setting brightness range: " .. retval)
		-- set to full brightness.  This is required to put GPIO 13 into PWM mode, so that 'pigs GDC g' will work
		retval = rpi.run_lcd_script_command("F")
		log:debug("Result of setting brightness value: " .. retval)
	end
end
