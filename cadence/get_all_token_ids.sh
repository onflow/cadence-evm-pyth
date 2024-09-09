#!/bin/bash

# Function to fetch and process Pyth price feeds
fetch_pyth_ids() {
    # Fetch price feeds from Hermes API
    response=$(curl -s "https://hermes.pyth.network/v2/price_feeds")

    # Check if curl command was successful
    if [ $? -ne 0 ]; then
        echo "Failed to fetch data from Hermes API"
        exit 1
    fi

    # Process the JSON response using jq
    echo "$response" | jq -r '.[] | "\(.symbol) \(.id)"'
}

# Prompt user for token and pair
read -p "Enter the base token (e.g., BTC): " base_token
read -p "Enter the quote token (e.g., USD): " quote_token

# Convert inputs to uppercase
base_token=$(echo "$base_token" | tr '[:lower:]' '[:upper:]')
quote_token=$(echo "$quote_token" | tr '[:lower:]' '[:upper:]')

# Construct the symbol
symbol="${base_token}/${quote_token}"

# Fetch and process Pyth IDs
pyth_ids=$(fetch_pyth_ids)

# Find the matching ID
matching_id=$(echo "$pyth_ids" | grep -i "^$symbol" | awk '{print $2}')

if [ -n "$matching_id" ]; then
    # Construct the variable name
    var_name="${base_token}_${quote_token}_ID"

    # Set the variable
    declare "$var_name=$matching_id"

    echo "Variable set: $var_name=$matching_id"

    # Demonstrate how to use the variable
    echo "You can now use this variable in your script like this:"
    echo "echo \$$var_name"
else
    echo "No matching Pyth ID found for $symbol"
fi