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
# Calculate the time since expiry in milli seconds
# Exit with error if certificate has expired, and print the time since expiry
# Continue if the certificate has not expired
# log the messages to syslog as well
if [[ "$(echo "${CERT_FNGPRNT_EXPIRY}" | grep -oP 'notAfter=\K.*')" < "$(date +%b\ %d\ %H:%M:%S\ %Y\ %Z)" ]]; then
	echo "ERROR: Certificate has expired!" 2>&1
	echo "ERROR: Certificate has expired!" | logger
	echo "ERROR: Certificate expired $(($(date -d "$(echo "${CERT_FNGPRNT_EXPIRY}" | grep -oP 'notAfter=\K.*')" +%s) - $(date +%s))) seconds ago!" 2>&1
	echo "ERROR: Certificate expired $(($(date -d "$(echo "${CERT_FNGPRNT_EXPIRY}" | grep -oP 'notAfter=\K.*')" +%s) - $(date +%s))) seconds ago!" | logger
	exit 1
else
	echo "OK: Certificate has not expired!" 2>&1
	echo "OK: Certificate has not expired!" | logger
fi

# Get the certificate fingerprint and expiry of the file and store it in FILE_FNGPRNT_EXPIRY
FILE_FNGPRNT_EXPIRY=$(openssl x509 -noout -fingerprint -enddate -in "$2")

# Compare the fingerprints and expiry
# Exit with error if the fingerprints don't match
# Exit with error if the expiry dates don't match
# Exit with success if the fingerprints and expiry dates match
# log the messages to syslog as well
if [[ "$(echo "${CERT_FNGPRNT_EXPIRY}" | grep -oP 'SHA1 Fingerprint=\K.*')" != "$(echo "${FILE_FNGPRNT_EXPIRY}" | grep -oP 'SHA1 Fingerprint=\K.*')" ]]; then
	echo "ERROR: Certificate fingerprints don't match!" 2>&1
	echo "ERROR: Certificate fingerprints don't match!" | logger
	exit 1
elif [[ "$(echo "${CERT_FNGPRNT_EXPIRY}" | grep -oP 'notAfter=\K.*')" != "$(echo "${FILE_FNGPRNT_EXPIRY}" | grep -oP 'notAfter=\K.*')" ]]; then
	echo "ERROR: Certificate expiry dates don't match!" 2>&1
	echo "ERROR: Certificate expiry dates don't match!" | logger
	exit 1
else
	echo "OK: Certificate fingerprints and expiry dates match!" 2>&1
	echo "OK: Certificate fingerprints and expiry dates match!" | logger
	exit 0
fi
