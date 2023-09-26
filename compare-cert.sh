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
# Calculate the time since expiry
# Exit with error if certificate has expired
# Use awk instead of "grep"
if [[ "$(echo "${CERT_FNGPRNT_EXPIRY}" | awk '{print $4}')" == "expired" ]]; then
	echo "Certificate has expired!"
	# Display the time lapsed since expiry
	echo "Time since expiry: $(echo "${CERT_FNGPRNT_EXPIRY}" | awk '{print $5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16,$17,$18}')"
	exit 1
else
	echo "Certificate has not expired! Continuing..."
fi

# Compare the fingerprints and expiry
# Exit with error if the fingerprints don't match
# Exit with error if the expiry dates don't match
# Exit with success if the fingerprints and expiry dates match
if [[ "$(echo "${CERT_FNGPRNT_EXPIRY}" | awk '{print $2}')" != "$(openssl x509 -noout -fingerprint -enddate -in "$2" | awk '{print $2}')" ]]; then
	echo "Fingerprints don't match!"
	exit 1
elif [[ "$(echo "${CERT_FNGPRNT_EXPIRY}" | awk '{print $4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16,$17,$18}')" != "$(openssl x509 -noout -fingerprint -enddate -in "$2" | awk '{print $4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16,$17,$18}')" ]]; then
	echo "Expiry dates don't match!"
	exit 1
else
	echo "Fingerprints and expiry dates match!"
	exit 0
fi
