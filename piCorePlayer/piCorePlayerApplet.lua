--[[
v2  adds pcp command in os.execute, backlight off when shutting down and Dutch translation
v3  adds version number checking
v4  adds backlight brightness adjustment for the official Raspberry Pi display rev. 1.1
v5  adds option to rescan LMS media library for pCP 2.x
v6  improve rescan LMS media library with a 5 seconds countdown and check if player is conencted to LMS or if a rescan is already running
    adds option to adjust backlight brightness when player is off (for this to work multiple JiveLite hacks are needed)
v7  adds checkbox to enable/disable power on button when off (needs JiveLite hacks)
    adds WOL menu
v8  updated WOL menu with working add and remove menu options
v9  WOL settings saved to /opt/bootlocal.sh
v10 WOL settings saved to /usr/local/sbin/config.cfg and evaluated in /home/tc/www/cgi-bin/do_rebootstuff.sh
v11 Updates for pi5, refactor code into rpi_bl.lua
   
Lua/Jive/JiveLite bugs/problems encountered:
    - keyboard cursor key up moves volume slider down
    - keyboard cursor key down moves volume slider up
    - inconsistent behaviour when pressing 'right' on the remote or keyboard and the -first- menu item opens a popup which has a
      brightness_slider or settings_slider -> looks like the 'right' press is ignored until you first press down and up!
--]]

local tostring          = tostring
local tonumber          = tonumber
local ipairs            = ipairs

local table             = require("table")
local string            = require("string")
local math              = require("math")
local os                = require("os")
local io                = require("io")
local oo                = require("loop.simple")
local Event             = require("jive.ui.Event")
local Icon              = require("jive.ui.Icon")
local Label             = require("jive.ui.Label")
local Popup             = require("jive.ui.Popup")
local SimpleMenu        = require("jive.ui.SimpleMenu")
local Window            = require("jive.ui.Window")
local Slider            = require("jive.ui.Slider")
local Textarea          = require("jive.ui.Textarea")
local Group             = require("jive.ui.Group")
local Framework         = require("jive.ui.Framework")
local Checkbox          = require("jive.ui.Checkbox")
local Choice            = require("jive.ui.Choice")
local Textinput         = require("jive.ui.Textinput")
local Keyboard          = require("jive.ui.Keyboard")
local rpi               = require("jive.utils.rpi_bl")

local debug             = require("jive.utils.debug")

local Applet            = require("jive.Applet")

local appletManager     = appletManager

module(..., Framework.constants)
oo.class(_M, Applet)

local pCP_version_file_location = "/usr/local/etc/pcp/pcpversion.cfg"

local pCP_list_network_interfaces_cmd = "ls -1 /sys/class/net/"

local pCP_WOL_config_file_location = "/usr/local/etc/pcp/pcp.cfg"
local pCP_WOL_searchstring_WOL = "WOL="
local pCP_WOL_searchstring_WOL_NIC = "WOL_NIC="
local pCP_WOL_searchstring_WOL_LMSMACADDRESS = "WOL_LMSMACADDRESS="

local pCP_1_22_reboot_cmd = "/home/tc/.local/bin/pcp rb"
local pCP_1_22_shutdown_cmd = "/home/tc/.local/bin/pcp sd"
local pCP_1_22_save_cmd = "/home/tc/.local/bin/pcp bu"

local pCP_2_0_reboot_cmd = "/usr/local/sbin/pcp rb"
local pCP_2_0_shutdown_cmd = "/usr/local/sbin/pcp sd"
local pCP_2_0_save_cmd = "/usr/local/sbin/pcp bu"

local pCP_3_2_reboot_cmd = "/usr/local/bin/pcp rb"
local pCP_3_2_shutdown_cmd = "/usr/local/bin/pcp sd"
local pCP_3_2_save_cmd = "/usr/local/bin/pcp bu"

local pCP_default_reboot_cmd = "sudo reboot"
local pCP_default_shutdown_cmd = "sudo poweroff"
local pCP_default_save_cmd = "sudo filetool.sh -b"

local pCP_is_player_connected_to_LMS_cmd = "/usr/local/sbin/pcp connection_status"

local pCP_rescan_LMS_media_library_min_version = 2.06
local pCP_rescan_LMS_media_library_cmd = "/usr/local/sbin/pcp rescan"
local pCP_rescan_LMS_media_library_in_progress_cmd = "/usr/local/sbin/pcp rescan_status"

function menu(self, menuItem)
    local window = Window("text_list", "piCorePlayer")
    local menu = SimpleMenu("menu")

    menu:addItem({ text = self:string("MENU_REBOOT"),
            callback = function(event, menuItem)
                self:rebootPi(menuItem)
            end })

    menu:addItem({ text = self:string("MENU_SHUTDOWN"),
            callback = function(event, menuItem)
                self:shutdownPi(menuItem)
            end })

    menu:addItem({ text = self:string("MENU_RESCAN_LMS_MEDIA_LIBRARY"),
            callback = function(event, menuItem)
                self:rescanLMSMediaLibrary(menuItem)
            end })

    menu:addItem({ text = self:string("MENU_ADJUST_BRIGHTNESS"),
            callback = function(event, menuItem)
                self:adjustDisplayBrightness(menuItem)
            end })

    menu:addItem({ text = self:string("MENU_ADJUST_BRIGHTNESS_WHEN_OFF"),
            callback = function(event, menuItem)
                self:adjustDisplayBrightnessWhenOff(menuItem)
            end })
            
    local is_checked = self:getSettings()["pcp_enable_power_on_button_when_off"]
    if is_checked == nil then
        is_checked = false
    end

    menu:addItem({ text = self:string("MENU_ENABLE_POWER_ON_BUTTON_WHEN_OFF"), 
            style = "item_choice",
            check = Checkbox(
                "checkbox",
                function(object, isSelected)
                    self:getSettings()["pcp_enable_power_on_button_when_off"] = isSelected
                    self:storeSettings()
                end,
                is_checked
                )
            })

    menu:addItem({ text = self:string("MENU_WAKE_ON_LAN"),
            callback = function(event, menuItem)
                self:menuWOL(menuItem)
            end })

    menu:addItem({ text = self:string("MENU_SAVE_SETTINGS"),
            callback = function(event, menuItem)
                self:saveToSDCard(menuItem)
            end })

    window:addWidget(menu)

    self:tieAndShowWindow(window)
    return window
end

function getBacklightBrightnessWhenOn(self)
    return self:getSettings()["pcp_rpi_display_brightness"]
end

function getBacklightBrightnessWhenOff(self)
    return self:getSettings()["pcp_rpi_display_brightness_when_off"]
end

function getEnablePowerOnButtonWhenOff(self)
    return self:getSettings()["pcp_enable_power_on_button_when_off"]
end

function menuWOL(self, menuItem)
    if getpCPVersion() ~= nil then
        local window = Window("text_list", self:string("WOL_MENU_TITLE"))
        local menu = SimpleMenu("menu")
        
        menu:addItem({ text = self:string("WOL_MENU_SEND_WOL_PACKET"),
            callback = function(event, menuItem)
                self:sendWOLPacket(menuItem)
            end })
        
        --this should return the value defined in defaultSettings() in piCorePlayerMeta.lua but it doesn't
        --it just returns nil
        local macAddress = self:getSettings()["pcp_LMS_MAC_address"]
        if macAddress == nil then
            macAddress = ""
        else
            macAddress = macAddress:gsub(("(%x%x)"):rep(6), "%1:%2:%3:%4:%5:%6")
        end
        
        menu:addItem({ text = tostring(self:string("WOL_MENU_LMS_MAC_ADDRESS")) .. " (" .. macAddress .. ")",
            callback = function(event, menuItem)
                self:keyboardLMSMACAddress(menuItem)
            end })

        local networkInterfaces = {}
        networkInterfaces = getNetworkInterfaces()
        -- empty table could exist when LMS runs on piCorePlayer and all network interfaces are disabled!
        -- the #arrayname construction only works if the table is using the default keys (1, 2, 3, ...) 
        local networkInterfacesFound = true
        if #networkInterfaces == 0 then
            networkInterfaces[1] = ""
            networkInterfacesFound = false
        end
    
        local networkInterfaceIndex = 1
        local networkInterfaceIndexFound = false
        if networkInterfacesFound == true then
            for index, value in ipairs(networkInterfaces) do
                if value == self:getSettings()["pcp_pi_network_interface_name"] then
                    networkInterfaceIndex = index
                    networkInterfaceIndexFound = true
                    break
                end
            end
        end
        
        -- if nics are found but pcp_pi_network_interface_name is not part of this list
        -- save the first nic (networkInterfaces[1]) to pcp_pi_network_interface_name
        if networkInterfacesFound == true and networkInterfaceIndexFound == false then
            self:getSettings()["pcp_pi_network_interface_name"] = networkInterfaces[1]
            self:storeSettings()
        end
        
        menu:addItem({ text = self:string("WOL_MENU_NETWORK_INTERFACE"),
            style = "item_choice",
            check = Choice(
                "choice", 
                networkInterfaces,
                function(obj, selectedIndex)
                    if tostring(obj:getSelected()) ~= "" then
                        self:getSettings()["pcp_pi_network_interface_name"] = tostring(obj:getSelected())
                        self:storeSettings()
                    end
                end,
                networkInterfaceIndex
            )
        })

        local is_checked = self:getSettings()["pcp_enable_wol_in_pcp_config"]
        if is_checked == nil then
            is_checked = false
            self:getSettings()["pcp_enable_wol_in_pcp_config"] = is_checked
            self:storeSettings()
        end

        menu:addItem({ text = self:string("WOL_MENU_ENABLE_WOL_IN_PCP_CONFIG"), 
                style = "item_choice",
                check = Checkbox(
                    "checkbox",
                    function(object, isSelected)
                        self:getSettings()["pcp_enable_wol_in_pcp_config"] = isSelected
                        self:storeSettings()
                    end,
                    is_checked
                    )
                })

        menu:addItem({ text = self:string("WOL_MENU_UPDATE_PCP_CONFIG"),
            callback = function(event, menuItem)
                self:updatepCPConfig(menuItem)
            end })

        window:addWidget(menu)

        self:tieAndShowWindow(window)
        return window
    else
        self:showPopupMessage(tostring(self:string("LABEL_ERROR_NO_PICOREPLAYER_VERSION_FOUND")), 2500)
    end
end

function updatepCPConfig(self, menuItem)
    if self:getSettings()["pcp_LMS_MAC_address"] then
        if self:getSettings()["pcp_pi_network_interface_name"] then
            if self:getSettings()["pcp_enable_wol_in_pcp_config"] ~= nil then -- this should never happen!
                
                local tbl = read_textfile_to_table(pCP_WOL_config_file_location)
                
                -- lua magic characters: ^$()%.[]*+-?)
                -- should be escaped with a %

                if tbl then
                    local WOLfailedCount = 3
                    
                    --search for 'WOL='
                    local index = table_find(pCP_WOL_searchstring_WOL, tbl)
                    if index then
                        --update WOL=
                        if self:getSettings()["pcp_enable_wol_in_pcp_config"] == true then
                            tbl[index] = "WOL=\"yes\""
                            WOLfailedCount = WOLfailedCount - 1
                        elseif self:getSettings()["pcp_enable_wol_in_pcp_config"] == false then
                            tbl[index] = "WOL=\"no\""
                            WOLfailedCount = WOLfailedCount - 1
                        end
                    end
                    
                    --search for 'WOL_NIC='
                    index = table_find(pCP_WOL_searchstring_WOL_NIC, tbl)
                    if index then
                        --update WOL_NIC=
                        tbl[index] = "WOL_NIC=\"" .. self:getSettings()["pcp_pi_network_interface_name"] .. "\""
                        WOLfailedCount = WOLfailedCount - 1
                    end
                    
                    --search for 'WOL_LMSMACADDRESS='
                    index = table_find(pCP_WOL_searchstring_WOL_LMSMACADDRESS, tbl)
                    if index then
                        --update WOL_LMSMACADDRESS=
                        tbl[index] = "WOL_LMSMACADDRESS=\"" .. tostring(self:getSettings()["pcp_LMS_MAC_address"]):gsub(("(%x%x)"):rep(6), "%1:%2:%3:%4:%5:%6") .. "\""
                        WOLfailedCount = WOLfailedCount - 1
                    end

                    if WOLfailedCount < 3 then
                        --write /usr/local/sbin/config.cfg
                        write_table_to_textfile(pCP_WOL_config_file_location, tbl)
                    end
                    
                    if WOLfailedCount == 0 then
                        self:showPopupMessage(tostring(self:string("LABEL_WOL_PCP_CONFIG_SAVE_SUCCES")), 5000)
                    elseif WOLfailedCount > 0 and WOLfailedCount < 3 then
                        self:showPopupMessage(tostring(self:string("LABEL_WOL_PCP_CONFIG_SAVE_WARNING")), 2500)
                    elseif WOLfailedCount == 3 then
                        self:showPopupMessage(tostring(self:string("LABEL_WOL_PCP_CONFIG_SAVE_ERROR")), 2500)
                    end
                else
                    self:showPopupMessage("LABEL_WOL_UPDATE_PCP_CONFIG_NOT_FOUND", 2500)
                    self:showPopupMessage(tostring(self:string("LABEL_WOL_ERROR_NO_ENABLE_WOL")), 2500)
                end
            else
                self:showPopupMessage(tostring(self:string("LABEL_WOL_ERROR_NO_ENABLE_WOL")), 2500)
            end
        else
            self:showPopupMessage(tostring(self:string("LABEL_WOL_ERROR_NO_NETWORK_INTERFACE")), 2500)
        end
    else
        self:showPopupMessage(tostring(self:string("LABEL_WOL_ERROR_NO_LMS_MAC_ADDRESS")), 2500)
    end
end

function sendWOLPacket(self, menuItem)
    if self:getSettings()["pcp_LMS_MAC_address"] then
        if self:getSettings()["pcp_pi_network_interface_name"] then
            os.execute("ether-wake -i " .. self:getSettings()["pcp_pi_network_interface_name"] .. " " .. tostring(self:getSettings()["pcp_LMS_MAC_address"]):gsub(("(%x%x)"):rep(6), "%1:%2:%3:%4:%5:%6"))
            
            local popupText = tostring(self:string("LABEL_WOL_SEND_WOL_PACKET")) .. " " .. tostring(self:getSettings()["pcp_LMS_MAC_address"]):gsub(("(%x%x)"):rep(6), "%1:%2:%3:%4:%5:%6") .. " (" .. self:getSettings()["pcp_pi_network_interface_name"] .. ")"

            self:showPopupMessage(popupText, 2500)
        else
            self:showPopupMessage(tostring(self:string("LABEL_WOL_ERROR_NO_NETWORK_INTERFACE")), 2500)
        end
    else
        self:showPopupMessage(tostring(self:string("LABEL_WOL_ERROR_NO_LMS_MAC_ADDRESS")), 2500)
    end
end

function keyboardLMSMACAddress(self, menuItem)
    local window = Window("text_list", self:string("LABEL_WOL_KEYBOARD_TITLE"))

    window:setAllowScreensaver(false)
            
    local macAddress = self:getSettings()["pcp_LMS_MAC_address"]
    if macAddress == nil then
        macAddress = ""
    end 
    
    -- restore saved MAC address, set character limit to 12 and minimum allowed number of characters to 12
    local defaultText = Textinput.textValue(macAddress, 12, 12)
    
    local input = Textinput("textinput", defaultText,
        function(_, value)
            self:getSettings()["pcp_LMS_MAC_address"] = tostring(value)
            self:storeSettings()
            menuItem.text = tostring(self:string("WOL_MENU_LMS_MAC_ADDRESS")) .. " (" .. tostring(self:getSettings()["pcp_LMS_MAC_address"]):gsub(("(%x%x)"):rep(6), "%1:%2:%3:%4:%5:%6") .. ")"
            window:hide(Window.transitionPushLeft)
            return true
        end,
        "ABCDEF1234567890"
        )
    local keyboard = Keyboard("keyboard", "hex", input)
    local backspace = Keyboard.backspace()
    local group = Group("keyboard_textinput", { textinput = input, backspace = backspace } )

    window:addWidget(group)
    window:addWidget(keyboard)
    window:focusWidget(group)
    
    self:tieAndShowWindow(window)
    return window
end

function adjustDisplayBrightnessWhenOff(self, menuItem)
    if getpCPVersion() ~= nil then
        local currentBrightness = tonumber(rpi.get_pCP_display_current_brightness())
        if currentBrightness == nil then
            currentBrightness = tonumber("50")
        end

        if currentBrightness ~= nil then
            local maxBrightness = tonumber(rpi.get_pCP_display_max_brightness())
            local brightnessWhenOff = currentBrightness
            if self:getSettings()["pcp_rpi_display_brightness_when_off"] then
                brightnessWhenOff = self:getSettings()["pcp_rpi_display_brightness_when_off"]
            end

            local popup = Popup("black_popup")

            popup:setAllowScreensaver(false)
            popup:setAlwaysOnTop(true)
            popup:setAutoHide(false)
            popup:setTransparent(false)

            popup:ignoreAllInputExcept({"back", "go_home", "scanner_rew", "volume_up", "volume_down", "play_preset_1", "play_preset_2", "play_preset_3", "play_preset_4", "play_preset_5", "play_preset_6", "play_preset_7", "play_preset_8", "play_preset_9", "play_preset_0"})
            
            local cancelBrightnessAction = function()
                    -- store brightnessWhenOff to settings\piCorePlayer.lua
                    self:getSettings()["pcp_rpi_display_brightness_when_off"] = brightnessWhenOff
                    self:storeSettings()
                    popup:hide()
                    return EVENT_CONSUME
            end

            popup:addActionListener("back", self, cancelBrightnessAction)
            popup:addActionListener("go_home", self, cancelBrightnessAction)
            popup:addActionListener("scanner_rew", self, cancelBrightnessAction)
            
            local help
            local labelText
            if rpi.PiDisplay() == "pitouch" then
                help = Textarea("help_text", self:string("HELP_TEXT_ADJUST_BRIGHTNESS_WHEN_OFF"))
                labelText = tostring(self:string("LABEL_ADJUST_BRIGHTNESS_WHENOFF"))
            elseif rpi.PiDisplay() == "lcd" then
                help = Textarea("help_text", self:string("HELP_TEXT_ADJUST_BRIGHTNESS_WHEN_OFF_GENERIC"))
                labelText = tostring(self:string("LABEL_ADJUST_BRIGHTNESS_WHEN_OFF_GENERIC"))
            end
            local label = Label("text", labelText .. " " .. tostring(brightnessWhenOff))

            local slider = Slider("brightness_slider", 0, maxBrightness, brightnessWhenOff,
                function(slider, value)
                    label:setValue(labelText .. " " .. tostring(value))
                    brightnessWhenOff = value
                end)

            local brightnessUpAction = function()
                    if slider:getValue() < maxBrightness then
                        slider:setValue(slider:getValue() + 1)
                        label:setValue(labelText .. " " .. tostring(slider:getValue()))
                        brightnessWhenOff = slider:getValue()
                        return EVENT_CONSUME
                    end
                    return EVENT_UNUSED
            end

            local brightnessDownAction = function()
                    if slider:getValue() > 0 then
                        slider:setValue(slider:getValue() - 1)
                        label:setValue(labelText .. " " .. tostring(slider:getValue()))
                        brightnessWhenOff = slider:getValue()
                        return EVENT_CONSUME
                    end
                    return EVENT_UNUSED
            end

            popup:addActionListener("volume_up", self, brightnessUpAction)
            popup:addActionListener("volume_down", self, brightnessDownAction)

            local brightnessPercentAction = function(self, event)
                local eventName = event:getAction()
                if eventName == "play_preset_0" then
                    slider:setValue(maxBrightness)
                    label:setValue(labelText .. " " .. tostring(slider:getValue()))
                    brightnessWhenOff = slider:getValue()
                    return EVENT_CONSUME
                else
                    local presetNumber = tonumber(string.sub(eventName, -1))
                    slider:setValue(math.floor((maxBrightness / 100) * (10 * presetNumber)))
                    label:setValue(labelText .. " " .. tostring(slider:getValue()))
                    brightnessWhenOff = slider:getValue()
                    return EVENT_CONSUME
                end
                return EVENT_UNUSED
            end

            popup:addActionListener("play_preset_1", self, brightnessPercentAction)
            popup:addActionListener("play_preset_2", self, brightnessPercentAction)
            popup:addActionListener("play_preset_3", self, brightnessPercentAction)
            popup:addActionListener("play_preset_4", self, brightnessPercentAction)
            popup:addActionListener("play_preset_5", self, brightnessPercentAction)
            popup:addActionListener("play_preset_6", self, brightnessPercentAction)
            popup:addActionListener("play_preset_7", self, brightnessPercentAction)
            popup:addActionListener("play_preset_8", self, brightnessPercentAction)
            popup:addActionListener("play_preset_9", self, brightnessPercentAction)
            popup:addActionListener("play_preset_0", self, brightnessPercentAction)

            popup:addListener(EVENT_MOUSE_PRESS,
                function(event)
                    -- store brightnessWhenOff to settings\piCorePlayer.lua
                    self:getSettings()["pcp_rpi_display_brightness_when_off"] = brightnessWhenOff
                    self:storeSettings()
                    popup:hide()
                    return EVENT_CONSUME
                end)

            popup:addWidget(label)
            popup:addWidget(help)
            popup:addWidget(Group("slider_group", {
                         min = Icon("brightness_group.down"),
                         slider = slider,
                         max = Icon("brightness_group.up")
                     }))

            self:tieAndShowWindow(popup)
            return popup
        else
            self:showPopupMessage(tostring(self:string("LABEL_NO_DISPLAY_FOUND_ADJUST_BRIGHTNESS")), 2500)
        end
    else
        self:showPopupMessage(tostring(self:string("LABEL_ERROR_NO_PICOREPLAYER_VERSION_FOUND")), 2500)
    end
end

function adjustDisplayBrightness(self, menuItem)
    if getpCPVersion() ~= nil then
        local currentBrightness = tonumber(rpi.get_pCP_display_current_brightness())
        if currentBrightness ~= nil then
            local maxBrightness = tonumber(rpi.get_pCP_display_max_brightness())
 
            local popup = Popup("black_popup")

            popup:setAllowScreensaver(false)
            popup:setAlwaysOnTop(true)
            popup:setAutoHide(false)
            popup:setTransparent(false)

            popup:ignoreAllInputExcept({"back", "go_home", "scanner_rew", "volume_up", "volume_down", "play_preset_1", "play_preset_2", "play_preset_3", "play_preset_4", "play_preset_5", "play_preset_6", "play_preset_7", "play_preset_8", "play_preset_9", "play_preset_0"})
            
            local cancelBrightnessAction = function()
                -- read current brightness value from and save settings to settings\piCorePlayer.lua
                self:getSettings()["pcp_rpi_display_brightness"] = currentBrightness
                self:storeSettings()
                popup:hide()
                return EVENT_CONSUME
            end

            popup:addActionListener("back", self, cancelBrightnessAction)
            popup:addActionListener("go_home", self, cancelBrightnessAction)
            popup:addActionListener("scanner_rew", self, cancelBrightnessAction)
            
            --use of a generic lcdscript script file if official 7" display is not present
            local help
            local labelText
            if rpi.PiDisplay() == "pitouch" then
                help = Textarea("help_text", self:string("HELP_TEXT_ADJUST_BRIGHTNESS"))
                labelText = tostring(self:string("LABEL_ADJUST_BRIGHTNESS"))
            elseif rpi.PiDisplay() == "lcd" then
                help = Textarea("help_text", self:string("HELP_TEXT_ADJUST_BRIGHTNESS_GENERIC"))
                labelText = tostring(self:string("LABEL_ADJUST_BRIGHTNESS_GENERIC"))
            end
            local label = Label("text", labelText .. " " .. tostring(currentBrightness))

            local slider = Slider("brightness_slider", 0, maxBrightness, currentBrightness,
                function(slider, value)
                label:setValue(labelText .. " " .. tostring(value))
                rpi.set_pCP_display_current_brightness(tostring(value))
            end)

            local brightnessUpAction = function()
                if slider:getValue() < maxBrightness then
                    slider:setValue(slider:getValue() + 1)
                    label:setValue(labelText .. " " .. tostring(slider:getValue()))
                    rpi.set_pCP_display_current_brightness(tostring(slider:getValue()))
                    return EVENT_CONSUME
                end
                return EVENT_UNUSED
            end

            local brightnessDownAction = function()
                    if slider:getValue() > 0 then
                        slider:setValue(slider:getValue() - 1)
                        label:setValue(labelText .. " " .. tostring(slider:getValue()))
                        rpi.set_pCP_display_current_brightness(tostring(slider:getValue()))
                        return EVENT_CONSUME
                    end
                    return EVENT_UNUSED
            end

            popup:addActionListener("volume_up", self, brightnessUpAction)
            popup:addActionListener("volume_down", self, brightnessDownAction)

            local brightnessPercentAction = function(self, event)
                local eventName = event:getAction()
                if eventName == "play_preset_0" then
                    slider:setValue(maxBrightness)
                    label:setValue(labelText .. " " .. tostring(slider:getValue()))
                    rpi.set_pCP_display_current_brightness(tostring(slider:getValue()))
                    return EVENT_CONSUME
                else
                    local presetNumber = tonumber(string.sub(eventName, -1))
                    slider:setValue(math.floor((maxBrightness / 100) * (10 * presetNumber)))
                    label:setValue(labelText .. " " .. tostring(slider:getValue()))
                    rpi.set_pCP_display_current_brightness(tostring(slider:getValue()))
                    return EVENT_CONSUME
                end
                return EVENT_UNUSED
            end

            popup:addActionListener("play_preset_1", self, brightnessPercentAction)
            popup:addActionListener("play_preset_2", self, brightnessPercentAction)
            popup:addActionListener("play_preset_3", self, brightnessPercentAction)
            popup:addActionListener("play_preset_4", self, brightnessPercentAction)
            popup:addActionListener("play_preset_5", self, brightnessPercentAction)
            popup:addActionListener("play_preset_6", self, brightnessPercentAction)
            popup:addActionListener("play_preset_7", self, brightnessPercentAction)
            popup:addActionListener("play_preset_8", self, brightnessPercentAction)
            popup:addActionListener("play_preset_9", self, brightnessPercentAction)
            popup:addActionListener("play_preset_0", self, brightnessPercentAction)

            popup:addListener(EVENT_MOUSE_PRESS,
                function(event)
                    -- read current brightness value from /sys/class/backlight/rpi_backlight/brightness and save settings to settings\piCorePlayer.lua
                    self:getSettings()["pcp_rpi_display_brightness"] = tonumber(rpi.get_pCP_display_current_brightness())
                    self:storeSettings()
                    popup:hide()
                    return EVENT_CONSUME
                end)

            popup:addWidget(label)
            popup:addWidget(help)
            popup:addWidget(Group("slider_group", {
                min = Icon("brightness_group.down"),
                slider = slider,
                max = Icon("brightness_group.up")
                }))

            self:tieAndShowWindow(popup)
            return popup
        else
            self:showPopupMessage(tostring(self:string("LABEL_NO_DISPLAY_FOUND_ADJUST_BRIGHTNESS")), 2500)
        end
    else
        self:showPopupMessage(tostring(self:string("LABEL_ERROR_NO_PICOREPLAYER_VERSION_FOUND")), 2500)
    end
end

function rebootPi(self, menuItem)
    local pcpVersion = tonumber(getpCPVersion())

    if pcpVersion ~= nil then
        local popup = Popup("black_popup")

        popup:setAllowScreensaver(false)
        popup:setAlwaysOnTop(true)
        popup:setAutoHide(false)
        popup:setTransparent(false)

        local icon = Icon("icon_connecting")
        local text = Label("text", self:string("LABEL_REBOOT_IN_PROGRESS"))
        local label = Label("subtext", self:string("LABEL_COUNTDOWN_5_SECONDS"))

        popup:addWidget(label)
        popup:addWidget(icon)
        popup:addWidget(text)

        local state = 4
        popup:addTimer(1000, function()
            if state == 4 then
                label:setValue(self:string("LABEL_COUNTDOWN_4_SECONDS"))
            elseif state == 3 then
                label:setValue(self:string("LABEL_COUNTDOWN_3_SECONDS"))
            elseif state == 2 then
                label:setValue(self:string("LABEL_COUNTDOWN_2_SECONDS"))
            elseif state == 1 then
                label:setValue(self:string("LABEL_COUNTDOWN_1_SECOND"))
            elseif state == 0 then
                icon:setStyle("")
                label:setValue("")
                text:setValue(self:string("LABEL_REBOOTING"))
            elseif state == -1 then
                if pcpVersion >= 3.20 then
                    os.execute(pCP_3_2_reboot_cmd)
                elseif pcpVersion >= 2.00 then
                    os.execute(pCP_2_0_reboot_cmd)
                elseif pcpVersion >= 1.22 then
                    os.execute(pCP_1_22_reboot_cmd)
                else
                    os.execute(pCP_default_reboot_cmd)
                end
            end
            state = state - 1
        end)

        self:tieAndShowWindow(popup)
        return popup
    else
        self:showPopupMessage(tostring(self:string("LABEL_ERROR_NO_PICOREPLAYER_VERSION_FOUND")), 2500)
    end
end

function shutdownPi(self, menuItem)
    local pcpVersion = tonumber(getpCPVersion())

    if pcpVersion ~= nil then
        local popup = Popup("black_popup")

        popup:setAllowScreensaver(false)
        popup:setAlwaysOnTop(true)
        popup:setAutoHide(false)
        popup:setTransparent(false)

        local icon = Icon("icon_connecting")
        local text = Label("text", self:string("LABEL_SHUTDOWN_IN_PROGRESS"))
        local label = Label("subtext", self:string("LABEL_COUNTDOWN_5_SECONDS"))

        popup:addWidget(label)
        popup:addWidget(icon)
        popup:addWidget(text)

        local state = 4
        popup:addTimer(1000, function()
            if state == 4 then
                label:setValue(self:string("LABEL_COUNTDOWN_4_SECONDS"))
            elseif state == 3 then
                label:setValue(self:string("LABEL_COUNTDOWN_3_SECONDS"))
            elseif state == 2 then
                label:setValue(self:string("LABEL_COUNTDOWN_2_SECONDS"))
            elseif state == 1 then
                label:setValue(self:string("LABEL_COUNTDOWN_1_SECOND"))
            elseif state == 0 then
                icon:setStyle("")
                label:setValue("")
                text:setValue(self:string("LABEL_SHUTTING_DOWN"))
            elseif state == -1 then
                -- should we disconnect player from server before shutdown????
                appletManager:callService("disconnectPlayer")
                if pcpVersion >= 3.20 then
                    rpi.set_backlight_power("1")
                    os.execute(pCP_3_2_shutdown_cmd)
                elseif pcpVersion >= 2.00 then
                    -- turn off display!
                    -- code from Ralphy's DisplayOffApplet.lua
                    -- no need to remember the current state
                    -- as the Pi is about to be powered off
                    rpi.set_backlight_power("1")
                    os.execute(pCP_2_0_shutdown_cmd)
                elseif pcpVersion >= 1.22 then
                    rpi.set_backlight_power("1")
                    os.execute(pCP_1_22_shutdown_cmd)
                else
                    os.execute(pCP_default_shutdown_cmd)
                end
            end
            state = state - 1
        end)

        self:tieAndShowWindow(popup)
        return popup
    else
        self:showPopupMessage(tostring(self:string("LABEL_ERROR_NO_PICOREPLAYER_VERSION_FOUND")), 2500)
    end
end

function rescanLMSMediaLibrary(self, menuItem)
    local pcpVersion = tonumber(getpCPVersion())
    
    if pcpVersion ~= nil then
        if pcpVersion >= pCP_rescan_LMS_media_library_min_version then
            if tonumber(_read_capture(pCP_is_player_connected_to_LMS_cmd)) == 1 then
                if tonumber(_read_capture(pCP_rescan_LMS_media_library_in_progress_cmd)) == 0 then
                    local popup = Popup("black_popup")

                    popup:setAllowScreensaver(false)
                    popup:setAlwaysOnTop(true)
                    popup:setAutoHide(false)
                    popup:setTransparent(false)

                    local icon = Icon("icon_connecting")
                    local text = Label("text", self:string("LABEL_RESCAN_LMS_MEDIA_LIBRARY"))
                    local label = Label("subtext", self:string("LABEL_COUNTDOWN_5_SECONDS"))

                    popup:addWidget(label)
                    popup:addWidget(icon)
                    popup:addWidget(text)

                    local state = 4
                    popup:addTimer(1000, function()
                        if state == 4 then
                            label:setValue(self:string("LABEL_COUNTDOWN_4_SECONDS"))
                        elseif state == 3 then
                            label:setValue(self:string("LABEL_COUNTDOWN_3_SECONDS"))
                        elseif state == 2 then
                            label:setValue(self:string("LABEL_COUNTDOWN_2_SECONDS"))
                        elseif state == 1 then
                            label:setValue(self:string("LABEL_COUNTDOWN_1_SECOND"))
                        elseif state == 0 then
                            icon:setStyle("")
                            label:setValue("")
                            text:setValue(self:string("LABEL_RESCAN_LMS_MEDIA_LIBRARY_INITIATED"))
                        elseif state == -1 then
                            os.execute(pCP_rescan_LMS_media_library_cmd)
                        elseif state == -2 then
                            popup:hide()
                        end
                        state = state - 1
                    end)

                    self:tieAndShowWindow(popup)
                    return popup
                else
                    self:showPopupMessage(tostring(self:string("LABEL_RESCAN_LMS_MEDIA_LIBRARY_IN_PROGRESS")), 2500)
                end
            else
                self:showPopupMessage(tostring(self:string("LABEL_RESCAN_LMS_MEDIA_LIBRARY_NOT_CONNECTED")), 2500)
            end
        else
            self:showPopupMessage(tostring(self:string("LABEL_RESCAN_LMS_MEDIA_LIBRARY_NOT_SUPPORTED")), 2500)
        end
    else
        self:showPopupMessage(tostring(self:string("LABEL_ERROR_NO_PICOREPLAYER_VERSION_FOUND")), 2500)
    end
end

function saveToSDCard(self, menuItem)
    local pcpVersion = tonumber(getpCPVersion())

    if pcpVersion ~= nil then
        local popup = Popup("toast_popup_text")

        popup:setAllowScreensaver(false)
        popup:setAutoHide(false)

        -- don't allow any keypress/touch command so user cannot interrupt the save command
        -- popup will hide when saving is done
        popup:ignoreAllInputExcept({""})

        local text = Label("text", tostring(self:string("LABEL_SAVING_SETTINGS")))

        popup:addWidget(text)

        local state = "not saved"
        popup:addTimer(1000, function()
                if state == "not saved" then
                    if pcpVersion >= 3.20 then
                        os.execute(pCP_3_2_save_cmd)
                    elseif pcpVersion >= 2.00 then
                        os.execute(pCP_2_0_save_cmd)
                    elseif pcpVersion >= 1.22 then
                        os.execute(pCP_1_22_save_cmd)
                    else
                        os.execute(pCP_default_save_cmd)
                    end
                    text:setValue(self:string("LABEL_SETTINGS_SAVED"))
                    state = "done"
                elseif state == "done" then
                    state = "hide"
                elseif state == "hide" then
                    popup:hide(Window.transitionFadeOut)
                end
            end)

        self:tieAndShowWindow(popup, Window.transitionFadeIn)
        return popup
    else
        self:showPopupMessage(tostring(self:string("LABEL_ERROR_NO_PICOREPLAYER_VERSION_FOUND")), 2500)
    end
end

function showPopupMessage(self, message, duration)
    local popup = Popup("toast_popup_text")

    popup:setAllowScreensaver(false)
    popup:setTransparent(true)

    --"text" doesn't support \n\n constructions but centers the text vertically
    local text = Label("text", message)
    --"help text" does support \n\n constructions but doesn's center the text vertically
    -- local text = Textarea("help_text", message)

    popup:addWidget(text)

    popup:showBriefly(duration, nil, Window.transitionFadeIn, Window.transitionFadeOut)
    return popup
end

function getpCPVersion()
    local fh, err = io.open(pCP_version_file_location,"r")
    if err then
        return nil
    end
    local pcpv = fh:read("*all")
    fh:close()

    if string.find(pcpv, "%d+%.%d+") ~= nil then
        pcpv = string.sub(pcpv, string.find(pcpv, "%d+%.%d+"))
    else
        return nil
    end
    return pcpv
end

function _write(file, val)
    local fh, err = io.open(file, "w")
    if err then
        return
    end
    fh:write(val)
    fh:close()
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

function getNetworkInterfaces()
    local nics = {}
    local tmpfile = "/tmp/pcp_nics.txt"
    os.execute(pCP_list_network_interfaces_cmd .. " > " .. tmpfile)
    local fh, err = io.open(tmpfile)
    if err then
        return nics
    end
    index = 1
    for line in fh:lines() do
        if line ~= "lo" then -- don't add loopback interface
            nics[index] = line
            index = index + 1
        end
    end
    fh:close()
    return nics
 end
 
function read_textfile_to_table(file)
    local fh, err = io.open(file, "r")
    if err then
        return nil
    end
    local tbl = {}
    for line in fh:lines() do
        table.insert(tbl, line)
    end
    fh:close()
    return tbl
end

function write_table_to_textfile(file, tbl)
    local fh, err = io.open(file, "w")
    if err then
        return
    end
    for i=1, #tbl do
        fh:write(tbl[i] .. "\n") -- is \n necessary in Linux?
    end
    fh:close()
end

function table_find(val, tbl)
    for index, value in ipairs(tbl) do
        if string.find(value, val) then
            return index
        end
    end
    return nil
end
