#!/usr/bin/tcl
#************************************************************************
#              Skreens Entertainment Technologies                       *
#                                                                       *
#        Filename:                                                      *
#                main_module.tcl                                        *
#                                                                       *
#        Description:                                                   *
#                Skreens driver for URC                                 *
#                                                                       *
#        Revision History:                                              *
#                11/1/2017        - Creation                            *
#                                                                       *
# Copyright (c) 2012-2017 Skreens Entertainment Technologies Inc        *
# http://skreens.com                                                    *
# All rights reserved.                                                  *
#                                                                       *
#************************************************************************
set scriptDir [ file dirname [ info script ] ]
set moduleDir [ file dirname [ info script ] ]
source ${scriptDir}/systemSDK.tcl
source ${moduleDir}/remote.tcl

global ::varIfParam
global wsBuild
global osdMode
global osdPrev
global myIP
global myPort
global myLayout
global myOsdTimeout
global myPortName1
global myPortName2
global myPortName3
global myPortName4
global myCommand
global myOption 
global varIfAddress
global varIfPort
#global varIfClientType
global varIfMRXMAC
global varIfDevName
global portCount
global portPos

global LOGENABLE
global LOGFILEENABLE
global LOGENABLE_LEVEL
global LOGENABLE_DEBUG


#Start with debug logging enabled
set LOGENABLE 1
set LOGFILEENABLE 0
set LOGENABLE_DEBUG 1
set LOGENABLE_LEVEL 3

set wsBuild "empty"
set portCount 0
set portPos 1

LOG "MSG000: Starting Skreens URC driver module."

set myIP $varIfAddress
set myPort "80" 
set myCommand "init"
set myOption "1"
set myOsdTimeout 15000

LOG "MSG100: Using IP $varIfAddress, Port varIfPort"
LOG "MSG101: MRX-xx MAC Address $varIfMRXMAC"

LOG "MSG102: Raw Parameters = $::varIfParam"
set eIfParam [string map {= " "} $::varIfParam]
LOG "MSG202: Formated Parameters = $eIfParam"

set drvVersion  [dict get $eIfParam DRIVER_VERSION]
set myTimeout   [dict get $eIfParam OSD_TIMEOUT]
set myPortName1 [dict get $eIfParam PORT_NAME_1]
set myPortName2 [dict get $eIfParam PORT_NAME_2]
set myPortName3 [dict get $eIfParam PORT_NAME_3]
set myPortName4 [dict get $eIfParam PORT_NAME_4]
set myDebugMode [dict get $eIfParam DEBUG_MODE]

LOG "MSG103: Driver Version = $drvVersion"
LOG "MSG104: Port 1 = $myPortName1"
LOG "MSG105: Port 2 = $myPortName2"
LOG "MSG106: Port 3 = $myPortName3"
LOG "MSG107: Port 4 = $myPortName4"

set myOsdTimeout [expr {$myTimeout * 1000}]
LOG "MSG108: OSD Timeout = $myOsdTimeout"
# if OSD timeout value is zero, set the timeout for 5 minutes.
if { $myOsdTimeout == 0 } {
	set myOsdTimeout 300000
}

LOG "MSG109: Debug Mode = $myDebugMode"
if { $myDebugMode == "OFF" } {
	LOG "MSG602: Turning debug messages off."
	set LOGENABLE 0
	set LOGFILEENABLE 0
	set LOGENABLE_DEBUG 0
	set LOGENABLE_LEVEL 0
} elseif { $myDebugMode == "LOG" } {
	LOG "MSG602: Turning debug messages LOG only."
	set LOGENABLE 1
	set LOGFILEENABLE 0
	set LOGENABLE_DEBUG 1
	set LOGENABLE_LEVEL 3
} elseif { $myDebugMode == "FILE" } {
	LOG "MSG602: Turning debug messages FILE only."
	set LOGENABLE 1
	set LOGFILEENABLE 1
	set LOGENABLE_DEBUG 0
	set LOGENABLE_LEVEL 0
} elseif { $myDebugMode == "LOG_FILE" } {
	LOG "MSG602: Turning debug messages LOG and FILE."
	set LOGENABLE 1
	set LOGFILEENABLE 1
	set LOGENABLE_DEBUG 1
	set LOGENABLE_LEVEL 3
}

########################################################################
# Setup the port names based on the parameter list.
########################################################################
set myCommand  {1/hdmi-ports/1}
set results [osdNames $myIP $myPort $myCommand $myPortName1]
set myCommand  {1/hdmi-ports/2}
set results [osdNames $myIP $myPort $myCommand $myPortName2]
set myCommand  {1/hdmi-ports/3}
set results [osdNames $myIP $myPort $myCommand $myPortName3]
set myCommand  {1/hdmi-ports/4}
set results [osdNames $myIP $myPort $myCommand $myPortName4]
if { $results == false } {
	LOG "WRN003: osdNames() function failed."
}
########################################################################
# When we 1st start up, go collect the layouts inventory.
########################################################################
set myCommand "init"
set myOption "1"
set results [remoteControl $myIP $myPort $myCommand $myOption]
if { $results == false } {
	LOG "WRN002: remoteControl() function failed. Exiting program."
}
########################################################################
# When we 1st start up, go collect the layouts inventory.
########################################################################
set myCommand "layouts"
set myOption "1"
set results [remoteControl $myIP $myPort $myCommand $myOption]
if { $results == false } {
	LOG "WRN002: remoteControl() function failed. Exiting program."
}
########################################################################
# Catch commands from the UI.
########################################################################
proc sendOverride {socketID command option time} {
	global myIP
	global myPort
	global myLayout
	global myOsdTimeout
	global myOption
	global osdMode
	global osdPrev
	global wsBuild

	# Remove any RETURN characters.
	set command [string map {"\r" ""} $command]

	LOG "MSG200: sendOverride() SocketID = $socketID Command = $command Receive Option = $option Wait Time = $time"
	
	set optCount [expr {[llength [split $command " "]] - 1}]
	LOG "MSG450: Received CMD from MRX-xx -> $command, option count = $optCount"
	
	# If we have 1 command option, split the command up	for remoteControl().	
	if { $optCount == 1 } {
		set myOption [lindex [split $command] 1]
		set command [lindex [split $command] 0]
	}

	set myCmd [lindex [split $command] 0]
	LOG "MSG477: Received CMD from MRX-xx -> $myCmd, OSD mode = $osdMode"
	
	if {( $myCmd == "ok" ) || ( $myCmd == "exit" )} {
		if { $osdMode != "ctlOsdDismissed" } {
			LOG "MSG478: OSD mode is set. Executing $myCmd, OSD mode = $osdMode"
			clearTimer $::connTimer
			set results [remoteControl $myIP $myPort $myCmd $myOption]
			if { $results == false } {
				LOG "WRN001: First remoteControl() function failed."
			}
		} elseif { $myCmd == "ok" } {
			set myCmd "pause"
			set myOption "1"			
			LOG "MSG479: OSD mode is Dismissed. Executing $myCmd, OSD mode = $osdMode"
			set results [remoteControl $myIP $myPort $myCmd $myOption]
			if { $results == false } {
				LOG "WRN001: First remoteControl() function failed."
			}
			set ::connTimer [setTimer $myOsdTimeout]
		} else {
			LOG "ERR480: OK or EXIT failed. Executing $myCmd, OSD mode = $osdMode"			
		}
	} else {
		set results [remoteControl $myIP $myPort $command $myOption]
		if { $results == false } {
			LOG "WRN001: First remoteControl() function failed."
#		} else {
#			clearTimer $::connTimer
		}

		# If any key is pressed while in any OSD mode, restart the timer.							   	
		if { $osdMode != "oscDismissed" } {
			set ::connTimer [setTimer $myOsdTimeout]
#			set newTime $::connTimer
#			LOG "MSG444: Restarting time with $newTime"
		}
 	}
	LOG "MSG003: Current OSD Mode $osdMode"
	LOG "MSG004: Current OSD Previous ID $osdPrev"
	LOG "MSG005: Firmware build version =  $wsBuild"
}

proc onTimer { id } {
	global myIP
	global myPort
	global osdMode

	if {$id == $::connTimer} {
		clearTimer $::connTimer
		
		LOG "MSG113: Timer Expired! Executing EXIT command."
    
        set response [osdExit $myIP $myPort]
	}
}
