#!/bin/bash
# Usage: ./compare-cert.sh <domain:port> <certificate file>
# Example: ./compare-cert.sh google.com:443 google.com.crt

# Check if the user has provided a domain and a certificate file
if [[ $# -ne 2 ]]; then
	echo "Usage: ./compare-cert.sh <domain:port> <certificate file>"
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
	TIME_SINCE_EXPIRY=$(TZ=UTC date -d @$(($(date -u +%s) - $(date -d "$(echo "${CERT_FNGPRNT_EXPIRY}" | grep -oP 'notAfter=\K.*')" +%s))) +%H:%M:%S)
	MESSAGE="ERROR: Certificate has expired $TIME_SINCE_EXPIRY ago!"
	echo "${MESSAGE}" 2>&1
	echo "${MESSAGE}" | logger
	exit 1
else
	MESSAGE="OK: Certificate has not expired!"
	echo "${MESSAGE}" 2>&1
	echo "${MESSAGE}" | logger
fi

# Get the certificate fingerprint and expiry of the file and store it in FILE_FNGPRNT_EXPIRY
FILE_FNGPRNT_EXPIRY=$(openssl x509 -noout -fingerprint -enddate -in "$2")

# Compare the fingerprints and expiry
# Exit with error if the fingerprints don't match
# Exit with error if the expiry dates don't match
# Exit with success if the fingerprints and expiry dates match
# log the messages to syslog as well
# use variables to store the message before outputting to stdout and syslog
if [[ "${CERT_FNGPRNT_EXPIRY}" != "${FILE_FNGPRNT_EXPIRY}" ]]; then
	MESSAGE="ERROR: Certificate fingerprints do not match!"
	echo "${MESSAGE}" 2>&1
	echo "${MESSAGE}" | logger
	exit 1
elif [[ "$(echo "${CERT_FNGPRNT_EXPIRY}" | grep -oP 'notAfter=\K.*')" != "$(echo "${FILE_FNGPRNT_EXPIRY}" | grep -oP 'notAfter=\K.*')" ]]; then
	MESSAGE="ERROR: Certificate expiry dates do not match!"
	echo "${MESSAGE}" 2>&1
	echo "${MESSAGE}" | logger
	exit 1
else
	MESSAGE="OK: Certificate fingerprints and expiry dates match!"
	echo "${MESSAGE}" 2>&1
	echo "${MESSAGE}" | logger
	exit 0
fi
