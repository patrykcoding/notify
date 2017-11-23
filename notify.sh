#!/bin/bash

config_file="$HOME/.notify.conf"

create_config() {
	echo "Config file not found. Creating a new one"
	echo -n "Enter key: "
	read key
	echo -n "Enter salt: "
	read salt
	echo ""
	echo -n "Enter password: "
	read -s passwd
	echo ""

	config="$key
$salt
$passwd"

	res="$(openssl aes-256-cbc -a -salt -out $config_file <<< "$config")"
}

decrypt_config() {
	params=()
	res=$(openssl aes-256-cbc -d -a -in $config_file)
	if [ "$?" -ne 0 ]; then
		exit
	fi

	while read -r line; do
		params+=("$line")
	done <<< "$res"

	key="${params[0]}"
	salt="${params[1]}"
	passwd="${params[2]}"
}

generate_key () {
	# First argument is password
	if [ -z "${salt}" ]; then
		echo -n "${1}${default_salt}" | sha1sum | awk '{print toupper($1)}' | cut -c1-32
	else
		echo -n "${1}${salt}" | sha1sum | awk '{print toupper($1)}' | cut -c1-32
	fi
}

encrypt () {
	# First argument is key
	# Second argument is IV
	# Third argument is data

	echo -n "${3}" | openssl aes-128-cbc -base64 -K "${1}" -iv "${2}" | awk '{print}' ORS='' | tr '+' '-' | tr '/' '_'
}

run_command() {
	command=""
	for arg in "$@"; do
		command+="$arg"
		command+=" "
	done

	$SHELL -c "${command}"
	sh_res="$?"
}

if [ -e $config_file ]; then
	decrypt_config
else
	create_config
fi

run_command "${@}"

iv=`openssl enc -aes-128-cbc -k dummy -P -md sha1 | grep iv | cut -d "=" -f 2`

default_salt=1789F0B8C4A051E5

encryption_key=`generate_key "${passwd}"`

if [ ! -z $HOST ]; then
	title_encrypted=`encrypt "${encryption_key}" "${iv}" "$HOST"`
else
	title_encrypted=`encrypt "${encryption_key}" "${iv}" "$HOSTNAME"`
fi
title="&title=${title_encrypted}"

if [ $sh_res -eq 0 ]; then
	event="&event=success"
else
	event="&event=error"
fi

message=`encrypt "${encryption_key}" "${iv}" "${1}"`

curl --http1.1 --data "key=${key}${title}&msg=${message}${event}&encrypted=true&iv=$iv" "https://api.simplepush.io/send" > /dev/null 2>&1
