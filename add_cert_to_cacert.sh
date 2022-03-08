#!/bin/bash

# Change this to correct paths
certificate_base_dir="$(pwd)/certificates"
java_home="${JAVA_HOME:-/opt/java/8}"
keytool="$java_home/bin/keytool"
keystore="$java_home/lib/security/cacerts"
keystore_pass="changeit"

usage() {
	echo "To use this script please see the following options:"
	echo "Syntax: .\add_cert_to_cacert -[c <hostname>|f <file>]"
	echo "options:"
	echo "c		<hostname>	Add certificate of the given hostname to java's keystore"
	echo "f		<file>		Reads the file and gets all the hostname certificate and add it to java\'s keystore. Do not that when using file you must add newline after the last hostname"
	echo "s					Skip downloading of certficate"
	echo "h				Prints usage"
	echo
}

addCertificate() {
	hostname="$1"
	certificate_name="$hostname.pem"
	certificate="$certificate_base_dir/$certificate_name"

	echo "=============== ADDING \"$hostname\" CERTIFICATE TO KEYSTORE ==============="

	# Create certificate directory
	mkdir -p "$certificate_base_dir"

	if [ $skip == false ]; then
		# Get certificate
		openssl s_client -connect $hostname:443 -showcerts </dev/null | openssl x509 -outform pem > "$certificate"	
	fi
	
	# Remove certificate by alias
	echo "Deleting $hostname"
	"$keytool" -delete -alias "$hostname" -keystore "$keystore" -storepass "$keystore_pass"

	echo "Adding $hostname"
	# Add certificate to keystore
	"$keytool" -import -alias "$hostname" -file "$certificate" -keystore "$keystore" -storepass "$keystore_pass" -noprompt

	echo "=============================== DONE \"$hostname\" ==============================="
	echo
	echo
}

no_arg=false
skip=false

# Get Options
while getopts ":hsc:f:" option; do
	case $option in
			h )
				usage
				exit;;
			s )
				skip=true
				;;
			c )
				no_arg=true
				addCertificate $OPTARG
				exit;;
			f )
				no_arg=true
				declare -a hostnames=($(cat certificate_lists.txt | sed 'N;s/\r\n/ /'))
				
				for hostname in "${hostnames[@]}"; do
					addCertificate "$hostname"
				done
				exit;;
			\? )
				usage
				exit;;
	esac
done

# Print usage when no option is passed
if [ "$no_arg" ]; then
	usage
fi