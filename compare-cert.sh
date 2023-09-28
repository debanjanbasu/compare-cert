#!/bin/bash
# Usage: ./compare-cert.sh <domain:port> <certificate file>
# Example: ./compare-cert.sh google.com:443 google.com.crt

# Function to log a message to both stdout and syslog
# Uses logger to log the message to syslog
function sys_logger {
	logger -s "${1}"
}

# Check if the OpenSSL command exists
# Exit with error if the command does not exist
# log the messages to syslog as well
# use variables to store the message before outputting to stdout and syslog
if ! [[ -x "$(command -v openssl)" ]]; then
	MESSAGE="ERROR: OpenSSL is not installed!"
	sys_logger "${MESSAGE}"
	exit 1
fi

# Check if the user has provided a domain and a certificate file
# Exit with error if the user has not provided a domain and a certificate file
# Explain the usage of the program
# use variables to store the message before outputting to stdout and syslog
if [[ -z "$1" ]] || [[ -z "$2" ]]; then
	MESSAGE="ERROR: Please provide a domain and a certificate file!"
	sys_logger "${MESSAGE}"
	echo "Usage: ./compare-cert.sh <domain:port> <certificate file>"
	echo "Example: ./compare-cert.sh google.com:443 google.com.crt"
	exit 1
fi

# Use OpenSSL s_client to connect and get the certificate fingerprint and date
# Store the fingerprint and expiry date in a variable
CERT_FNGPRNT_EXPIRY=$(echo | openssl s_client -servername "$1" -connect "$1" 2>/dev/null | openssl x509 -noout -fingerprint -enddate)

# Check if the certificate has expired from CERT_FNGPRNT_EXPIRY
# Calculate the time since expiry in hh:mm:ss format
# Exit with error if certificate has expired, and print the time since expiry
# Continue if the certificate has not expired
# log the messages to syslog as well
# use variables to store the message before outputting to stdout and syslog
if [[ "$(echo "${CERT_FNGPRNT_EXPIRY}" | grep -oP 'notAfter=\K.*')" < "$(date -u +%Y%m%d%H%M%S)" ]]; then
	TIME_SINCE_EXPIRY=$(($(date -u +%s) - $(date -u -d "$(echo "${CERT_FNGPRNT_EXPIRY}" | grep -oP 'notAfter=\K.*')" +%s)))
	MESSAGE="ERROR: Certificate has expired! Time since expiry: $(date -u -d @"${TIME_SINCE_EXPIRY}" +'%H:%M:%S')"
	sys_logger "${MESSAGE}"
	exit 1
else
	MESSAGE="OK: Certificate has not expired!"
	sys_logger "${MESSAGE}"
fi

# Get the certificate fingerprint and expiry of the file and store it in FILE_FNGPRNT_EXPIRY
FILE_FNGPRNT_EXPIRY=$(openssl x509 -noout -fingerprint -enddate -in "$2")

# Compare the fingerprints and expiry
# Exit with error if the fingerprints don't match
# Exit with error if the expiry dates don't match
# Exit with success if the fingerprints and expiry dates match
# log the messages to syslog as well
# use variables to store the message before outputting to stdout and syslog
if [[ "$(echo "${CERT_FNGPRNT_EXPIRY}" | grep -oP 'SHA1 Fingerprint=\K.*')" != "$(echo "${FILE_FNGPRNT_EXPIRY}" | grep -oP 'SHA1 Fingerprint=\K.*')" ]]; then
	MESSAGE="ERROR: Fingerprints don't match!"
	sys_logger "${MESSAGE}"
	exit 1
elif [[ "$(echo "${CERT_FNGPRNT_EXPIRY}" | grep -oP 'notAfter=\K.*')" != "$(echo "${FILE_FNGPRNT_EXPIRY}" | grep -oP 'notAfter=\K.*')" ]]; then
	MESSAGE="ERROR: Expiry dates don't match!"
	sys_logger "${MESSAGE}"
	exit 1
else
	MESSAGE="OK: Fingerprints and expiry dates match!"
	sys_logger "${MESSAGE}"
	exit 0
fi
