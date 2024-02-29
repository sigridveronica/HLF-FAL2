#!/bin/bash
#
# SPDX-License-Identifier: Apache-2.0

# default to using OEM
ORG=${1:-OEM}

# Exit on first error, print all commands.
set -e
set -o pipefail

# Where am I?
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"

# Define CA certificates for each organization
ORDERER_CA=${DIR}/test-network/organizations/ordererOrganizations/example.com/tlsca/tlsca.example.com-cert.pem
PEER_QA1_1_CA=${DIR}/test-network/organizations/peerOrganizations/oem.example.com/tlsca/tlsca.oem.example.com-cert.pem
PEER_QA2_1_CA=${DIR}/test-network/organizations/peerOrganizations/supplier.example.com/tlsca/tlsca.supplier.example.com-cert.pem
PEER_QA3_1_CA=${DIR}/test-network/organizations/peerOrganizations/airline.example.com/tlsca/tlsca.airline.example.com-cert.pem

# Convert ORG to lowercase using tr for compatibility
org_lower=$(echo "$ORG" | tr '[:upper:]' '[:lower:]')

# Set environment variables based on organization
if [[ $org_lower == "oem" ]]; then
   CORE_PEER_LOCALMSPID=OEMMSP
   CORE_PEER_MSPCONFIGPATH=${DIR}/test-network/organizations/peerOrganizations/oem.example.com/users/Admin@oem.example.com/msp
   CORE_PEER_ADDRESS=localhost:7051 # Assuming QA1.1 is running on this port
   CORE_PEER_TLS_ROOTCERT_FILE=${PEER_QA1_1_CA}

elif [[ $org_lower == "supplier" ]]; then
   CORE_PEER_LOCALMSPID=SupplierMSP
   CORE_PEER_MSPCONFIGPATH=${DIR}/test-network/organizations/peerOrganizations/supplier.example.com/users/Admin@supplier.example.com/msp
   CORE_PEER_ADDRESS=localhost:8051 # Assuming QA2.1 is running on this port
   CORE_PEER_TLS_ROOTCERT_FILE=${PEER_QA2_1_CA}

elif [[ $org_lower == "airline" ]]; then
   CORE_PEER_LOCALMSPID=AirlineMSP
   CORE_PEER_MSPCONFIGPATH=${DIR}/test-network/organizations/peerOrganizations/airline.example.com/users/Admin@airline.example.com/msp
   CORE_PEER_ADDRESS=localhost:9051 # Assuming QA3.1 is running on this port
   CORE_PEER_TLS_ROOTCERT_FILE=${PEER_QA3_1_CA}

else
   echo "Unknown \"$ORG\", please choose OEM, Supplier, or Airline"
   exit 1
fi

# Output the variables that need to be set
echo "CORE_PEER_TLS_ENABLED=true"
echo "ORDERER_CA=${ORDERER_CA}"
echo "PEER_QA1_1_CA=${PEER_QA1_1_CA}"
echo "PEER_QA2_1_CA=${PEER_QA2_1_CA}"
echo "PEER_QA3_1_CA=${PEER_QA3_1_CA}"

echo "CORE_PEER_MSPCONFIGPATH=${CORE_PEER_MSPCONFIGPATH}"
echo "CORE_PEER_ADDRESS=${CORE_PEER_ADDRESS}"
echo "CORE_PEER_TLS_ROOTCERT_FILE=${CORE_PEER_TLS_ROOTCERT_FILE}"

echo "CORE_PEER_LOCALMSPID=${CORE_PEER_LOCALMSPID}"