#!/bin/sh
#************************************************************************
#              Skreens Entertainment Technologies                       *
#                                                                       *
#        Filename:                                                      *
#                socket.tcl                                             *
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
global LOGENABLE
global LOGENABLE_LEVEL
global LOGENABLE_DEBUG
global wsBuild

package require http
package require json
package require websocket
::websocket::loglevel debug
# ####################################################
# URL POST
# ####################################################
proc socketPost { ip port data ctrl} {
	append path "http://" $ip "/" $ctrl				

	LOG "MSG220: Entering http POST with Path : $path"
	LOG "MSG221: Message Body : $data"

	set myPost [http::geturl $path -type application/json -query $data] 

	set responseBody [http::data $myPost]
	if { [string length $responseBody] != 0 } {
		LOG "MSG222: http Response : $responseBody length : [string length $responseBody]"
	} else {
		LOG "MSG223: There was no http response data, length = [string length $responseBody]"
	}	

	http::cleanup $myPost
}
# ####################################################
# URL PUT
# ####################################################
proc socketPut { ip port data ctrl} {
	append path "http://" $ip "/" $ctrl				

	LOG "PUT Path : $path"
	LOG "Body : $data"

	set myPut [http::geturl $path -type application/json -method PUT -query $data] 
	LOG "MSG766: putUrl() has been sent." 
	set responseBody [http::data $myPut]
	LOG "Response : "
	# Remove any RETURN characters.
	set command [string map {"\r" ""} $responseBody]
	LOG $responseBody
	http::cleanup $myPut

}
# ####################################################
# URL DELETE
# ####################################################
proc socketDelete { ip port ctrl } {
	append path "http://" $ip "/" $ctrl

	LOG "MSG552: Delete Path : $path"

	set myDel [http::geturl $path -method DELETE -query]

	set responseBody [http::data $myDel]
	http::cleanup $myDel
	LOG "MSG449: Delete Response : $responseBody"

}
# ####################################################
# URL GET
# ####################################################
proc socketGet { ip port ctrl} {
	dict set hdr Pragma no-cache
	append path "http://" $ip ":" $port "/" $ctrl
	
	LOG "MSG444: socketGet with path $path Control $ctrl"

	set token [::http::geturl $path -type application/json -headers $hdr]

#	Remove any RETURN at the end of the string.
#	set responseBody [string map { "\n" "" } [http::data $token] ] 
	LOG "MSG446: Response length = [string length [::http::data $token]] "

	set dictData [json::json2dict [::http::data $token ]]

	set status [http::status $token]
	LOG "MSG445: socketGet Status = $status"


	if {$status eq "ok"} {
		LOG "MSG447: socketGet status = $status, with data $dictData"
		http::cleanup $token
#		Some GET responses return "null" when there isn't any data for the GET. 
		if {$dictData eq "null"} {
			LOG "ERR448: socketGet responded with a $dictData string. Reboot the Kia unit."
			set dictData "NULL_RESPONSE"
		}

		return $dictData

	} else {
	    LOG "ERR447: socketGet with data returned bad status = $status."
		http::cleanup $token
		return $status
	}
}
# ####################################################
# URL GET
# ####################################################
proc socketGet1 { ip port ctrl} {
	dict set hdr Pragma no-cache
	append path "http://" $ip ":" $port "/" $ctrl
	
	LOG "MSG444: socketGet with path $path Control $ctrl"

	set token [::http::geturl $path -type application/json -headers $hdr]

	set status [http::status $token]
	LOG "MSG445: socketGet Status = $status"
	
	set responseBody [http::data $token] 

#	Remove any RETURN at the end of the string.
	set responseBody [string map { "\n" "" } $responseBody] 
	LOG "MSG446: Response length = [string length $responseBody] "

	set dictData [json::json2dict [::http::data $token ]]
#  	set dictData [http::data $token] 

	if {$status eq "ok"} {
		LOG "MSG447: socketGet status = $status, with data $responseBody"
		http::cleanup $token
#		Some GET responses return "null" when there isn't any data for the GET. 
		if {$dictData eq "null"} {
			LOG "ERR448: socketGet responded with a $dictData string. Reboot the Kia unit."
			set dictData "NULL_RESPONSE"
		}

		return $dictData

	} else {
	    LOG "ERR447: socketGet with data responseBody returned bad status = $status."
		http::cleanup $token
		set responseBody $status
		return $status
	}
}

# ####################################################
# URL GET
# ####################################################
proc socketGet2 { ip port ctrl} {

	dict set hdr Pragma no-cache
	append path "http://" $ip ":" $port "/" $ctrl
	
	LOG "MSG444: socketGet with path $path Control $ctrl"

	set token [::http::geturl $path -type application/json -headers $hdr]

	set status [http::status $token]
	LOG "MSG445: socketGet Status = $status"
	
	set responseBody [http::data $token] 

#	Remove any RETURN at the end of the string.
	set responseBody [string map { "\n" "" } $responseBody] 
	LOG "MSG446: Response length = [string length $responseBody] "

	set dictData [json::json2dict [::http::data $token ]]
#	set dictData [http::data $token] 

	if {$status eq "ok"} {
		LOG "MSG447: socketGet status = $status, with data $responseBody"
		http::cleanup $token
#		Some GET responses return "null" when there isn't any data for the GET. 
		if {$dictData eq "null"} {
			LOG "ERR448: socketGet responded with a $dictData string. Reboot the Kia unit."
			set dictData "NULL_RESPONSE"
		}

		return $dictData

	} else {
	    LOG "ERR447: socketGet with data responseBody returned bad status = $status."
		http::cleanup $token
		set responseBody $status
		return $status
	}
}
# ####################################################
# WS GET
# ####################################################
proc wsGet { ip port ctrl} {
	dict set hdr Pragma no-cache
	append path "ws://" $ip "/" $ctrl
	LOG "MSG430: wsGet path = $path"	
	set token [::http::geturl $path -type application/json -headers $hdr]
	LOG "MSG446: wsGet with path $path"
	set responseBody [http::data $token]
	
	if {$responseBody eq ""} {
	    LOG "ERR449: socketGet with data responseBody returned NULL"
	} else {
		LOG "MSG449: socketGet with data $responseBody"
	}
	set dictData [json::json2dict [::http::data $token ]]
	http::cleanup $token
	return $dictData
}
# ####################################################
# WebSocket Start
# ####################################################
proc handler { sock type msg } {

	global wsBuild

	switch -glob -nocase -- $type {
		co* {
			LOG "MSG901: Connected on $sock, Type = $type"
			LOG "MSG999: [::websocket::conninfo $sock type] from [::websocket::conninfo $sock sockname] to [::websocket::conninfo $sock peername] state [::websocket::conninfo $sock state]"

		}
		te* {
			LOG "MSG902: RECEIVED: $msg"
			set dictData [json::json2dict $msg ]
			LOG "MSG907: dictData = $dictData"
			::websocket::close $sock

			dict for {key1 val1} $dictData {
				LOG "MSG100: $key1 = $val1"
				if { $key1 == "build_version" } {
					set wsBuild $val1
				}		
			}

		}
		cl* -
		dis* {
			#exit on disconnection.
			LOG "MSG905: Exiting on disconnection."
		}
    }
}

proc socketSend { sock } {
	
	LOG "MSG900: [::websocket::conninfo $sock type] from [::websocket::conninfo $sock sockname] to [::websocket::conninfo $sock peername] state [::websocket::conninfo $sock state]"
	
	set message "{\"screen\":\"help\"}"
	LOG "MSG771: Message sent to server = $message"
	::websocket::send $sock text $message
	after 1000 {
		LOG "MSG777: Message sent to server = $message"
	}
}

proc wsStart { ip ctrl mode } {
	dict set hdr Pragma no-cache
	append path "ws://" $ip "/" $ctrl
	LOG "MSG778: wsStart path = $path"

	set sock [::websocket::open $path handler -header $hdr]
	LOG "MSG904: sock ID = $sock"
	if { $mode >= 1 } {
		after 400
		set results [socketSend $sock]	
	}	
}
