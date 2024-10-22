#!/bin/bash

if [ $# -eq 0 ]; then
    echo "Error: No argument provided."
    echo "Usage: $0 <Pyth token pair ID>"
    exit 1
fi

# Fetch the latest price update
# Fetch the latest price update
RESPONSE=$(curl -s "https://hermes.pyth.network/v2/updates/price/latest?&ids[]=$1")

# Use a single jq command to extract all required fields
PARSED_DATA=$(echo "$RESPONSE" | jq -r '{
    binary_data: .binary.data[0]
}')

# Extract individual values
PRICE_UPDATE_DATA=$(echo "$PARSED_DATA" | jq -r '.binary_data')
echo $PRICE_UPDATE_DATA

flow transactions send ./transactions/get_eth_price_from_pythevm.cdc 0x9Ca38bd7184b23b2c8CD175eE00F3021636631EB $PRICE_UPDATE_DATA $1 -f flow.json -n testnet --signer 'testnet-jp' --gas-limit 9999
