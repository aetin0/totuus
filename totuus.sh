#!/bin/bash

######################
# checks the current
# TCP connections
######################

# colors
DFLTCOL='\e[39m'
RED='\e[91m'
YELLOW='\033[1;33m'
GREEN='\e[92m'
LIGHTYELLOW='\e[93m'
UNDERLINE='\e[4m'
BOLD='\e[1m'
DFLT="\e[25m\e[0m${DFLTCOL}"
ASK="${BOLD}${LIGHTYELLOW}"
INFO="${YELLOW}"
DETAIL="${BOLD}${GREEN}"
WARN="${BOLD}${RED}"
SEP=";"

# variables
STORE_DIR=".totuus"
STORE_FILE="map.dat"
STORE_PATH="/home/$USER/$STORE_DIR/$STORE_FILE"
declare -g FILTER_ADDR=("10." "192" "172" "0.0")

make_spec_dir()
{
	[[ ! -d "/home/$USER/$STORE_DIR" ]]\
		&& mkdir -p "/home/$USER/$STORE_DIR"
}

make_spec_file()
{
	[[ ! -d "/home/$USER/$STORE_DIR/$STORE_FILE" ]]\
		&& touch "/home/$USER/$STORE_DIR/$STORE_FILE"	
}

# retrieve addrs from proc entry
get_addrs()
{
	local addrs
	local array

	addrs=`cat /proc/net/tcp | tr -s ' ' | cut -d ' ' -f 4 | cut -d ':' -f 1`

	#remove column title
	array=("${addrs[@]:11}")
	echo $array
}

is_local_addr()
{
	local addr

	[[ -z $1 ]]\
		&& return 1
	addr=$1

	for i in "${FILTER_ADDR[@]}";do
		[[ "${addr:0:3}" == "$i" ]]\
			&& return 0
	done
	return 1
}

request_store_info()
{
	local addr
	[[ -z $1 ]]\
		&& return

	addr=$1
	is_local_addr $addr
	ret=$?
	if [ $ret -ne 0 ];then
		gg=`grep "$addr" $STORE_PATH`
		if [ -z "$gg" ];then

			info=`whois $addr`
			loc=`curl "ipinfo.io/$addr/loc" 2> /dev/null`

			netname=`echo "$info"|grep -i "netname"| tr -s '\n' " " |tr -s " " |cut -d " " -f 2`
			orgname=`echo "$info"|grep -i "OrgName"| tr -s '\n' " " |tr -s " " |cut -d " " -f 2`
			country=`echo "$info"|grep -i "Country"| tr -s '\n' " " |tr -s " " |cut -d " " -f 2`
			city=`echo "$info"|grep -i "city"| tr -s '\n' " " |tr -s " " |cut -d ":" -f 2`

			#store the addresses in a file
			echo -ne "$YELLOW$addr$DFLT$SEP"		>> $STORE_PATH
			echo -ne "$BOLD$netname$DFLT$SEP"		>> $STORE_PATH
			echo -ne "$BOLD$orgname$DFLT$SEP"		>> $STORE_PATH
			echo -ne "$BOLD$city$DFLT$SEP"		>> $STORE_PATH
			echo -ne "$loc$SEP" 			>> $STORE_PATH
			echo "$country" 			>> $STORE_PATH

			#display info
			echo -ne "$YELLOW$addr$DFLT\t"
			echo -ne "$BOLD$netname$DFLT\t"
			echo -ne "$BOLD$orgname$DFLT\t"
			echo -ne "$BOLD$city$DFLT\t"
			echo -ne "$loc\t"
			echo "$country"
		else
			echo -e "$gg\t$LIGHTYELLOW (from store)$DFLT"
		fi

	fi
}

convert_hex_addr_to_dec()
{
	#echo $i
	a=$((16#${i:0:2}))
#	echo $a
	b=$((16#${i:2:2}))
#	echo $b
	c=$((16#${i:4:2}))
#	echo $c
	d=$((16#${i:6:2}))
#	echo $d
	addr="$d.$c.$b.$a"
	echo $addr
}

###################
# main
###################
clear
make_spec_dir
make_spec_file

# get TCP connections addresses
addresses=`get_addrs`

for i in $addresses;do
	addr=`convert_hex_addr_to_dec "$addr"`
	request_store_info "$addr"
done

