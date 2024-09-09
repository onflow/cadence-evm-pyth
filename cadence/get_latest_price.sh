#!/bin/bash

if [ $# -eq 0 ]; then
    echo "Error: No argument provided."
    echo "Usage: $0 <Pyth token pair ID>"
    exit 1
fi

# Fetch the latest price update
RESPONSE=$(curl -s "https://hermes.pyth.network/v2/updates/price/latest?&ids[]=$1")

# Use a single jq command to extract all required fields
PARSED_DATA=$(echo "$RESPONSE" | jq -r '{
    binary_data: .binary.data[0],
    publish_time: .parsed[0].price.publish_time
}')

# Extract individual values
PRICE_UPDATE_DATA=$(echo "$PARSED_DATA" | jq -r '.binary_data')
PUBLISH_TIME=$(echo "$PARSED_DATA" | jq -r '.publish_time')

export PRICE_UPDATE_DATA PUBLISH_TIME

flow-c1 transactions send ./transactions/get_eth_price_from_pythevm.cdc 0x0113fc39D6f9c549da38b150DfF3f6bB0AB678E1 $PRICE_UPDATE_DATA $1 $PUBLISH_TIME -f flow.json -n testnet --signer 'testnet-jp'
