--[[

Display Off Applet based on BlankScreen screensaver

--]]

local oo            = require("loop.simple")

local AppletMeta    = require("jive.AppletMeta")

local appletManager = appletManager

module(...)
oo.class(_M, AppletMeta)


function jiveVersion(self)
	return 1, 1
end


function registerApplet(self)
end


function configureApplet(self)
	-- add ourselves
	appletManager:callService("addScreenSaver",
		self:string("SCREENSAVER_DISPLAYOFF"),
		"DisplayOff", 
		"openScreensaver", _, _, 100, 
		"closeScreensaver"
	)
end
