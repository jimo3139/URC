#!/bin/sh
#************************************************************************
#              Skreens Entertainment Technologies                       *
#                                                                       *
#        Filename:                                                      *
#                remote.tcl                                             *
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
source [file join $scriptDir socket.tcl]

global LOGENABLE
global LOGENABLE_LEVEL
global LOGENABLE_DEBUG

global ctlOsdDismissed
global osdMode
global osdPrev
global portCount
global portPos
set osdMode "oscDismissed"
set osdPrev 0
global layoutIdx
set layoutIdx 0
global layoutMax
set layoutMax 99
global globalLayouts
set globalLayouts [list]
#######################################################################
# RemoteControl
########################################################################
proc remoteControl { myIP myPort myCommand myOption } {
	# URL extentions
	set getDevices        {1/hdmi-devices}	
	set getBackground     {1/window-manager/background}	
	set getLoadedLayout   {1/window-manager/layout}
	set getLayouts        {1/layouts}	
	set getDefault        {1/layouts/default}
	set sendOSD           {1/osd}
	set setLayout         {1/window-manager/layout}
	set setDefault        {1/layouts/default}
	set setOsdText		  {1/keyboard/text}	 
	set setOsdCtrl        {1/keyboard/control-character}
	set setAudio          {1/audio-config} 
	set getUpdate         {1/device/update}
	set getName           {1/device/name}
	set getInfo           {1/server-info}
	set wsGetSocket		  {1/sockets}


	# HTTP packet body
	set osdHelp           {{"screen":"help"}}
	set osdStatus         {{"screen":"status"}}
	set osdMenu           {{"screen":"menu"}}
	set osdHome           {{"screen":"home"}}
	set osdLayouts        {{"screen":"layouts"}}
	set osdAudio          {{"text":"a"}}
	set osdFull           {{"text":"f"}}
	set osdRight          {{"text":"x"}}
	set osdLeft           {{"text":"z"}}
	set osdSelect         {{"control_character":"return"}}
	set osdLt             {{"control_character":"left"}}
	set osdRt             {{"control_character":"right"}}
	set osdUp             {{"control_character":"up"}}
	set osdDown           {{"control_character":"down"}}
	set osdAudio          {{"hdmi_out_stream:"}}

	# OSD controls
	set ctlOsdHelp        "ctlOsdHelp"
	set ctlOsdMenu        "ctlOsdMemu"
	set ctlOsdHome        "ctlOsdHome"
	set ctlOsdStatus      "ctlOsdStatus"
	set ctlOsdLayouts     "ctlOsdLayouts"
	set ctlOsdDismissed   "ctlOsdDismissed"

	global osdMode
	global layoutIdx
	global layoutMax
	global osdPrev
	global portCount
	global portPos
	global globalLayouts

	LOG "MSG500: remoteControl() function. CMD $myCommand OPT $myOption"
	LOG "MSG501: remoteControl() IP $myIP Port $myPort"

	switch $myCommand {
		info {
			LOG "Execute INFO $osdHelp\n"
			socketPost $myIP $myPort $osdHelp $sendOSD
			#socketTestRun $myip $myPort $osdHelp $sendOSD

			set osdMode $ctlOsdHelp
			return true
		}
		guide {
			LOG "Execute GUIDE $osdLayouts"
			socketPost $myIP $myPort $osdLayouts $sendOSD
			set osdMode $ctlOsdLayouts
			return true
		}
		pause {
			LOG "Execute STATUS $osdStatus"
			socketPost $myIP $myPort $osdStatus $sendOSD
			set osdMode $ctlOsdStatus
			return true
		}
		menu {
			LOG "Execute MENU $osdMenu"
			socketPost $myIP $myPort $osdMenu $sendOSD
			set osdMode $ctlOsdMenu
			return true
		}
		home {
			LOG "Execute HOME $osdHome"
			socketPost $myIP $myPort $osdHome $sendOSD
			set osdMode $ctlOsdHome
			return true
		}
		exit {
			LOG "Execute EXIT"
			socketDelete $myIP $myPort $sendOSD
			set osdMode $ctlOsdDismissed
			return true
		}
		up {
			LOG "Execute UP $osdUp"
			socketPost $myIP $myPort $osdUp $setOsdCtrl
			return true
		}
		down {
			LOG "Execute DOWN $osdDown"
			socketPost $myIP $myPort $osdDown $setOsdCtrl
			return true
		}
		right {
			LOG "Execute Right $osdRight"

			if { $osdMode == $ctlOsdLayouts } {
				socketPost $myIP $myPort $osdRt $setOsdCtrl
			} else {
				socketPost $myIP $myPort $osdRight $setOsdText
			}
			return true
		}
		left {
			LOG "Execute Left $osdLeft"
			if { $osdMode == $ctlOsdLayouts } {
				socketPost $myIP $myPort $osdLt $setOsdCtrl
			} else {
				socketPost $myIP $myPort $osdLeft $setOsdText
			}
			return true
		}
		play {
			LOG "Execute PLAY $osdFull"


			if { $osdMode == $ctlOsdStatus } {
				set results [socketGet $myIP $myPort $getLoadedLayout]
				if {$results eq "NULL_RESPONSE"} {
					LOG "ERR547: socketGet has failed, returned a $results string."
				} else {
					set myId [dict get $results id] 
					LOG "MSG230: Currently loaded layout ID = $myId"
					set osdPrev $myId
					LOG "MSG231: Updating OSD Previous from current = $osdPrev"
	
					socketPost $myIP $myPort $osdFull $setOsdText
				}
				set osdMode $ctlOsdDismissed

			}
			return true
		}
		ch+ {
			LOG "Execute CH+"
			
			# check to see if we are at the end of the array.
			if { $layoutIdx >= $layoutMax } {
				set layoutIdx [expr 1]
			} else {
				incr layoutIdx
			}

			# We have all the parameters, so go execute the PUT.	
			set myIdx 1
			foreach item [dict keys $globalLayouts] {
				set myName [dict get $globalLayouts $item]
				if { $myIdx == $layoutIdx } {
					set sendName $myName
					set sendId $item
				}
				incr myIdx
			}

			LOG "MSG 998: IDX = $layoutIdx, Loading layout ID $sendId Name $sendName"
			set strId $sendId
			set layoutStr "\{\"id\":"
			append layoutStr $strId "\}"
			socketPut $myIP $myPort $layoutStr $setLayout

			return true
		}
		ch- {
			LOG "Execute CH-"

			# check to see if we are at the beginning of the array.
			set one 1
			LOG "DBG555: ID IDX = $layoutIdx MAX = $layoutMax "
			if { $layoutIdx <= [expr {$one}] } {
				set layoutIdx $layoutMax
			} else {
				incr layoutIdx -1 
			}

			# We have all the parameters, so go execute the PUT.	
			set myIdx 1
			foreach item [dict keys $globalLayouts] {
				set myName [dict get $globalLayouts $item]
				if { $myIdx == $layoutIdx } {
					set sendName $myName
					set sendId $item
				}
				incr myIdx
			}

			LOG "MSG 995: IDX = $layoutIdx, Loading layout ID $sendId Name $sendName"
			set strId $sendId
			set layoutStr "\{\"id\":"
			append layoutStr $strId "\}"
			socketPut $myIP $myPort $layoutStr $setLayout

			return true
		}
		full {
			LOG "Execute FULL $osdFull"
			socketPost $myIP $myPort $osdFull $setOsdText
			return true
		}
		ok {
			LOG "Execute SELECT $osdSelect"

			set results [socketGet $myIP $myPort $getLoadedLayout]
			if {$results eq "NULL_RESPONSE"} {
				LOG "ERR050: socketGet has failed, returned a $results string."
			} else {
				set myId [dict get $results id] 
				LOG "MSG235: Currently loaded layout ID = $myId"
				set osdPrev $myId
				LOG "MSG236: Updating OSD Previous from current = $osdPrev"
			}
			if { $osdMode == $ctlOsdStatus } {
				socketDelete $myIP $myPort $sendOSD
			} elseif { $osdMode == $ctlOsdHelp } {
				socketPost $myIP $myPort $osdFull $setOsdText
			} else {
				socketPost $myIP $myPort $osdSelect $setOsdCtrl
			}
			
			set osdMode $ctlOsdDismissed
			return true
		}
		stop {
			LOG "Execute Set current Layout as Default $myIP $myPort"
			set results [socketGet $myIP $myPort $getLoadedLayout]
			if {$results eq "NULL_RESPONSE"} {
				LOG "ERR051: socketGet has failed, returned a $results string."
			} else {
				set myId [dict get $results id] 
				LOG "MSG448: Currently loaded layout ID = $myId"

				LOG "Setting default ID $myId"
				set strId $myId
				set layoutStr "\{\"layout_id\":"
				append layoutStr $strId "\}"
				socketPut $myIP $myPort $layoutStr $setDefault
			}
		}
		audio {
			LOG "Execute audio direct select. $portPos $myIP $myPort"
			#	override the number 1,2,3,4 inputs to AUDIO # strings, plus 0 for AUDIO OFF.
			if {[string compare $myOption "1"] == 0} {
				set audioStr "{\"hdmi_out_stream\":1}"
			} elseif {[string compare $myOption "2"] == 0} {
				set audioStr "{\"hdmi_out_stream\":2}"
			} elseif {[string compare $myOption "3"] == 0} {
				set audioStr "{\"hdmi_out_stream\":3}"
			} elseif {[string compare $myOption "4"] == 0} {
				set audioStr "{\"hdmi_out_stream\":4}"
			} elseif {[string compare $myOption "0"] == 0} {
				set audioStr "{\"hdmi_out_stream\":0}"
			}
			socketPut $myIP $myPort $audioStr $setAudio	
		}
		audio+ {
			LOG "Execute audio next number $portPos $myIP $myPort"

			set audioPos $portPos
			set audioStr "\{\"hdmi_out_stream\":"
			append audioStr $audioPos "\}"
			socketPut $myIP $myPort $audioStr $setAudio	

			if { $portPos == $portCount } {
				set portPos 1
			} else {
				incr portPos
			}

			return true

		}
		audio- {
			if { $portPos == [expr 1] } {
				set portPos $portCount
			} else {
				incr portPos -1
			}

			LOG "Execute audio prev number $portPos $myIP $myPort"

			set audioPos $portPos
			set audioStr "\{\"hdmi_out_stream\":"
			append audioStr $audioPos "\}"
			socketPut $myIP $myPort $audioStr $setAudio	

			return true

		}
		back {
			LOG "Execute load previous Layout $myIP $myPort"
			set myPrev $osdPrev

			set results [socketGet $myIP $myPort $getLoadedLayout]
			if {$results eq "NULL_RESPONSE"} {
				LOG "ERR152: socketGet has failed, returned a $results string."
			} else {
				set myId [dict get $results id] 
				LOG "MSG232: Currently loaded layout ID = $myId"

				set osdPrev $myId
				LOG "Updating PREV ID $osdPrev"
				LOG "Loading layout $myPrev"
				set strId $myPrev
				set layoutStr "\{\"id\":"
				append layoutStr $strId "\}"
				socketPut $myIP $myPort $layoutStr $setLayout
			}	
		}
		star {
			LOG "Execute Get Default Layout $myIP $myPort"
			set results [socketGet $myIP $myPort $getDefault]
			if {$results eq "NULL_RESPONSE"} {
				LOG "ERR053: socketGet has failed, returned a $results string."
			} else {
				foreach secTwo $results {
					set myId $secTwo
					LOG "My ID = $myId"
				}
				LOG "Loading layout $myId"
				set strId $myId
				set layoutStr "\{\"id\":"
				append layoutStr $strId "\}"
				socketPut $myIP $myPort $layoutStr $setLayout	
			}
		}
		init {
			LOG "Execute options INIT"

			if { $osdMode != $ctlOsdDismissed } {
				set results [socketGet $myIP $myPort $getLoadedLayout]
				if {$results eq "NULL_RESPONSE"} {
					LOG "ERR054: socketGet has no response data, returned a $results string."
				} else {
					set myId [dict get $results id] 
					LOG "MSG233: Currently loaded layout ID = $myId"

					set osdPrev $myId
					LOG "MSG200: Updating OSD Previous from init = $osdPrev"
				}
			} else {
				LOG "MSG201: Command INIT with OSD mode not dismissed."
			}

			# 0 = Just boardcast, 1 = Send the command in wsGetSocket.
			set socketMode 0
			set results [wsStart $myIP $wsGetSocket $socketMode]

			# Get server info.							
			set results [socketGet $myIP $myPort $getInfo]
			if {$results eq "NULL_RESPONSE"} {
				LOG "ERR055: socketGet has failed, returned a $results string."
			} else {
				dict for {key1 val1} $results {
					LOG "\tLevel 1 $key1 = $val1"
					if { $key1 == "kai_configuration" } {
						LOG "\tPort key   = $key1"
						LOG "\tPort value = $val1"
						LOG "\tconf values= [dict values $val1]"
						set key4 [dict keys $val1]

						# Get model name.
						if { [lindex $key4 0] == "model" } {
							LOG "MSG441: Device model = [lindex $val1 1]"
						}

						# Get number of HDMI ports.
						if { [lindex $key4 4] == "hdmi_port_count" } {
							set portCount [lindex $val1 9]
							LOG "MSG442: Port Count   = $portCount"
						}
					}
				}	 
			}

			# Get device name.							
			set info [socketGet $myIP $myPort $getName]
			if {$info eq "NULL_RESPONSE"} {
				LOG "ERR056: socketGet has failed, returned a $info string."
			} else {
				LOG "MSG557: Skreens device name" 
				dict for {key1 val1} $info {
					LOG "\t$key1 = $val1"
				}
			
				# Get device information
				set info [socketGet $myIP $myPort $getUpdate]
				LOG "MSG553: Skreens device information" 
				dict for {key1 val1} $info {
					LOG "\t$key1 = $val1"
				}
			}
			return true
		}
		layouts {
			LOG "Execute Get LAYOUTS"

			set results [socketGet $myIP $myPort $getLayouts]
			if {$results eq "NULL_RESPONSE"} {
				LOG "ERR057: socketGet has failed, returned a $results string."
			} else {
			
				foreach secOne $results {
					set myWindows [dict get $secOne windows]
					set myName [dict get $secOne name] 
					set myId [dict get $secOne id]
					regsub {\"} $myId "" myId
					regsub {\"} $myName "" myName
					set layoutArray($myId) $myName
					lappend globalLayouts $myId $myName
				}

#				foreach item [dict keys $globalLayouts] {
#					set 4upId [dict get $globalLayouts $item]
#					if { $4upId == "4 Up" } {
#						LOG "MSG899: Found $4upId Layout with ID $item"
#					} else {
#						LOG "MSG892: Found $4upId Layout with ID $item"
#					}
#				}

				set myIdx 0
				foreach key [array names layoutArray] {
					LOG "Local Array ID = ${key} NAME = $layoutArray($key)"
					incr myIdx
				}
				# How many layouts do we have?
				set layoutMax $myIdx
				LOG "MSG441: Number of layouts: $layoutMax"
			}
			return true
		}
		load {
			LOG "Execute LOAD a layout"

			#	override the number 1,2,3,4 inputs to HDMI # strings, plus 0 for 4 Up.
			if {[string compare $myOption "1"] == 0} {
				set myOption {HDMI 1}
			} elseif {[string compare $myOption "2"] == 0} {
				set myOption {HDMI 2}
			} elseif {[string compare $myOption "3"] == 0} {
				set myOption {HDMI 3}
			} elseif {[string compare $myOption "4"] == 0} {
				set myOption {HDMI 4}
			} elseif {[string compare $myOption "0"] == 0} {
				set myOption {4 Up}
			}

			set results [socketGet $myIP $myPort $getLoadedLayout]
			if {$results eq "NULL_RESPONSE"} {
				LOG "ERR058: socketGet has failed, returned a $results string."
			} else {
				set myId [dict get $results id] 
				LOG "MSG237: Currently loaded layout ID = $myId"
				set osdPrev $myId
				LOG "MSG238: Updating OSD Previous from current = $osdPrev"

				set results [socketGet $myIP $myPort $getLayouts]
				foreach secOne $results {
					set myName [dict get $secOne name] 
					set myId [dict get $secOne id]
					regsub {\"} $myId "" myId
					regsub {\"} $myName "" myName
					set layoutArray($myId) $myName
				}

				foreach item [dict keys $globalLayouts] {
					set 4upId [dict get $globalLayouts $item]
					if { $4upId == "4 Up" } {
						LOG "MSG819: Found $4upId Layout with ID $item"
						#break
					} else {
						LOG "MSG820: Found $4upId Layout with ID $item"
					}
				}
				set foundLayout false
				foreach key [array names layoutArray] {
					LOG "MSG511: Array ID = ${key} NAME = $layoutArray($key)"

					if {[string compare $layoutArray($key) $myOption] == 0} {
						LOG "MSG512: Loading layout $key"
						set strId $key
						set layoutStr "\{\"id\":"
						append layoutStr $strId "\}"
						socketPut $myIP $myPort $layoutStr $setLayout
						set foundLayout true
						break
					}
				}
				if { $foundLayout == false} {
					LOG "ERR881: Layout not found $myOption"
					return false
				} else {
					LOG "MSG513: Finish loading layout."
					return true
				}
			}
		}
		default {
			LOG "ERR502: Invalid command.\n"
			return false
		}
	}	
}
#######################################################################
# Set the OSD port names
########################################################################
proc osdNames { myIP myPort myCmd myOption } {
	LOG "MSG540: osdNames() function. CMD $myCmd String $myOption"
	LOG "MSG541: osdNames() IP $myIP Port $myPort"

	set osdPortName "{\"device_name\":\""
	set nameStr $osdPortName
	append nameStr $myOption "\"}"

	LOG "MSG542: SetPortNames() JSON String $nameStr"
	socketPut $myIP $myPort $nameStr $myCmd
	return true	
}
#######################################################################
# Dismiss any OSD display.
########################################################################
proc osdExit { myIP myPort } {
	global osdMode
    
	set ctlOsdDismissed   "ctlOsdDismissed"
	set sendOSD           {1/osd}
	set response [socketDelete $myIP $myPort $sendOSD]
	set osdMode $ctlOsdDismissed
	LOG "MSG662: Execute timeout EXIT with OSD mode = $osdMode"

}
