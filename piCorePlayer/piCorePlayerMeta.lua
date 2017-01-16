local io                    = require("io")
local oo                    = require("loop.simple")
local AppletMeta            = require("jive.AppletMeta")
local appletManager         = appletManager
local jiveMain              = jiveMain

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
        -- pcp_enable_power_on_button_when_off = false,
        -- pcp_pi_network_interface_name = nil,
        -- pcp_LMS_MAC_address = nil,
    }
end

function configureApplet(self)
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
    		jiveMain:getSkinParamOrNil('piCorePlayerStyle')
    	)
    )

    if self:getSettings()['pcp_rpi_display_brightness'] then
        _write("/sys/class/backlight/rpi_backlight/brightness", self:getSettings()['pcp_rpi_display_brightness'])
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
