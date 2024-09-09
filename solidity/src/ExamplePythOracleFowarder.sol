// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "@pythnetwork/pyth-sdk-solidity/IPyth.sol";
import "@pythnetwork/pyth-sdk-solidity/PythStructs.sol";

contract ExamplePythOracleForwarder {
    IPyth pyth;

    constructor(address _pyth) {
        pyth = IPyth(_pyth);
    }

    function fetchPrice(
        bytes[] calldata pythPriceUpdateData,
        bytes32 priceFeedId,
        uint64 publishTime
    ) public payable returns (uint256) {
        // Calc fee for this pythPriceUpdateData
        uint updateFee = pyth.getUpdateFee(pythPriceUpdateData);

        bytes32[] memory priceIds = new bytes32[](1);
        priceIds[0] = priceFeedId;

        uint64[] memory publishTimes = new uint64[](1);
        publishTimes[0] = publishTime;

        pyth.updatePriceFeedsIfNecessary{value: updateFee}(pythPriceUpdateData, priceIds, publishTimes);

        // Fetch the latest price
        PythStructs.Price memory price = pyth.getPriceNoOlderThan(
            priceFeedId,
            60
        );

        uint tokenPriceToTokenExpoDecimals = (uint(uint64(price.price)) * (10 ** 18)) /
            (10 ** uint8(uint32(-1 * price.expo)));

        return tokenPriceToTokenExpoDecimals;
    }

    // Error raised if the payment is not sufficient
    error InsufficientFee();
}