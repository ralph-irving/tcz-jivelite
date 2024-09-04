local io    = require("io")
local os    = require("os")
local log   = require("jive.utils.log").logger("piCorePlayer")

local tonumber = tonumber

module(...)

if init == nil then
    brightness = "/sys/class/backlight/rpi_backlight/brightness"
    max_brightness = "/sys/class/backlight/rpi_backlight/max_brightness"
    bl_power = "/sys/class/backlight/rpi_backlight/bl_power"

    pCP_lcdscript = "/home/tc/lcd-brightness.sh"
end

function set()
    if init == nil then
        log:info("Init: First Run")
    else
        log:info("Init:" .. init)
    end
  
    --Rpi display presents differently on pi0-4 vs pi5 (2 display connectors)
    if _file_exists("/sys/class/backlight/4-0045/brightness") then
        pidisplay = "pitouch"
        brightness = "/sys/class/backlight/4-0045/brightness"
    elseif _file_exists("/sys/class/backlight/6-0045/brightness") then
        pidisplay = "pitouch"
        brightness = "/sys/class/backlight/6-0045/brightness"
    elseif _file_exists("/sys/class/backlight/10-0045/brightness") then
        pidisplay = "pitouch"
        brightness = "/sys/class/backlight/10-0045/brightness"
    elseif _file_exists (brightness) then
        pidisplay = "pitouch"
    end

    if _file_exists("/sys/class/backlight/4-0045/max_brightness") then
        max_brightness = "/sys/class/backlight/4-0045/max_brightness"
    elseif _file_exists("/sys/class/backlight/6-0045/max_brightness") then
        max_brightness = "/sys/class/backlight/6-0045/max_brightness"
    elseif _file_exists("/sys/class/backlight/10-0045/max_brightness") then
        max_brightness = "/sys/class/backlight/10-0045/max_brightness"
    end

    if _file_exists("/sys/class/backlight/4-0045/bl_power") then
        bl_power = "/sys/class/backlight/4-0045/bl_power"
    elseif _file_exists("/sys/class/backlight/6-0045/bl_power") then
        bl_power = "/sys/class/backlight/6-0045/bl_power"
    elseif _file_exists("/sys/class/backlight/10-0045/bl_power") then
        bl_power = "/sys/class/backlight/10-0045/bl_power"
    end

    if pidisplay == nil then
        if _file_exists(pCP_lcdscript) then
            pidisplay = "lcd"
        end
    end

    log:info("Setting touchscreen to: " .. pidisplay)
    init = 1
end

function PiDisplay()
    if init == nil then
        set()
    end
    return pidisplay
end

function set_backlight_power(power)
    local on = "0"
    local off = "1"
    log:debug("Turning Display: " .. power)
    if PiDisplay() == "pitouch" then
        if power == on then
            log:debug("0-bl_power: " .. _read(bl_power)) 
            if tonumber(_read(bl_power)) == tonumber(off) then
                _write(bl_power, power)
            end
        elseif power == off then
            log:debug("1-bl_power: " .. _read(bl_power)) 
            if tonumber(_read(bl_power)) == tonumber(on) then
                _write(bl_power, power)
            end
        end
    end
end

function run_lcd_script_command(command)
    if PiDisplay() == "lcd" then
        local cmd = pCP_lcdscript .. " " .. command
        log:debug(cmd)
        local retval = _read_capture(cmd)
        return retval
    end
    return nil
end

function get_lcd_current_brightness()
    local ret = _read_capture(pCP_lcdscript .. " C")
    return ret
end

function set_lcd_current_brightness(br)
    os.execute(pCP_lcdscript .. " " .. br)
end
        
function set_pCP_display_current_brightness( BlBr )
    log:debug("Setting " .. PiDisplay() .. " brightness: " .. BlBr)
    --RPi 7" Touchscreen
    if PiDisplay() == "pitouch" then
        _write(brightness, BlBr)
    --Generic brightness script
    elseif PiDisplay() == "lcd" then
        local cmd = pCP_lcdscript .. " " .. BlBr
        log:debug(cmd)
        os.execute(cmd)
    end
end

function get_pCP_display_current_brightness()
    if PiDisplay() == "pitouch" then
        return _read(brightness)
    elseif PiDisplay() == "lcd" then
        return _read_capture(pCP_lcdscript .. " C")
    end
end 

function get_pCP_display_max_brightness()
    if PiDisplay() == "pitouch" then
        return _read(max_brightness)
    elseif PiDisplay() == "lcd" then
        return _read_capture(pCP_lcdscript .. " M")
    end
end

function isTouch()
    if touch == nil then
        local cmd = "udevadm info --export-db | grep ID_INPUT_TOUCHSCREEN"
        local ret = _read_capture(cmd)
        log:debug("udev found: " .. ret)
        touch = 1
        hasTouch = ret
    end
    if hasTouch ~= nil then
        return hasTouch
    else
        return nil
    end
end

function _file_exists(name)
   local f=io.open(name,"r")
   if f~=nil then io.close(f) return true else return false end
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
