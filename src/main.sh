function successHook(){
	echo "Success!"
	exit 0
}

function errorHook(){
	echo "$status - [$error_id] $error_msg"
	case $error_id in
		UNAUTHORIZED)
			exit 100
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
		let local n=n+1
		local d=`echo $i | cut -d"," -f1`
		local c=`echo $i | cut -d"," -f2`
		local f=`echo $i | cut -d"," -f3`
		local t=`echo $i | cut -d"," -f4`
		local m=`template $d $c`
		unset i
		if [ $n -lt $# ]; then
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
	if [ "$DEBUG" -ne "0" ]; then echo $payload | jq; fi
	unset api_key
	unset report_url
	unset concat
	unset messages
	local r=`curl -s --request POST \
		-H 'Content-Type: application/json' \
		-H 'Accept: application/json' \
		-d "$payload" https://api.gateway360.com/api/3.0/sms/send`
	local status=`echo $r | jq -r '.status'`
	local error_id=`echo $r | jq -r '.error_id'`
	local error_msg=`echo $r | jq -r '.error_msg'`
	unset r
	case "$status" in
		ok)
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
