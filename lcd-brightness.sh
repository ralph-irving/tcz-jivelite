#!/bin/sh

#========================================================================================
# Script to call a command line utility to adjust LCD brightness
# Written for the Pirate Audio display that uses PWM on GPIO 13 to adjust brightness,
# so the pigpio command 'pigs' can be used.
# Adjust this script to use whatever command line utility suits your display.
#----------------------------------------------------------------------------------------
#
# $1 is the only passed parameter
# If $1 is ""  then do nothing
# If $1 is "C" then return Current brightness
# If $1 is "M" then return Maximum brightness
# If $1 is "R" then set the Range maximum to $rmax (100 is useful, so that increments are %)
# If $1 is "F" then set to Full (maximum) brightness
# If $1 is a number then set the brightness to this value
#
#----------------------------------------------------------------------------------------
#
# To use the 'pigs' utility 
# pigs GDC 13     : returns the current brightness value
# pigs PRG 13     : returns the maximum brightness (not really needed when PRS is used
#                   to set the maximum to 100 - we could simply return 100)
# pigs PRS 13 100 : sets the brightness range to 0-100
# pigs PWM 13 100 : sets the maximum brightness
# pigs PWM 13 0   : turns off the LCD backlight
#
#----------------------------------------------------------------------------------------

	g=13		# gpio pin for backlight control
	rmax=100	# range maximum

    case $1 in
    	"" )							# empty string - do nothing
    		exit 1
    		;;
    	"C" | "c" )						# get current value
    		echo $(pigs GDC $g)
    		;;
    	"M" | "m" )						# return maximum possible brightness
    		echo $(pigs PRG $g)
    		;;
    	"R" | "r" )						# set maximum brightness range
    		echo $(pigs PRS $g $rmax)
    		;;
    	"F" | "f" )						# set full brightness 
    		echo $(pigs PWM $g $rmax)
    		;;
	    *[!0-9]*) 						# string containing non-numbers - do nothing
	    	exit 1
	    	;;
    	* )								# everything else.  Assume only numbers at this point
    		bright_val=$1
    		# add some checking that $bright_val is in range 0-rmax (TBD)
    		pigs PWM $g $bright_val
    esac
