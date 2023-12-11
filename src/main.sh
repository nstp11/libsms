function successHook(){
	echo "Success!"
	[ -e $SUCCESS_SCRIPT ] && /usr/bin/bash $SUCCESS_SCRIPT 2>/dev/random
	exit 0
}

function errorHook(){
	echo "$status - [$error_id] $error_msg"
 	[ -e $ERROR_SCRIPT ] && /usr/bin/bash $ERROR_SCRIPT 2>/dev/random
	case "$error_id" in
		"INVALID_CONTENT_TYPE")
			exit 101
			;;

		"JSON_PARSE_ERROR")
			exit 102
			;;

		"MISSING_PARAMS")
			exit 103
			;;

		"BAD_PARAMS")
			exit 104
			;;

		"UNAUTHORIZED")
			exit 105
			;;

		"INVALID_SENDER")
			exit 106
			;;

		"INVALID_DESTINATION")
			exit 107
			;;

		"INVALID_TEXT")
			exit 108
			;;

		"INVALID_DATETIME")
			exit 109
			;;

		"NOT_ENOUGH_BALANCE")
			exit 110
			;;

		"LIMIT_EXCEEDED")
			exit 111
			;;
	esac
	exit 1
}

function template(){
        local message=`\
                cat $TEMPLATE | \
                sed "s/<domain>/$1/g" | \
                sed "s/<days>/$2/"`
        echo $message
	exit 0
}

function messages(){
	local n=0
	local messages="["
	for i in $@; do
		let n=n+1
		local d=`echo $i | cut -d"," -f1`
		local c=`echo $i | cut -d"," -f2`
		local f=`echo $i | cut -d"," -f3`
		local t=`echo $i | cut -d"," -f4`
		local m=`template $d $c`
		unset i
		if [ "$n" -lt "$#" ]; then
			local messages="$messages{\"from\": \"$f\", \"to\": \"$t\", \"message\": \"$m\"},"
		else
			local messages="$messages{\"from\": \"$f\", \"to\": \"$t\", \"message\": \"$m\"}"
		fi
	done
	local messages="$messages]"
	echo $messages
	exit 0
}

function send(){
        local messages=`messages $@`
	local payload="{\"api_key\":\"$api_key\", \"report_url\":\"$report_url\", \"concat\":\"$concat\", \"messages\": $messages}"
	unset api_key
	unset report_url
	unset concat
	unset messages
 	if [ "$DEBUG" -ne "0" ]; then echo $payload | jq; fi
	local r=`curl -s --request POST \
		-H 'Content-Type: application/json' \
		-H 'Accept: application/json' \
		-d "$payload" https://api.gateway360.com/api/3.0/sms/send`
  	unset payload
	local status=`echo $r | jq -r '.status'`
	local error_id=`echo $r | jq -r '.error_id'`
	local error_msg=`echo $r | jq -r '.error_msg'`
	unset r
	case "$status" in
		"ok")
			successHook
			;;
		*)
			errorHook
			;;
	esac
	exit 0
}

function main(){
	local api_key=`cat $API_KEY`
	local report_url="https://localhost"
	local concat="1"

	send $@
	exit 0
}

source ./settings.sh
main $@
