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
# Use grep freebsd without the -P
# Continue if the certificate has not expired
if [[ $(echo "${CERT_FNGPRNT_EXPIRY}" | grep -oP 'notAfter=\K.*') < $(date +%s) ]]; then
	echo "ERROR: Certificate has expired" 2>&1 | logger &
	echo "Time since expiry: $(($(date +%s) - $(echo "${CERT_FNGPRNT_EXPIRY}" | grep -oP 'notAfter=\K.*') | bc)) seconds" 2>&1 | logger &
	exit 1
else
	echo "OK: Certificate has not expired" 2>&1 | logger &
fi

# Get the certificate fingerprint and expiry of the file and store it in FILE_FNGPRNT_EXPIRY
FILE_FNGPRNT_EXPIRY=$(openssl x509 -noout -fingerprint -enddate -in "$2")

# Compare the fingerprints and expiry
# Exit with error if the fingerprints don't match
# Exit with error if the expiry dates don't match
# Exit with success if the fingerprints and expiry dates match
if [[ "$(echo "${CERT_FNGPRNT_EXPIRY}" | grep -oP 'SHA1 Fingerprint=\K.*')" != "$(echo "${FILE_FNGPRNT_EXPIRY}" | grep -oP 'SHA1 Fingerprint=\K.*')" ]]; then
	echo "ERROR: Fingerprints don't match!" 2>&1 | logger &
	exit 1
elif [[ "$(echo "${CERT_FNGPRNT_EXPIRY}" | grep -oP 'notAfter=\K.*')" != "$(echo "${FILE_FNGPRNT_EXPIRY}" | grep -oP 'notAfter=\K.*')" ]]; then
	echo "ERROR: Expiry dates don't match!" 2>&1 | logger &
	exit 1
else
	echo "OK: Fingerprints and expiry dates match!" 2>&1 | logger &
	exit 0
fi
